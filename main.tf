
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

data "terraform_remote_state" "operational_environment" {
  backend = "s3"

  config = {
    region = "us-east-1"
    bucket = "kojitechs.vpcstatebuckets1"
    key    = "terraform.tfstate"
  }
}

locals {
  operational_environment = data.terraform_remote_state.operational_environment.outputs.vpc_outputs
  vpc_id                  = local.operational_environment.vpc_id
  pub_subnet              = local.operational_environment.pub_subnet
  private_subnet          = local.operational_environment.private_subnet
  database_subnet         = local.operational_environment.database_subnet
  vpc_cidr                = local.operational_environment.vpc_cidr
  name                  = "kojitechs-${replace(basename(var.component_name), "-", "-")}"
}

# contole(accountability)
# version (keep track in infrastructur changes ) 5, 4
# (, create_tag/version=1.2.0, branch=master[1.0.0, 1.2.0])

module "aurora" {
  source = "git::https://github.com/Bkoji1150/aws-rdscluster-kojitechs-tf.git"

  name           = local.name
  engine         = "aurora-mysql"
  engine_version = "5.7.12"
  instances = {
    1 = {
      instance_class      = "db.r5.large"
      publicly_accessible = false
    }
    1 = {
      identifier     = format("%s-%s", "kojitechs-${var.component_name}", "reader-instance")
      instance_class = "db.r5.xlarge"
      promotion_tier = 15
    }
  }
  vpc_id                 = local.vpc_id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  create_db_subnet_group = true
  create_security_group  = false
  subnets                = local.database_subnet

  iam_database_authentication_enabled = true
  create_random_password              = false

  apply_immediately   = true
  skip_final_snapshot = true

  db_parameter_group_name         = aws_db_parameter_group.example.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.example.id
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  database_name                   = "webappdb"
  master_username                 = "dbadmin"
}

resource "aws_db_parameter_group" "example" {
  name        = "${local.name}-aurora-db-57-parameter-group"
  family      = "aurora-mysql5.7"
  description = "${local.name}-aurora-db-57-parameter-group"

}

resource "aws_rds_cluster_parameter_group" "example" {
  name        = "${local.name}-aurora-57-cluster-parameter-group"
  family      = "aurora-mysql5.7"
  description = "${local.name}-aurora-57-cluster-parameter-group"

}


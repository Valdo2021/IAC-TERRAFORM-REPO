
resource "aws_security_group" "frontend_loadbalancer_sg" {
  name        = "frontend_loadbalancer_sg"
  description = "front end"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = local.web_ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = local.egress_rule
    iterator = foo

    content {
      from_port   = foo.value.from_port
      to_port     = foo.value.to_port
      protocol    = foo.value.protocol
      cidr_blocks = foo.value.cidr_blocks
    }
  }
  tags = {
    "Name" = "frontend_loadbalancer_sg"
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "ecs_cluster_sg" {
  name        = "${var.component_name}_ecs_cluster_sg"
  description = "Allow inbound traffic from loadbalancer"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = local.ecs_cluster_ingress_rules

    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      security_groups = ingress.value.security_groups
    }
  }

  dynamic "egress" {
    for_each = local.egress_rule
    iterator = foo

    content {
      from_port   = foo.value.from_port
      to_port     = foo.value.to_port
      protocol    = foo.value.protocol
      cidr_blocks = foo.value.cidr_blocks
    }
  }
  tags = {
    "Name" = "${var.component_name}_ecs_cluster_sg"
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "db_sg" {
  name        = "${var.component_name}_db_sg"
  description = "Allow app from self"
  vpc_id      = local.vpc_id

  ingress {
    description     = "Allow app from self"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_cluster_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "${var.component_name}_db_sg"
  }
  lifecycle {
    create_before_destroy = true
  }
}
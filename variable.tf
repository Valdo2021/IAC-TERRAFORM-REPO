
variable "component_name" {
  default = "kojitechs"
}

variable "http_port" {
  description = "http from everywhere"
  type        = number
  default     = 80
}


variable "https_port" {
  description = "https from everywhere"
  type        = number
  default     = 8080
}


variable "register_dns" {
  default = "bullychainkp.org"
}
variable "dns_name" {
  type    = string
  default = "bullychainkp.org"
}

variable "subject_alternative_names" {
  type    = list(any)
  default = ["*.bullychainkp.org"]
}


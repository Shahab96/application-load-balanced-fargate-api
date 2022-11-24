variable "container_port" {
  type    = number
  default = 3000
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

locals {
  project_prefix = "fargate-api-${terraform.workspace}"
}
terraform {
  backend "s3" {
    encrypt = true
    key     = "dev"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_region" "this" {}
data "aws_caller_identity" "this" {}
data "aws_partition" "this" {}
data "aws_availability_zones" "this" {
  state = "available"
}

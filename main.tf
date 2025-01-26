resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  name = "vpc-endpoint-demo-${random_string.suffix.result}"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "http" "my_public_ip" {
  url = "http://ifconfig.me/ip"
}

data "aws_ami" "amzn2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

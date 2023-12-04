terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
  required_version = ">= 1.2.0"
  backend "s3" {
    bucket         = "bucket-terraform-insper-grupo-e"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "dynamo_table"
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "172.31.0.0/16"
  azs = var.azs

  # Define CIDR blocks for your private subnets
  private_subnets = ["172.31.0.0/26", "172.31.0.64/26"]

  # Define CIDR blocks for your public subnets
  public_subnets = ["172.31.0.128/26", "172.31.0.192/26"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "Development"
    Project = "My"
  }
}

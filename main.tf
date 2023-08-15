terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source              = "./network"
  availability_zone_1 = var.availability_zone_1
  availability_zone_2 = var.availability_zone_2
  application_port    = var.application_port
}

module "ecs" {
  source                    = "./ecs"
  application_name          = var.application_name
  application_count         = var.application_count
  application_port          = var.application_port
  default_security_group_id = module.network.default_security_group_id
  private_subnet_ids        = concat([module.network.private_subnet_1_id], [module.network.private_subnet_1_id])
}

module "client" {
  source = "./client"
}

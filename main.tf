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
    source = "./network"
    availability_zone_1 = var.availability_zone_1
    availability_zone_2 = var.availability_zone_2
    application_port = var.application_port
}
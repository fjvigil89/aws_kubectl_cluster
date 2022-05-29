terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.72"
    }
  }

  backend "s3" {
    bucket  = "ages-kubectl-tf"
    key     = "terraform.tfstate"
    encrypt = true
    profile = "cadem"
  }
}

provider "aws" {
  region = "eu-west-1"
}



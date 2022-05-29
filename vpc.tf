data "aws_availability_zones" "available" {}

resource "aws_kms_key" "eks" {
  description = "EKS Ages Proyect"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  cluster_name    = "${var.cluster_name}-eks-${random_string.suffix.result}"
  name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  cluster_version = "1.21"
  region          = var.region

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "${var.project_name}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}"  = "shared"
    "kubernetes.io/role/elb-${local.cluster_name}" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}"           = "shared"
    "kubernetes.io/role/internal-elb-${local.cluster_name}" = "1"
  }
}



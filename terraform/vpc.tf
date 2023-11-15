data "aws_availability_zones" "available" {}

# Create VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "${var.environment}-${var.application_name}-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  private_subnet_names = ["${var.environment}-${var.application_name}-private-subnet1", "${var.environment}-${var.application_name}-private-subnet2", "${var.environment}-${var.application_name}-private-subnet3"]
  public_subnet_names  = ["${var.environment}-${var.application_name}-public-subnet1", "${var.environment}-${var.application_name}-public-subnet2", "${var.environment}-${var.application_name}-public-subnet3"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.tags

  # **k8s tags for subnets**
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }


}



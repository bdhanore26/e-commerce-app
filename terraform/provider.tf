# ==========================================
# TERRAFORM SETTINGS
# ==========================================

terraform {
  # Minimum Terraform version required
  required_version = ">= 1.5.0"

  required_providers {

    # AWS Provider
    # ~> 5.0 = accepts 5.x, rejects 6.x
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ==========================================
  # REMOTE BACKEND (OPTIONAL)
  # ==========================================
  # Uncomment when ready to store state remotely.
  # Needed for team collaboration.
  #
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "eks-cluster/terraform.tfstate"
  #   region = "eu-west-1"
  # }
}

# ==========================================
# LOCAL VARIABLES
# ==========================================

locals {

  # AWS Region — eu-west-1 (Ireland)
  region = "eu-west-1"

  # EKS Cluster name
  name = "tws-eks-cluster"

  # VPC CIDR — 65,536 IPs
  vpc_cidr = "10.0.0.0/16"

  # Availability Zones
  azs = [
    "eu-west-1a",
    "eu-west-1b"
  ]

  # Public subnets — Load balancers, bastion, public EC2
  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  # Private subnets — App servers, backends, databases
  private_subnets = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]

  # Intra subnets — EKS control plane ENIs
  intra_subnets = [
    "10.0.5.0/24",
    "10.0.6.0/24"
  ]

  # ==========================================
  # COMMON TAGS
  # ==========================================
  # Applied across all resources.
  # Helps with billing, filtering, automation.

  tags = {
    Project     = local.name
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "your-name"     # ← update this
  }
}

# ==========================================
# AWS PROVIDER
# ==========================================
# Connects Terraform to your AWS account.
#
# Credentials resolved from:
#   1. Environment variables (AWS_ACCESS_KEY_ID)
#   2. ~/.aws/credentials file (aws configure)
#   3. IAM Role (if running on EC2/EKS)

provider "aws" {
  region = local.region

  # Optional: tag every resource by default
  default_tags {
    tags = local.tags
  }
}

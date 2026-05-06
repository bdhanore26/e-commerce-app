# ==========================================
# TERRAFORM SETTINGS
# ==========================================
#
# Defines:
# - Required providers
# - Provider source
# - Provider version constraints

terraform {

  required_providers {

    # ==========================================
    # AWS PROVIDER
    # ==========================================
    #
    # HashiCorp AWS provider allows Terraform
    # to communicate with AWS services.
    #
    # Source:
    # Official Terraform Registry provider.

    aws = {

      # Official provider source
      source = "hashicorp/aws"

      # Version constraint
      #
      # "~> 5.0" means:
      # - Accept 5.x versions
      # - Reject 6.x versions
      #
      # Helps avoid breaking changes.

      version = "~> 5.0"
    }
  }
}

# ==========================================
# LOCAL VARIABLES
# ==========================================
#
# Locals help avoid repeating values.
#
# Reusable variables inside Terraform project.

locals {

  # ==========================================
  # AWS REGION
  # ==========================================
  #
  # Region where infrastructure will be created.
  #
  # eu-west-1 = Ireland

  region = "eu-west-1"

  # ==========================================
  # EKS CLUSTER NAME
  # ==========================================
  #
  # Used for:
  # - EKS cluster naming
  # - Resource tagging
  # - Identification

  name = "tws-eks-cluster"

  # ==========================================
  # VPC CIDR BLOCK
  # ==========================================
  #
  # Main network range for VPC.
  #
  # 10.0.0.0/16 gives:
  # 65,536 private IP addresses

  vpc_cidr = "10.0.0.0/16"

  # ==========================================
  # AVAILABILITY ZONES
  # ==========================================
  #
  # Deploy infrastructure across multiple AZs
  # for high availability.

  azs = [
    "eu-west-1a",
    "eu-west-1b"
  ]

  # ==========================================
  # PUBLIC SUBNETS
  # ==========================================
  #
  # Used for:
  # - Load balancers
  # - Bastion hosts
  # - Public EC2 instances
  #
  # Internet accessible.

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  # ==========================================
  # PRIVATE SUBNETS
  # ==========================================
  #
  # Used for:
  # - Application servers
  # - Backend services
  # - Databases
  #
  # No direct internet access.

  private_subnets = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]

  # ==========================================
  # INTRA SUBNETS
  # ==========================================
  #
  # Used internally inside AWS.
  #
  # Often used for:
  # - EKS control plane
  # - Internal services
  # - Internal networking

  intra_subnets = [
    "10.0.5.0/24",
    "10.0.6.0/24"
  ]

  # ==========================================
  # COMMON TAGS
  # ==========================================
  #
  # Applied to AWS resources.
  #
  # Helps:
  # - Resource identification
  # - Billing
  # - Automation
  # - Monitoring

  tags = {

    # Example tag
    example = local.name
  }
}

# ==========================================
# AWS PROVIDER CONFIGURATION
# ==========================================
#
# Connects Terraform to AWS account.
#
# Uses credentials from:
# - aws configure
# - environment variables
# - IAM role
# - shared credentials file

provider "aws" {

  # AWS region for deployment
  region = local.region
}

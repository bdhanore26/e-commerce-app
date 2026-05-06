# ==========================================
# AWS REGION VARIABLE
# ==========================================
#
# Defines the AWS region where all
# infrastructure resources will be created.
#
# Current region:
# eu-west-1 = Europe (Ireland)
#
# Used by:
# - EC2
# - EKS
# - VPC
# - Load Balancers
# - All AWS services

variable "aws_region" {

  # Description visible in Terraform docs
  description = "AWS region where resources will be provisioned"

  # Default AWS region
  default = "eu-west-1"
}

# ==========================================
# EC2 AMI ID VARIABLE
# ==========================================
#
# Defines Ubuntu/Linux machine image
# used for EC2 instance creation.
#
# NOTE:
# In your current setup you are already
# dynamically fetching Ubuntu AMI using:
#
# data "aws_ami" "os_image"
#
# So this variable is OPTIONAL unless
# you want to use a fixed AMI manually.
#
# Keeping it for flexibility.

variable "ami_id" {

  # Description for AMI variable
  description = "AMI ID for the EC2 instance"

  # Example Ubuntu AMI for eu-west-1
  #
  # AMIs are region-specific.
  # This AMI may change over time.
  #
  # Recommended:
  # Use dynamic AMI lookup instead.

  default = "ami-01f23391a59163da9"
}

# ==========================================
# EC2 INSTANCE TYPE VARIABLE
# ==========================================
#
# Defines EC2 machine size.
#
# Used for:
# - Jenkins server
# - Automation server
# - Bastion host
#
# m7i-flex.large:
# - 2 vCPU
# - 8 GB RAM
# - Modern Intel processor
# - Better than t2/t3 generation

variable "instance_type" {

  # Variable description
  description = "Instance type for the EC2 instance"

  # Default EC2 size
  default = "m7i-flex.large"
}

# ==========================================
# ENVIRONMENT VARIABLE
# ==========================================
#
# Used for identifying infrastructure
# environments.
#
# Common values:
# - dev
# - test
# - staging
# - prod
#
# Helpful for:
# - tagging
# - cost management
# - CI/CD pipelines

variable "my_enviroment" {

  # Environment description
  description = "Environment name for infrastructure resources"

  # Default environment
  default = "dev"
}

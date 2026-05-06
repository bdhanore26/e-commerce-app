# ==========================================
# CREATE VPC
# ==========================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.name
  cidr = local.vpc_cidr

  # Availability zones from locals
  azs = local.azs

  # Subnet CIDR ranges from locals
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
  intra_subnets   = local.intra_subnets

  # Single NAT GW to save cost (learning project)
  # Set to false if using only public subnets for EKS nodes
  enable_nat_gateway = true
  single_nat_gateway = true

  # ==========================================
  # SUBNET TAGS FOR EKS
  # ==========================================
  # Required so AWS Load Balancer Controller
  # knows which subnets to use.

  # Public subnets → internet-facing Load Balancers
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  # Private subnets → internal Load Balancers
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  # Intra subnets → EKS control plane ENIs
  intra_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

# ==========================================
# OUTPUTS
# ==========================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "intra_subnets" {
  description = "Intra subnet IDs (EKS control plane)"
  value       = module.vpc.intra_subnets
}

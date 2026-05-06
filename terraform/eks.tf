# ==========================================
# CREATE EKS CLUSTER
# ==========================================
# Uses the official Terraform AWS EKS module.
# Suitable for learning/demo projects.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"   # Keeping your original version (stable for this config)

  # EKS Cluster Name (from locals)
  cluster_name = local.name

  # Public API access — fine for learning projects
  cluster_endpoint_public_access = true

  # ==========================================
  # EKS ADDONS
  # ==========================================
  cluster_addons = {

    # Kubernetes DNS resolution
    coredns = {
      most_recent = true
    }

    # Kubernetes network proxy
    kube-proxy = {
      most_recent = true
    }

    # AWS VPC networking plugin for pods
    vpc-cni = {
      most_recent = true
    }
  }

  # ==========================================
  # VPC CONFIGURATION
  # ==========================================

  vpc_id = module.vpc.vpc_id

  # Worker nodes in public subnets (OK for learning projects)
  subnet_ids = module.vpc.public_subnets

  # Control plane subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # ==========================================
  # NODE GROUP DEFAULTS
  # ==========================================
  # These apply to all managed node groups
  # unless overridden per group.

  eks_managed_node_group_defaults = {
    instance_types                        = ["m7i-flex.large"]
    attach_cluster_primary_security_group = true
  }

  # ==========================================
  # EKS MANAGED NODE GROUP
  # ==========================================

  eks_managed_node_groups = {
    tws-demo-ng = {

      # Scaling config
      min_size     = 2
      max_size     = 3
      desired_size = 2

      # Instance type (free-tier friendly for learning)
      instance_types = ["m7i-flex.large"]

      # On-Demand for stability in demo
      capacity_type = "ON_DEMAND"

      # Root volume size in GB
      disk_size = 35

      # Required for disk_size to take effect
      use_custom_launch_template = false

      tags = {
        Name        = "tws-demo-ng"
        Environment = "dev"
        ExtraTag    = "e-commerce-app"
      }
    }
  }

  # Common tags inherited from locals
  tags = local.tags
}

# ==========================================
# FETCH RUNNING EKS NODE IPs
# ==========================================
# Fetches the EC2 instances that are
# part of the EKS managed node group.
# NOTE: IPs change on scale events.

data "aws_instances" "eks_nodes" {

  instance_tags = {
    "eks:cluster-name" = module.eks.cluster_name
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  # Wait for EKS cluster and nodes to be ready
  depends_on = [module.eks]
}

# ==========================================
# OUTPUTS
# ==========================================

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster API Endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on EKS"
  value       = module.eks.cluster_version
}

output "node_group_arn" {
  description = "ARN of the EKS managed node group"
  value       = module.eks.eks_managed_node_groups["tws-demo-ng"].node_group_arn
}

output "eks_node_public_ips" {
  description = "Public IPs of running EKS worker nodes"
  value       = data.aws_instances.eks_nodes.public_ips
}

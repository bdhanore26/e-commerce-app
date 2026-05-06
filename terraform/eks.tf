# ==========================================
# CREATE EKS CLUSTER
# ==========================================

module "eks" {

  # Official Terraform AWS EKS module
  source  = "terraform-aws-modules/eks/aws"

  # Module version
  version = "19.15.1"

  # EKS Cluster Name
  cluster_name = local.name

  # Allow public access to Kubernetes API
  cluster_endpoint_public_access = true

  # ==========================================
  # EKS ADDONS
  # ==========================================

  cluster_addons = {

    # Kubernetes DNS
    coredns = {
      most_recent = true
    }

    # Kubernetes networking
    kube-proxy = {
      most_recent = true
    }

    # AWS VPC networking plugin
    vpc-cni = {
      most_recent = true
    }
  }

  # ==========================================
  # VPC CONFIGURATION
  # ==========================================

  vpc_id = module.vpc.vpc_id

  # Worker node subnets
  subnet_ids = module.vpc.public_subnets

  # Control plane subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # ==========================================
  # NODE GROUP DEFAULTS
  # ==========================================

  eks_managed_node_group_defaults = {

    # EC2 type for worker nodes
    instance_types = ["m7i-flex.large"]

    # Attach cluster security group
    attach_cluster_primary_security_group = true
  }

  # ==========================================
  # EKS MANAGED NODE GROUP
  # ==========================================

  eks_managed_node_groups = {

    tws-demo-ng = {

      # Minimum worker nodes
      min_size = 2

      # Maximum worker nodes
      max_size = 3

      # Desired worker nodes
      desired_size = 2

      # EC2 machine type
      instance_types = ["m7i-flex.large"]

      # Stable On-Demand instances
      capacity_type = "ON_DEMAND"

      # Root EBS volume size
      disk_size = 35

      # Needed for disk_size to work
      use_custom_launch_template = false

      # Tags
      tags = {
        Name        = "tws-demo-ng"
        Environment = "dev"
        ExtraTag    = "e-commerce-app"
      }
    }
  }

  # Common tags
  tags = local.tags
}

# ==========================================
# FETCH RUNNING EKS NODE IPS
# ==========================================

data "aws_instances" "eks_nodes" {

  instance_tags = {
    "eks:cluster-name" = module.eks.cluster_name
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [module.eks]
}

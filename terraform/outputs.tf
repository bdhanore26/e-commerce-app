# ==========================================
# OUTPUT AWS REGION
# ==========================================
#
# Displays the AWS region where
# infrastructure is deployed.
#
# Example Output:
# ap-south-1

output "region" {

  # Description visible in Terraform docs/output
  description = "The AWS region where resources are created"

  # Value fetched from local variable
  value = local.region
}

# ==========================================
# OUTPUT VPC ID
# ==========================================
#
# Displays the VPC ID created by
# the VPC Terraform module.
#
# Example:
# vpc-0a123456789abcdef

output "vpc_id" {

  description = "The ID of the created VPC"

  # Fetch VPC ID from module output
  value = module.vpc.vpc_id
}

# ==========================================
# OUTPUT EKS CLUSTER NAME
# ==========================================
#
# Displays Kubernetes cluster name.
#
# Useful for:
# - kubectl configuration
# - AWS CLI commands
# - Monitoring tools

output "eks_cluster_name" {

  description = "EKS cluster name"

  # Fetch cluster name from EKS module
  value = module.eks.cluster_name
}

# ==========================================
# OUTPUT EKS API ENDPOINT
# ==========================================
#
# Displays Kubernetes API server endpoint.
#
# kubectl communicates with this endpoint.
#
# Example:
# https://XXXXXXXX.gr7.ap-south-1.eks.amazonaws.com

output "eks_cluster_endpoint" {

  description = "EKS cluster API endpoint"

  value = module.eks.cluster_endpoint
}

# ==========================================
# OUTPUT EC2 PUBLIC IP
# ==========================================
#
# Displays public IP of Jenkins/Automation EC2.
#
# Useful for:
# - SSH access
# - Jenkins access
# - Browser access
#
# Example:
# 13.233.xxx.xxx

output "public_ip" {

  description = "Public IP of the EC2 instance"

  # Fetch EC2 public IP
  value = aws_instance.testinstance.public_ip
}

# ==========================================
# OUTPUT EKS NODE PUBLIC IPS
# ==========================================
#
# Displays public IPs of all Kubernetes worker nodes.
#
# Useful for:
# - Troubleshooting
# - SSH into worker nodes
# - Monitoring
#
# Example:
# [
#   "13.xxx.xxx.xxx",
#   "15.xxx.xxx.xxx"
# ]

output "eks_node_group_public_ips" {

  description = "Public IPs of the EKS node group instances"

  # Fetch all public IPs from EKS worker nodes
  value = data.aws_instances.eks_nodes.public_ips
}

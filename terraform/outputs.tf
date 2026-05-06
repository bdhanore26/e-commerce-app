# ==========================================
# outputs.tf — SINGLE SOURCE OF TRUTH
# ==========================================
# All outputs are defined here only.
# Removed from vpc.tf, ec2.tf, eks.tf to
# prevent "Duplicate output" Terraform errors.

# ---- Region ----
output "region" {
  description = "AWS region where resources are created"
  value       = local.region
}

# ---- VPC ----
output "vpc_id" {
  description = "The ID of the created VPC"
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

# ---- EC2 / Jenkins ----
output "public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_instance.testinstance.public_ip
}

output "jenkins_url" {
  description = "Jenkins UI URL"
  value       = "http://${aws_instance.testinstance.public_ip}:8080"
}

# ---- EKS ----
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version running on EKS"
  value       = module.eks.cluster_version
}

output "eks_node_group_arn" {
  description = "ARN of the EKS managed node group"
  value       = module.eks.eks_managed_node_groups["tws-demo-ng"].node_group_arn
}

output "eks_node_group_public_ips" {
  description = "Public IPs of the EKS worker nodes"
  value       = data.aws_instances.eks_nodes.public_ips
}

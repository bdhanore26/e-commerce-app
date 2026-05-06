eks_managed_node_group_defaults = {

  # EC2 instance type for worker nodes
  # m7i-flex.large:
  # - New generation Intel processor
  # - Better performance than t2/t3
  # - 2 vCPU
  # - 8 GB RAM
  # - Good for Kubernetes workloads

  instance_types = ["m7i-flex.large"]

  attach_cluster_primary_security_group = true
}

eks_managed_node_groups = {

  tws-demo-ng = {

    min_size     = 2
    max_size     = 3
    desired_size = 2

    # Worker node EC2 type
    instance_types = ["m7i-flex.large"]

    # Use Spot pricing for lower cost
   capacity_type = "ON_DEMAND"

    # Root EBS disk size
    disk_size = 35

    # Required for disk size to apply properly
    use_custom_launch_template = false

    tags = {
      Name        = "tws-demo-ng"
      Environment = "dev"
      ExtraTag    = "e-commerce-app"
    }
  }
}

# ==========================================
# FETCH LATEST UBUNTU 24.04 AMI
# ==========================================
# Data source means:
# Terraform will NOT create anything here.
# It will only fetch information from AWS.
#
# This block searches for the latest Ubuntu 24.04 AMI
# available in the selected AWS region.

data "aws_ami" "os_image" {

  # Official Canonical AWS Account ID
  # Ensures only official Ubuntu images are used
  owners = ["099720109477"]

  # Select the latest matching AMI
  most_recent = true

  # Filter only AMIs that are available
  filter {
    name   = "state"
    values = ["available"]
  }

  # Filter Ubuntu 24.04 AMD64 GP3 SSD images
  filter {
    name = "name"

    # Matches Ubuntu 24.04 server images
    values = ["ubuntu/images/hvm-ssd-gp3/*24.04-amd64*"]
  }
}

# ==========================================
# CREATE AWS KEY PAIR
# ==========================================
# This uploads your local public SSH key to AWS.
#
# Purpose:
# Allows SSH login into EC2 instance.

resource "aws_key_pair" "deployer" {

  # Name of key pair in AWS Console
  key_name = "terra-automate-key"

  # Reads local public key file
  # Example file: terra-key.pub
  public_key = file("terra-key.pub")
}

# ==========================================
# USE DEFAULT AWS VPC
# ==========================================
# Instead of creating a custom VPC,
# this uses AWS default VPC already available.

resource "aws_default_vpc" "default" {

}

# ==========================================
# CREATE SECURITY GROUP (FIREWALL)
# ==========================================
# Security Group controls:
# - Incoming traffic
# - Outgoing traffic
#
# Similar to a firewall.

resource "aws_security_group" "allow_user_to_connect" {

  # Security group name
  name = "allow TLS"

  # Description visible in AWS Console
  description = "Allow user to connect"

  # Attach SG to default VPC
  vpc_id = aws_default_vpc.default.id

  # ==========================================
  # ALLOW SSH PORT 22
  # ==========================================
  # Used for SSH login into EC2 instance.

  ingress {

    description = "port 22 allow"

    from_port = 22
    to_port   = 22

    # TCP protocol
    protocol = "tcp"

    # Allow from anywhere
    # WARNING:
    # Better to restrict to your IP only.
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ==========================================
  # ALLOW ALL OUTGOING TRAFFIC
  # ==========================================
  # Allows EC2 to:
  # - download packages
  # - access internet
  # - install software

  egress {

    description = "allow all outgoing traffic"

    from_port = 0
    to_port   = 0

    # -1 means all protocols
    protocol = "-1"

    # Allow all destinations
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ==========================================
  # ALLOW HTTP PORT 80
  # ==========================================
  # Used for websites / nginx / apache

  ingress {

    description = "port 80 allow"

    from_port = 80
    to_port   = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # ==========================================
  # ALLOW HTTPS PORT 443
  # ==========================================
  # Used for secure SSL/TLS websites.

  ingress {

    description = "port 443 allow"

    from_port = 443
    to_port   = 443

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # ==========================================
  # ALLOW PORT 8080
  # ==========================================
  # Commonly used for:
  # - Jenkins
  # - Spring Boot Apps
  # - Tomcat

  ingress {

    description = "port 8080 allow"

    from_port = 8080
    to_port   = 8080

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # ==========================================
  # TAGS
  # ==========================================
  # Helps identify resources in AWS Console.

  tags = {
    Name = "mysecurity"
  }
}

# ==========================================
# CREATE EC2 INSTANCE
# ==========================================
# This block launches the actual virtual machine.

resource "aws_instance" "testinstance" {

  # Use Ubuntu AMI fetched earlier
  ami = data.aws_ami.os_image.id

  # EC2 machine type
  # Example:
  # t2.micro
  # t3.medium
  instance_type = var.instance_type

  # Attach SSH key pair
  key_name = aws_key_pair.deployer.key_name

  # Attach security group firewall
  security_groups = [
    aws_security_group.allow_user_to_connect.name
  ]

  # ==========================================
  # USER DATA SCRIPT
  # ==========================================
  # Runs automatically when EC2 starts.
  #
  # Used for:
  # - Installing Jenkins
  # - Installing Docker
  # - Installing Kubernetes tools
  # - Configuring server automatically

  user_data = file("${path.module}/install_tools.sh")

  # ==========================================
  # EC2 TAGS
  # ==========================================
  # Name visible in AWS Console.

  tags = {
    Name = "Jenkins-Automate"
  }

  # ==========================================
  # ROOT DISK CONFIGURATION
  # ==========================================
  # Controls EC2 storage.

  root_block_device {

    # Disk size in GB
    volume_size = 20

    # GP3 SSD volume type
    # Better performance and cost efficient
    volume_type = "gp3"
  }
}

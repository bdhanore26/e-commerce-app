# ==========================================
# FETCH LATEST UBUNTU 24.04 AMI
# ==========================================
# Data source — only fetches info, creates nothing.
# Searches for the latest official Ubuntu 24.04 AMI.

data "aws_ami" "os_image" {

  # Official Canonical AWS Account ID
  owners = ["099720109477"]

  # Always pick the latest matching AMI
  most_recent = true

  filter {
    name   = "state"
    values = ["available"]
  }

  # Ubuntu 24.04 AMD64 GP3 SSD images
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/*24.04-amd64*"]
  }
}

# ==========================================
# CREATE AWS KEY PAIR
# ==========================================
# Uploads your local public SSH key to AWS.
# Allows SSH login into the EC2 instance.

resource "aws_key_pair" "deployer" {
  key_name   = "terra-automate-key"
  public_key = file("terra-key.pub")
}

# ==========================================
# USE DEFAULT AWS VPC
# ==========================================
# Reuses the default VPC already present in your account.

resource "aws_default_vpc" "default" {}

# ==========================================
# CREATE SECURITY GROUP (FIREWALL)
# ==========================================

resource "aws_security_group" "allow_user_to_connect" {
  name        = "allow_TLS"
  description = "Allow user to connect"
  vpc_id      = aws_default_vpc.default.id

  # ---- SSH ----
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # NOTE: For production restrict to your IP:
    # cidr_blocks = ["YOUR_IP/32"]
  }

  # ---- HTTP ----
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- HTTPS ----
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- Jenkins Port ----
  ingress {
    description = "Jenkins / Spring Boot / Tomcat"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- Allow All Outbound ----
  egress {
    description = "Allow all outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysecurity"
  }
}

# ==========================================
# CREATE EC2 INSTANCE (JENKINS SERVER)
# ==========================================

resource "aws_instance" "testinstance" {

  # Ubuntu 24.04 AMI fetched above
  ami = data.aws_ami.os_image.id

  # Instance type from variables
  instance_type = var.instance_type

  # SSH key pair
  key_name = aws_key_pair.deployer.key_name

  # Attach security group
  security_groups = [
    aws_security_group.allow_user_to_connect.name
  ]

  # ==========================================
  # USER DATA SCRIPT
  # ==========================================
  # Runs automatically on first boot.
  # Installs Jenkins, Docker, Trivy, kubectl, helm, aws-cli.

  user_data = file("${path.module}/install_tools.sh")

  tags = {
    Name = "Jenkins-Automate"
  }

  # ==========================================
  # ROOT DISK
  # ==========================================

  root_block_device {
    volume_size = 20       # GB
    volume_type = "gp3"   # Cost-efficient SSD
  }
}

# ==========================================
# OUTPUT: EC2 PUBLIC IP
# ==========================================

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_instance.testinstance.public_ip
}

output "jenkins_url" {
  description = "Jenkins UI URL"
  value       = "http://${aws_instance.testinstance.public_ip}:8080"
}

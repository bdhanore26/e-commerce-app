# ==========================================
# FETCH LATEST UBUNTU 24.04 AMI
# ==========================================

data "aws_ami" "os_image" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/*24.04-amd64*"]
  }
}

# ==========================================
# CREATE AWS KEY PAIR
# ==========================================

resource "aws_key_pair" "deployer" {
  key_name   = "terra-automate-key"
  public_key = file("terra-key.pub")
}

# ==========================================
# CREATE SECURITY GROUP (FIREWALL)
# ==========================================
# FIX: Removed aws_default_vpc — now uses the
# custom VPC created by the VPC module so Jenkins
# and EKS are in the same network.

resource "aws_security_group" "allow_user_to_connect" {
  name        = "allow_TLS"
  description = "Allow user to connect"

  # FIX: Use module VPC ID (not the default VPC).
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins / Spring Boot / Tomcat"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
  ami           = data.aws_ami.os_image.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  # FIX: Place Jenkins in the module VPC's public subnet.
  # Use subnet_id + vpc_security_group_ids instead of
  # security_groups (security_groups only works with the default VPC).
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.allow_user_to_connect.id]

  # FIX: Required so the instance gets a public IP
  # when launched in a custom VPC subnet.
  associate_public_ip_address = true

  user_data = file("${path.module}/install_tools.sh")

  # FIX: Ensure VPC and subnets exist before the instance launches.
  depends_on = [module.vpc]

  tags = {
    Name = "Jenkins-Automate"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}

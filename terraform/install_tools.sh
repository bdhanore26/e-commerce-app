#!/bin/bash

# ==========================================
# LOG ALL OUTPUT
# ==========================================
#
# Saves logs for troubleshooting.
#
# Logs:
# /var/log/user-data.log

exec > >(tee /var/log/user-data.log | logger -t user-data ) 2>&1

# Exit immediately if command fails
set -e

echo "========================================="
echo "STARTING DEVOPS TOOL INSTALLATION"
echo "========================================="

# ==========================================
# UPDATE SYSTEM
# ==========================================

apt update -y
apt upgrade -y

# ==========================================
# INSTALL REQUIRED PACKAGES
# ==========================================

apt install -y \
curl \
wget \
unzip \
git \
gnupg \
software-properties-common \
apt-transport-https \
ca-certificates \
lsb-release \
jq

# ==========================================
# INSTALL JAVA 17
# ==========================================
#
# Required for Jenkins.

apt install -y fontconfig openjdk-17-jre

# ==========================================
# VERIFY JAVA
# ==========================================

java -version

# ==========================================
# INSTALL JENKINS
# ==========================================

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" | \
tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt update -y

apt install -y jenkins

# ==========================================
# ENABLE & START JENKINS
# ==========================================

systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

# ==========================================
# INSTALL DOCKER
# ==========================================
#
# Using official Docker repository.

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y

apt install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin

# ==========================================
# ENABLE DOCKER
# ==========================================

systemctl enable docker
systemctl start docker

# ==========================================
# ADD USERS TO DOCKER GROUP
# ==========================================

usermod -aG docker ubuntu
usermod -aG docker jenkins

# ==========================================
# RESTART SERVICES
# ==========================================

systemctl restart docker
systemctl restart jenkins

# ==========================================
# INSTALL TRIVY
# ==========================================

curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | \
gpg --dearmor -o /usr/share/keyrings/trivy.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
https://aquasecurity.github.io/trivy-repo/deb \
$(lsb_release -sc) main" | \
tee /etc/apt/sources.list.d/trivy.list

apt update -y

apt install -y trivy

# ==========================================
# INSTALL AWS CLI V2
# ==========================================

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
-o "awscliv2.zip"

unzip awscliv2.zip

./aws/install

# ==========================================
# INSTALL KUBECTL
# ==========================================

curl -LO "https://dl.k8s.io/release/$(curl -L -s \
https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# ==========================================
# INSTALL HELM
# ==========================================

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ==========================================
# INSTALL TERRAFORM
# ==========================================

curl -fsSL https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com jammy main" | \
tee /etc/apt/sources.list.d/hashicorp.list

apt update -y

apt install -y terraform

# ==========================================
# VERIFY INSTALLATIONS
# ==========================================

echo "========================================="
echo "INSTALLED TOOL VERSIONS"
echo "========================================="

java -version
jenkins --version || true
docker --version
trivy --version
aws --version
kubectl version --client
helm version
terraform -version

# ==========================================
# JENKINS INITIAL PASSWORD
# ==========================================

echo "========================================="
echo "JENKINS INITIAL PASSWORD"
echo "========================================="

cat /var/lib/jenkins/secrets/initialAdminPassword

echo "========================================="
echo "INSTALLATION COMPLETED"
echo "========================================="

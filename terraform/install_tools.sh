#!/bin/bash
set -euo pipefail

# Update system and install core packages
sudo apt update
sudo apt install -y fontconfig openjdk-17-jre

# Jenkins installation
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Trivy repo setup (modern keyring approach)
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
  gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
  sudo tee /etc/apt/sources.list.d/trivy.list

# Single update after all repos are added
sudo apt-get update

# Install Jenkins, Docker, Trivy, and dependencies
sudo apt-get install -y jenkins docker.io trivy \
  wget apt-transport-https gnupg lsb-release snapd

# Start and enable services
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl restart docker

# User group permissions
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins

sudo systemctl restart jenkins

# AWS CLI, Helm, Kubectl via Snap
sudo snap install aws-cli --classic
sudo snap install helm --classic
sudo snap install kubectl --classic

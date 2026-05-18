#!/bin/bash
exec > /var/log/user-data.log 2>&1

echo "===== START $(date) ====="

##################################################
# Wait for apt/cloud-init locks
##################################################

while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 \
   || sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 \
   || sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1
do
    echo "Waiting for apt lock..."
    sleep 5
done

##################################################
# Update OS
##################################################

apt update -y
apt upgrade -y

##################################################
# Install base packages + Java 21
##################################################

apt install -y \
curl \
wget \
git \
gnupg \
ca-certificates \
software-properties-common \
lsb-release \
unzip \
fontconfig \
openjdk-21-jre

java -version

##################################################
# Install Docker (latest)
##################################################

curl -fsSL https://get.docker.com | sh

systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu

##################################################
# Install Jenkins (2026 method)
##################################################

mkdir -p /etc/apt/keyrings

wget -O /etc/apt/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
> /etc/apt/sources.list.d/jenkins.list

apt update -y
apt install -y jenkins

##################################################
# Force Jenkins to use Java 21
##################################################

echo 'JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' \
>> /etc/default/jenkins || true

systemctl daemon-reload
systemctl enable jenkins
systemctl restart jenkins

##################################################
# Install AWS CLI v2
##################################################

curl -o awscliv2.zip \
https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip

unzip -q awscliv2.zip
./aws/install

##################################################
# Install kubectl (latest stable)
##################################################

curl -LO \
"https://dl.k8s.io/release/$(curl -L -s \
https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install -m 0755 kubectl \
/usr/local/bin/kubectl

##################################################
# Install Helm (latest)
##################################################

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
| bash

##################################################
# Install Trivy (latest)
##################################################

curl -sfL \
https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
| sh -s -- -b /usr/local/bin

##################################################
# Permissions
##################################################

usermod -aG docker jenkins

systemctl restart docker
systemctl restart jenkins

##################################################
# Verify everything
##################################################

echo "===== VERIFY ====="

echo "JAVA"
java -version

echo "DOCKER"
docker --version

echo "AWS"
aws --version

echo "KUBECTL"
kubectl version --client

echo "HELM"
helm version

echo "TRIVY"
trivy --version

echo "JENKINS"
systemctl status jenkins --no-pager

echo "===== COMPLETE ====="

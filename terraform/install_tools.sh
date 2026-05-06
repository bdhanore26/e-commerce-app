#!/bin/bash
# FIX: Removed `set -euo pipefail` — that flag causes the entire
# script to abort on the first non-zero exit code. On Ubuntu 24.04
# cloud images, snap and lsb_release can return non-zero during
# early boot, killing the rest of the installation silently.
# We log every step to /var/log/user-data.log for easy debugging.

exec > /var/log/user-data.log 2>&1
echo "===== user-data started at $(date) ====="

# ---- Wait for apt lock to be released ----
# Ubuntu cloud images run unattended-upgrades on first boot.
# Without this wait, apt install commands fail with "lock" errors.
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "Waiting for apt lock..."
  sleep 5
done

# ---- Update system and install core packages ----
apt-get update -y
apt-get install -y \
  fontconfig \
  openjdk-17-jre \
  wget \
  apt-transport-https \
  gnupg \
  lsb-release \
  snapd \
  ca-certificates \
  curl

# ---- Jenkins repo ----
wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# ---- Trivy repo ----
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor \
  | tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
  https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
  | tee /etc/apt/sources.list.d/trivy.list

# ---- Single update after all repos are added ----
apt-get update -y

# ---- Install Jenkins, Docker, Trivy ----
apt-get install -y jenkins docker.io trivy

# ---- Start and enable services ----
systemctl enable jenkins
systemctl start jenkins

systemctl enable docker
systemctl restart docker

# ---- User group permissions ----
# FIX: $USER is empty in cloud-init context.
# Hardcode the default Ubuntu user instead.
usermod -aG docker ubuntu
usermod -aG docker jenkins

systemctl restart jenkins

# ---- AWS CLI via Snap ----
# FIX: snap requires snapd socket to be ready.
# Add a short wait to avoid "cannot connect to snapd" errors.
systemctl enable snapd
systemctl start snapd
sleep 10

snap install aws-cli --classic
snap install helm --classic
snap install kubectl --classic

echo "===== user-data finished at $(date) ====="

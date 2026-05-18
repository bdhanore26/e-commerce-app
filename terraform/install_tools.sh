#!/bin/bash
exec > /var/log/user-data.log 2>&1
echo "===== user-data started at $(date) ====="

# ==========================================
# STOP UNATTENDED UPGRADES FIRST
# ==========================================
systemctl stop unattended-upgrades apt-daily.service \
  apt-daily-upgrade.service 2>/dev/null || true
systemctl disable unattended-upgrades apt-daily.timer \
  apt-daily-upgrade.timer 2>/dev/null || true

# ==========================================
# WAIT FOR ALL APT LOCKS
# ==========================================
wait_apt() {
  for lock in \
    /var/lib/dpkg/lock-frontend \
    /var/lib/dpkg/lock \
    /var/lib/apt/lists/lock \
    /var/cache/apt/archives/lock; do
    while fuser "$lock" >/dev/null 2>&1; do
      echo "Waiting for lock: $lock"
      sleep 5
    done
  done
}

wait_apt
killall apt apt-get dpkg 2>/dev/null || true
sleep 5

# ==========================================
# WAIT FOR NETWORK
# ==========================================
echo "Waiting for network..."
until curl -s --max-time 5 https://google.com > /dev/null 2>&1; do
  echo "Network not ready, retrying..."
  sleep 5
done
echo "Network is up."

# ==========================================
# SYSTEM UPDATE + CORE PACKAGES
# ==========================================
wait_apt
apt-get update -y
apt-get install -y \
  fontconfig \
  openjdk-17-jre \
  wget \
  curl \
  gnupg \
  apt-transport-https \
  lsb-release \
  ca-certificates \
  snapd

# ==========================================
# JENKINS REPO — FIXED (gpg --dearmor)
# ==========================================
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
  https://pkg.jenkins.io/debian-stable binary/" | \
  tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# ==========================================
# TRIVY REPO
# ==========================================
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | \
  gpg --dearmor -o /usr/share/keyrings/trivy.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
  https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
  tee /etc/apt/sources.list.d/trivy.list > /dev/null

# ==========================================
# INSTALL JENKINS + DOCKER + TRIVY
# ==========================================
wait_apt
apt-get update -y
apt-get install -y jenkins docker.io trivy

# ==========================================
# START AND ENABLE SERVICES
# ==========================================
systemctl enable jenkins
systemctl start jenkins

systemctl enable docker
systemctl start docker
systemctl restart docker

# ==========================================
# USER GROUP PERMISSIONS
# ==========================================
usermod -aG docker ubuntu
usermod -aG docker jenkins

systemctl restart jenkins

# ==========================================
# SNAP TOOLS — WITH RETRY
# ==========================================
systemctl enable snapd
systemctl start snapd

# Wait for snapd socket to be ready
until snap list >/dev/null 2>&1; do
  echo "Waiting for snapd..."
  sleep 10
done

snap_install() {
  local pkg=$1; shift
  for i in 1 2 3 4 5; do
    snap install "$pkg" "$@" && return 0
    echo "snap install $pkg failed (attempt $i), retrying..."
    sleep 15
  done
  echo "ERROR: $pkg failed after 5 attempts"
  return 1
}

snap_install aws-cli --classic
snap_install helm --classic
snap_install kubectl --classic

# ==========================================
# VERIFY INSTALLATIONS
# ==========================================
echo "===== Verifying installs ====="
java -version
jenkins --version 2>/dev/null || systemctl is-active jenkins
docker --version
trivy --version
aws --version
helm version
kubectl version --client

echo "===== user-data finished at $(date) ====="

#!/bin/bash
exec > /var/log/user-data.log 2>&1
echo "===== user-data started at $(date) ====="

# ---- Kill unattended-upgrades FIRST ----
systemctl stop unattended-upgrades apt-daily.service \
  apt-daily-upgrade.service 2>/dev/null || true
systemctl disable unattended-upgrades apt-daily.timer \
  apt-daily-upgrade.timer 2>/dev/null || true

# ---- Wait for ALL apt locks ----
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

# Kill any lingering dpkg/apt processes
killall apt apt-get dpkg 2>/dev/null || true
sleep 5

# ---- Wait for network ----
echo "Waiting for network..."
until curl -s --max-time 5 https://google.com > /dev/null 2>&1; do
  sleep 5
done
echo "Network is up."

# ---- System update ----
wait_apt
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

wait_apt
apt-get update -y
apt-get install -y jenkins docker.io trivy

# ---- Services ----
systemctl enable jenkins && systemctl start jenkins
systemctl enable docker && systemctl restart docker

# ---- Permissions ----
usermod -aG docker ubuntu
usermod -aG docker jenkins

systemctl restart jenkins

# ---- Snap tools with retry ----
systemctl enable snapd && systemctl start snapd

snap_install() {
  local pkg=$1; shift
  for i in 1 2 3 4 5; do
    snap install "$pkg" "$@" && return 0
    echo "snap install $pkg failed (attempt $i), retrying..."
    sleep 15
  done
  echo "ERROR: $pkg failed after 5 attempts"; return 1
}

# Wait for snapd socket
until snap list >/dev/null 2>&1; do
  echo "Waiting for snapd..."
  sleep 10
done

snap_install aws-cli --classic
snap_install helm --classic
snap_install kubectl --classic

echo "===== user-data finished at $(date) ====="

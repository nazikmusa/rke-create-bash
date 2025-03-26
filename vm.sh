#!/bin/bash


function install_docker() {
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

VERSION_STRING=5:24.0.9-1~ubuntu.22.04~jammy
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin -y
}

function create_rke_user() {
        sudo useradd rke
        sudo usermod -aG docker rke
        sudo mkdir -p /home/rke/.ssh
        sudo touch /home/rke/.ssh/authorized_keys
        sudo chmod 700 /home/rke/.ssh
        sudo chmod 600 /home/rke/.ssh/authorized_keys
        sudo chown -R rke:rke /home/rke
}

install_docker
create_rke_user

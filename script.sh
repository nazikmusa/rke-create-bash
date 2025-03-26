#!/bin/bash

read -p "Enter master IP: " master_ip
read -p "Enter worker1 IP: " worker1_ip
read -p "Enter worker2 IP: " worker2_ip

pubkey=$(cat ~/.ssh/id_rsa.pub)
vms_ip=("$master_ip" "$worker1_ip" "$worker2_ip")



function install_rke() {
	wget https://github.com/rancher/rke/releases/download/v1.8.0/rke_linux-amd64
	mv rke_linux-amd64 rke
	chmod +x rke
	sudo mv rke /usr/local/bin
}

function install_kubectl() {
	sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
# If the folder `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly
sudo apt-get update
sudo apt-get install -y kubectl
}



function docker() {
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

function prepare_vms() {
	for IP in "${vms_ip[@]}"
	do
		scp vm.sh ubuntu@$IP:
		ssh ubuntu@$IP bash vm.sh
        	ssh ubuntu@$IP "echo '$pubkey' | sudo tee -a /home/rke/.ssh/authorized_keys"
	done
}

function create_cluster_file() {
	cp cluster.yml.template cluster.yml
	sed -i "s/MASTER_IP/$master_ip/" cluster.yml
	sed -i "s/WORKER1_IP/$worker1_ip/" cluster.yml
	sed -i "s/WORKER2_IP/$worker2_ip/" cluster.yml
}

function create_rke() {
	rke up
	sudo mkdir ~/.kube
	sudo mv kube_config_cluster.yml ~/.kube/config
	kubectl get nodes
}

install_rke
install_kubectl
docker
prepare_vms
create_cluster_file
create_rke

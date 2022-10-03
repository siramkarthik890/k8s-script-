#!/bin/bash

apt-get install -y curl openssh-server vim 
sed -e 's/^.*PermitRootLogin prohibit-password/PermitRootLogin yes/g' -i  /etc/ssh/sshd_config
systemctl restart sshd 
systemctl disable --now ufw

tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt install -y containerd.io

mkdir -p /etc/containerd
containerd config default>/etc/containerd/config.toml
sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml

systemctl daemon-reload
systemctl restart containerd
systemctl enable containerd


apt-get update && apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg


echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

KUBE_VERSION=1.24.0
apt-get update

apt-get install -y kubelet=${KUBE_VERSION}-00  kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00 kubernetes-cni=0.8.7-00  

apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet

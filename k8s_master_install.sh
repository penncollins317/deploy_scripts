#!/usr/bin/bash

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

sudo apt -y update
sudo apt -y install apt-transport-https ca-certificates curl

# 1. 下载并保存 Kubernetes 官方 GPG key（阿里云镜像可直接使用官方 key）
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 2. 添加阿里云 Kubernetes apt 镜像源
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.34/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt -y update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo tee /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///var/run/cri-dockerd.sock
image-endpoint: unix:///var/run/cri-dockerd.sock
timeout: 10
debug: false
EOF

sudo systemctl restart cri-docker.service cri-docker.socket

sudo crictl info

sudo kubeadm config images pull \
  --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers \
  --cri-socket=unix:///var/run/cri-dockerd.sock \
  --kubernetes-version=v1.34.1

sudo docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9
sudo docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9 k8s.gcr.io/pause:3.9
sudo docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9 registry.k8s.io/pause:3.9
sudo kubeadm reset

sudo kubeadm init \
  --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers \
  --cri-socket=unix:///var/run/cri-dockerd.sock \
  --kubernetes-version=v1.34.1 \
  --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl apply -f ./kube-flannel.yml

# 移除主节点
# kubectl taint nodes <master-name> node-role.kubernetes.io/control-plane-

#!/usr/bin/bash

sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i '/\[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options\]/,/^\s*\[/ s/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# 修改容器数据目录：/data/containerd，后续可以挂载额外的硬盘，或者nfs
sudo sed -i 's|root = "/var/lib/containerd"|root = "/data/containerd"|' /etc/containerd/config.toml
sudo sed -i '/\[plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"\]/,/^\s*\[/c\[plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]\n  endpoint = ["https://docker.m.daocloud.io","https://docker.imgdb.de","https://docker-0.unsee.tech","https://docker.hlmirror.com","https://cjie.eu.org"]' /etc/containerd/config.toml


sudo systemctl daemon-reexec
sudo systemctl restart containerd
sudo systemctl enable containerd


kubeadm init
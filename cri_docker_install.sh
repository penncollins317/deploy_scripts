#!/usr/bin/bash

# 下载最新版本
VERSION=v0.3.21
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.21/cri-dockerd-0.3.21.amd64.tgz
# 解压并安装
tar xvf cri-dockerd-0.3.21.amd64.tgz
sudo mv cri-dockerd/cri-dockerd /usr/local/bin/

rm -rf cri-dockerd-v0.3.21.amd64.tgz
rm -rf cri-dockerd

sudo tee /etc/systemd/system/cri-docker.service <<EOF
[Unit]
Description=CRI interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
After=network.target docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/cri-dockerd --container-runtime-endpoint fd:// --network-plugin=cni --pod-infra-container-image=k8s.gcr.io/pause:3.9
Restart=always
StartLimitInterval=0
RestartSec=10s
Delegate=yes
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/cri-docker.socket <<EOF
[Unit]
Description=CRI Docker Socket for the API
PartOf=cri-docker.service

[Socket]
ListenStream=/var/run/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service --now
sudo systemctl enable cri-docker.socket --now

# 测试
sudo crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock info

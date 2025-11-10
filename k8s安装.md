### K8s集群部署

### 1、禁用 Swap
```shell
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```
### 2、配置内核参数和加载模块
```shell
# 加载内核模块
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 配置 sysctl 参数
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# 应用 sysctl 参数
sudo sysctl --system
```
### 3、添加 Kubernetes apt 仓库 GPG 密钥
```shell
sudo apt -y update
sudo apt -y install apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.xx/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```
### 4、添加 Kubernetes apt 仓库
```shell
# 确保 'v1.xx' 替换为你想要安装的 Kubernetes 主要版本 (例如 v1.30)
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.xx/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
### 5、安装 Kubeadm、Kubelet 和 Kubectl
```shell
sudo apt -y update
# 安装特定版本，例如 1.28.0-1.1，避免自动升级导致集群不稳定
# 使用 apt-cache madison kubeadm 查看可用版本
sudo apt install -y kubelet kubeadm kubectl
# 阻止它们自动更新
sudo apt-mark hold kubelet kubeadm kubectl
```
### 主节点初始化
```shell
kubeadm init \
    --control-plane-endpoint=192.168.92.201:6443 \
    --pod-network-cidr=10.244.0.0/16 \
    --cri-socket=unix:///run/containerd/containerd.sock
```

### 主节点
```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 子节点加入到集群
```shell
kubeadm join 192.168.92.201:6443 --token 2ur29g.pixhcv6rf8fs0j0z \
        --discovery-token-ca-cert-hash sha256:8f2df24c15ae9cac485da1ca9dc276be5d29ac916d7530b1bc7c2f9c786f1bee 
```

### 主节点生成token
```shell
kubeadm token create
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
    | openssl rsa -pubin -outform der 2>/dev/null \
    | sha256sum | awk '{print $1}'
```
### 子节点使用新的token
```shell

kubeadm reset -f --cri-socket=unix:///var/run/cri-dockerd.sock
kubeadm join echovoid.top:6443 \
  --token 57w8cj.vc5sgn7nxsaj58ii \
  --cri-socket=unix:///var/run/cri-dockerd.sock \
  --discovery-token-ca-cert-hash sha256:76b073df6f4ffd9fe1ea03fc77430650a3ee2188292e89a1d871ac87e863e54a
```
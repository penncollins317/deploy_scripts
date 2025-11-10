#!/usr/bin/bash
set -e

echo "🧹 停止 kubelet 服务..."
sudo systemctl stop kubelet || true
sudo systemctl disable kubelet || true

echo "🧼 执行 kubeadm reset..."
sudo kubeadm reset -f || true

echo "🗑️ 删除 CNI 网络配置..."
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/cni/
sudo rm -rf /var/lib/etcd
sudo rm -rf /etc/kubernetes/

echo "🧹 删除 kubeconfig 文件..."
sudo rm -rf $HOME/.kube

echo "🧹 清理容器运行时的残留容器与镜像..."
# 针对 containerd / docker 环境自动检测
if systemctl is-active --quiet containerd; then
  echo "检测到 containerd，正在清理..."
  sudo ctr --namespace k8s.io containers ls -q | xargs -r sudo ctr --namespace k8s.io containers rm || true
  sudo ctr --namespace k8s.io images ls -q | xargs -r sudo ctr --namespace k8s.io images rm || true
elif systemctl is-active --quiet docker; then
  echo "检测到 Docker，正在清理..."
  sudo docker ps -aq | xargs -r sudo docker rm -f || true
  sudo docker images -q | xargs -r sudo docker rmi -f || true
fi

echo "🧽 清理 systemd 配置..."
sudo rm -f /etc/systemd/system/kubelet.service
sudo rm -rf /etc/systemd/system/kubelet.service.d

sudo systemctl daemon-reload

echo "🗂️ 清理日志和缓存..."
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /var/log/pods/
sudo rm -rf /var/log/containers/

echo "✅ K8s 环境已彻底清理完成！"
echo
echo "👉 你现在可以重新运行 kubeadm init。"

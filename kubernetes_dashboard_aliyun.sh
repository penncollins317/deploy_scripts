#!/usr/bin/bash

# 下载 Dashboard YAML（使用 ghproxy 国内中转）
wget -O dashboard.yaml https://ghproxy.cn/https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 修改镜像为阿里云镜像（可直接运行以下命令）
sed -i 's#kubernetesui/dashboard:#registry.cn-hangzhou.aliyuncs.com/google_containers/dashboard:#g' dashboard.yaml
sed -i 's#kubernetesui/metrics-scraper:#registry.cn-hangzhou.aliyuncs.com/google_containers/metrics-scraper:#g' dashboard.yaml

# 应用配置
kubectl apply -f dashboard.yaml

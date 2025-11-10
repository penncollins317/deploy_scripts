### 官方脚本
```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

### 使用镜像
```shell
# 下载 Dashboard YAML（使用 ghproxy 国内中转）
wget -O dashboard.yaml https://ghproxy.cn/https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 修改镜像为阿里云镜像（可直接运行以下命令）
sed -i 's#kubernetesui/dashboard:#registry.cn-hangzhou.aliyuncs.com/google_containers/dashboard:#g' dashboard.yaml
sed -i 's#kubernetesui/metrics-scraper:#registry.cn-hangzhou.aliyuncs.com/google_containers/metrics-scraper:#g' dashboard.yaml

# 应用配置
kubectl apply -f dashboard.yaml
```
### 2、暴露 Dashboard 访问方式
```shell
kubectl -n kubernetes-dashboard edit service kubernetes-dashboard
```
### 3、修改一下字段
```shell
spec:
  type: NodePort
```

### 4、保存后查看端口
```shell
kubectl -n kubernetes-dashboard get svc
```

### 5、创建管理员账号
```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```
### 6、获取Token
```shell
kubectl -n kubernetes-dashboard create token admin-user
```
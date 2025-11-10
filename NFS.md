


### 挂载硬盘
### 格式化
```shell
sudo mkfs.ext4 -F /dev/sdb1
```
```shell
sudo mkdir -p /data
sudo mount /dev/sdb1 /data
```

### 自动挂载
```shell
sudo blkid /dev/sdb1
```
### NFS安装
```shell
sudo apt install -y nfs-kernel-server
sudo mkdir -p /data/nfs
sudo chown nobody:nogroup /data/nfs
sudo chmod 777 /data/nfs
```
### 配置共享目录
### vim /etc/exports,增加下面代码
```shell
/data/nfs  *(rw,sync,no_subtree_check,no_root_squash)
```
### 使配置生效
```shell
sudo exportfs -rav
sudo exportfs -v
sudo systemctl enable --now nfs-server
sudo systemctl status nfs-server
```

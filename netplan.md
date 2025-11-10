### 禁用Cloud-init的网络配置

```shell
sudo touch /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```

### 网络配置

```shell
sudo touch /etc/netplan/01-netcfg.yaml
```

### 写入网络配置

```shell
sudo tee /etc/netplan/01-netcfg.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.92.210/24
      routes:
        - to: default
          via: 192.168.92.2
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
EOF
sudo netplan apply

```
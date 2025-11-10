#!/usr/bin/bash

sudo apt install -y nfs-kernel-server
sudo mkdir -p /data/nfs
sudo chown nobody:nogroup /data/nfs
sudo chmod 777 /data/nfs
sudo touch /etc/exports

sudo tee /etc/exports <<-'EOF'
/data/nfs  *(rw,sync,no_subtree_check,no_root_squash)
EOF

sudo exportfs -rav
sudo exportfs -v
sudo systemctl enable --now nfs-server
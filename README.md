### nginx配置

```text
upstream odoo {
    server web:8069;
}

upstream odoo-chat {
    server web:8072;
}

server {
    listen 80;
    listen 443 ssl;
    server_name _;

    ssl_certificate     /etc/nginx/certs/ssl.pem;
    ssl_certificate_key /etc/nginx/certs/ssl.key;

    location / {
        proxy_pass http://odoo;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }

    location /websocket {
        proxy_pass http://odoo-chat;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # 静态文件（可选，提升性能）
    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
    }
}
```

## 运行nginx

```shell
docker run --rm -it \
  -p 80:80 \
  -p 443:443 \
  -v /web/zlyj/nginx/nginx.conf:/etc/nginx/conf.d/default.conf \
  -v /web/zlyj/nginx/certs:/etc/nginx/certs:ro \
  nginx
```

## docker-compose.yaml

```text
services:
  web:
    image: odoo:17.0
    container_name: odoo17
    restart: always
    depends_on:
      - db
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=odoo
    volumes:
      - odoo-web-data:/var/lib/odoo
      - odoo-config:/etc/odoo

  db:
    image: postgres:16
    container_name: odoo17_db
    restart: always
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - odoo-db-data:/var/lib/postgresql/data/pgdata

  nginx:
    image: nginx:latest
    container_name: odoo17_nginx
    restart: always
    depends_on:
      - web
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf
      - ./nginx/certs:/etc/nginx/certs:ro
      - ./nginx/log:/var/log/nginx

volumes:
  odoo-web-data:
  odoo-db-data:
  odoo-config:
  odoo-addons:
```

### odoo模块更新

#### 1、停止web服务

```shell
docker compose stop web
```

#### 2、启动更新服务

```shell
docker compose run --rm web \
  -d odoo17_db -u base --stop-after-init --max-cron-threads=0
```

#### 3、更新完成后，重新启动web服务

```shell
docker compose start web
```

#### 4、更新服务

```shell
docker compose down --rmi=local && docker compose up -d && docker compose logs -f 
```

## 系统服务部署

```shell
sudo useradd postgres
sudo mkdir /data/pgsql
sudo chown postgres  /data/pgsql

sudo su - postgres

/usr/local/postgresql/bin/initdb -D /data/pgsql

vi /etc/systemd/system/postgresql.service

[Unit]
Description=postgresql
After=network.target

[Service]
Type=forking
User=postgres
SyslogIdentifier=postgres
PermissionsStartOnly=true
ExecStart=/usr/local/postgresql/bin/pg_ctl -D /data/pgsql -l logfile star
StandardOutput=journal+console
[Install]
WantedBy=multi-user.target


psql -U postgres

CREATE USER odoo WITH PASSWORD 'zkodoo2024pg' SUPERUSER;
CREATE DATABASE odoo OWNER odoo;
 



[options]
addons_path = /web/odoo17/odoo/addons
admin_passwd = admin
db_name = odoo_
db_host = localhost
db_user = odoo
db_password = odoo
db_port = 5432
logfile = /var/log/odoo17.log
gevent_port = 8072
http_port = 8069
workers = 2
pg_path = /usr/local/postgresql/bin
bin_path = /usr/bin/wkhtmltopdf/bin
log_level = info
log_handler = odoo.fields:ERROR,odoo.models:ERROR,odoo.addons.base.models.ir_model:ERROR,odoo.modules.module:ERROR
proxy_mode = True





[Unit]
Description=odoo17post
After=network.target,postgresql.service

[Service]
Type=simple
User=ubuntu
SyslogIdentifier=odoo17
PermissionsStartOnly=true
ExecStart=/usr/local/python311/venvs/odoo17/bin/python /web/odoo17/odoo-bin -c /web/odoo17/odoo.conf
StandardOutput=append:/usr/log/odoo.log
StandardError=append:/usr/log/odoo.log
[Install]
WantedBy=multi-user.target
```
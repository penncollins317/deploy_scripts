#!/usr/local/python3/venvs/odoo17/bin/python
import datetime
import logging
import os
import shutil
import subprocess

import qiniu

qiniu_access_key = os.getenv('QINIU_ACCESS_KEY', '')
qiniu_secret_key = os.getenv('QINIU_SECRET_KEY', '')
qiniu_bucket_name = os.getenv('QINIU_BUCKET_NAME', '')

# ====== 配置部分 ======
DB_NAME = "odoo17post"
DB_USER = "postgres"
DB_PASSWORD = "postgres"
DB_HOST = "127.0.0.1"
DB_PORT = "5432"

BACKUP_DIR = r"D:/data/db_backups"
RETENTION_DAYS = 7  # 保留7天

LOG_FILE = r"D:/data/db_backups/backup.log"

# ====== 初始化日志 ======
os.makedirs(BACKUP_DIR, exist_ok=True)
logging.basicConfig(filename=LOG_FILE, level=logging.INFO,
                    format="%(asctime)s [%(levelname)s] %(message)s")

# ====== 生成备份文件名 ======
timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
backup_filename = f"{DB_NAME}_{timestamp}.sql"
backup_path = os.path.join(BACKUP_DIR, backup_filename)


def upload_oss(file_path):
    if all([qiniu_access_key, qiniu_secret_key, qiniu_bucket_name]):
        auth = qiniu.Auth(qiniu_access_key, qiniu_secret_key)
        key = f"pg_back/{backup_filename}"
        token = auth.upload_token(qiniu_bucket_name, key)
        logging.info("qiniu upload key:%s token: %s", key, token)

        with open(file_path, 'rb') as fd:
            res = qiniu.put_data(token, key, fd.read())
            logging.info(f"qiniu upload:{res}")


# ====== 备份逻辑 ======
def backup_database():
    logging.info(f"开始备份数据库：{DB_NAME}")
    env = os.environ.copy()
    env["PGPASSWORD"] = DB_PASSWORD

    try:
        # 调用 pg_dump
        subprocess.run([
            "pg_dump",
            "-h", DB_HOST,
            "-p", DB_PORT,
            "-U", DB_USER,
            "-F", "p",  # 纯文本SQL格式
            "-f", backup_path,
            DB_NAME
        ], env=env, check=True)

        # 压缩备份
        compressed_file = f"{backup_path}.tar.gz"
        with open(backup_path, 'rb') as f_in:
            with open(compressed_file, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        os.remove(backup_path)

        logging.info(f"备份完成：{compressed_file}")
        upload_oss(compressed_file)
    except subprocess.CalledProcessError as e:
        logging.error(f"备份失败：{e}")
    except Exception as e:
        logging.error(f"未知错误：{e}")


# ====== 清理旧备份 ======
def cleanup_old_backups():
    logging.info("开始清理旧备份...")
    now = datetime.datetime.now()
    for filename in os.listdir(BACKUP_DIR):
        if filename.endswith(".tar.gz"):
            file_path = os.path.join(BACKUP_DIR, filename)
            file_time = datetime.datetime.fromtimestamp(os.path.getmtime(file_path))
            if (now - file_time).days > RETENTION_DAYS:
                os.remove(file_path)
                logging.info(f"已删除旧备份：{filename}")


if __name__ == "__main__":
    backup_database()
    cleanup_old_backups()

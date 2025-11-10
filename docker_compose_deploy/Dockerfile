FROM odoo:17
USER root
COPY requirements.txt /mnt/extra-addons/requirements.txt
RUN pip3 install --no-cache-dir -r /mnt/extra-addons/requirements.txt -i  https://mirrors.huaweicloud.com/repository/pypi/simple
RUN pip3 install --no-cache-dir --upgrade urllib3 -i  https://mirrors.huaweicloud.com/repository/pypi/simple
RUN pip3 install --no-cache-dir --upgrade pyopenssl -i  https://mirrors.huaweicloud.com/repository/pypi/simple
USER odoo
#COPY module_source/. /mnt/extra-addons/
COPY odoo.conf /etc/odoo
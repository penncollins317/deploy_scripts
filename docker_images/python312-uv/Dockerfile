# 基础 Python 镜像
FROM python:3.12-slim-bookworm

LABEL description="Python 3.12 slim with uv and HuaweiCloud PyPI mirror"

# 统一工作目录（供子镜像继承）
WORKDIR /app

# Python / uv 运行时环境变量
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_SYSTEM_PYTHON=1 \
    UV_INDEX_URL=https://mirrors.huaweicloud.com/repository/pypi/simple

# 安装 uv（使用华为云镜像）
RUN pip install --no-cache-dir uv \
    -i https://mirrors.huaweicloud.com/repository/pypi/simple

# 基础验证（构建期）
RUN python --version && uv --version

# 不指定具体应用启动
CMD ["python"]
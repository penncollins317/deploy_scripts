FROM python:3.12-slim-bookworm

LABEL description="Python 3.12 + Node.js 24.12.0 base image"

# -----------------------------
# 系统基础工具
# -----------------------------
RUN apt-get update && apt-get install -y \
    curl \
    xz-utils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 安装指定版本 Node.js（v24.12.0 官方二进制包）
ENV NODE_VERSION=24.12.0

RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
      -o node.tar.xz \
    && tar -xJf node.tar.xz -C /usr/local --strip-components=1 \
    && rm node.tar.xz

# -----------------------------
# 基础验证（构建期）
# -----------------------------
RUN python --version \
    && node --version \
    && npm --version

RUN npm install pnpm -g
RUN npm install yarn -g

# -----------------------------
# 统一工作目录（供子镜像继承）
# -----------------------------
WORKDIR /workspace

# 默认不启动任何应用
CMD ["bash"]

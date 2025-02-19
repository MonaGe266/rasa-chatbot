FROM python:3.9-slim-buster as builder

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# 安装构建依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /build

# 只复制必要的文件
COPY requirements.txt .

# 安装依赖到指定目录
RUN python -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --no-cache-dir rasa==3.6.2 rasa-sdk==3.6.1 jieba==0.42.1

# 第二阶段：最终镜像
FROM python:3.9-slim-buster

# 设置环境变量
ENV PORT=5005 \
    RASA_TELEMETRY_ENABLED=false \
    RASA_WORKERS=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# 从构建阶段复制虚拟环境
COPY --from=builder /opt/venv /opt/venv

# 复制项目文件
COPY config.yml domain.yml endpoints.yml ./
COPY data/ data/

# 创建模型目录并训练
RUN mkdir -p models && \
    rasa train --num-threads 1

# 暴露端口
EXPOSE 5005

# 启动命令
CMD rasa run --enable-api --cors "*" --port $PORT --host 0.0.0.0 
FROM python:3.9-slim-buster as builder

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# 创建非 root 用户
RUN groupadd -r rasa && useradd -r -g rasa -s /sbin/nologin -d /home/rasa rasa \
    && mkdir -p /home/rasa \
    && chown -R rasa:rasa /home/rasa

# 安装构建依赖
RUN mkdir -p /usr/share/man/man1 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    gcc \
    curl \
    xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/man/* \
    && apt-get clean

# 设置工作目录
WORKDIR /build

# 创建并设置虚拟环境
RUN python -m venv /opt/venv && \
    chown -R rasa:rasa /opt/venv

# 切换到非 root 用户
USER rasa

# 安装 Rasa 和基础依赖
RUN . /opt/venv/bin/activate && \
    pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir rasa==3.5.14

# 安装额外依赖
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir jieba==0.42.1

# 第二阶段：最终镜像
FROM python:3.9-slim-buster

# 创建非 root 用户
RUN groupadd -r rasa && useradd -r -g rasa -s /sbin/nologin -d /home/rasa rasa \
    && mkdir -p /home/rasa \
    && chown -R rasa:rasa /home/rasa

# 设置环境变量
ENV PORT=5005 \
    RASA_TELEMETRY_ENABLED=false \
    RASA_WORKERS=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    RASA_MEMORY_LIMIT=512m \
    RASA_MAX_TRAINING_PROCESSES=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /app

# 从构建阶段复制虚拟环境
COPY --from=builder --chown=rasa:rasa /opt/venv /opt/venv

# 复制项目文件
COPY --chown=rasa:rasa config.yml domain.yml endpoints.yml ./
COPY --chown=rasa:rasa data/ data/

# 创建模型目录
RUN mkdir -p models && \
    chown -R rasa:rasa /app

# 切换到非 root 用户
USER rasa

# 训练模型
RUN . /opt/venv/bin/activate && \
    rasa train --num-threads 1

# 暴露端口
EXPOSE $PORT

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:$PORT/status || exit 1

# 启动命令
CMD . /opt/venv/bin/activate && \
    rasa run --enable-api --cors "*" --port $PORT --host 0.0.0.0 
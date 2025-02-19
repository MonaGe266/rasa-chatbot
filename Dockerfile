FROM python:3.9-slim

# 设置环境变量
ENV PORT=5005
ENV RASA_TELEMETRY_ENABLED=false
ENV RASA_MEMORY_LIMIT=512m
ENV RASA_WORKERS=1
ENV RASA_MAX_TRAINING_PROCESSES=1
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# 安装系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制依赖文件并安装
COPY requirements.txt requirements.txt
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    rm -rf /root/.cache/pip

# 复制项目文件
COPY config.yml domain.yml credentials.yml endpoints.yml ./
COPY data/ data/

# 创建模型目录并训练
RUN mkdir -p models && \
    rasa train --num-threads 1 --debug && \
    rm -rf /tmp/* /var/tmp/*

# 暴露端口
EXPOSE ${PORT}

# 启动命令
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "5005", "--host", "0.0.0.0", "--num-threads", "1", "--debug"] 
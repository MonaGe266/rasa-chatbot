FROM python:3.9-slim

# 设置环境变量
ENV PORT=5005 \
    RASA_TELEMETRY_ENABLED=false \
    RASA_MEMORY_LIMIT=512m \
    RASA_WORKERS=1 \
    RASA_MAX_TRAINING_PROCESSES=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    SQLALCHEMY_SILENCE_UBER_WARNING=1

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

# 只复制必要的文件
COPY requirements.txt .
COPY config.yml domain.yml credentials.yml endpoints.yml ./
COPY data/ data/

# 安装依赖
RUN pip install --upgrade pip && \
    pip install --no-cache-dir rasa==3.6.2 rasa-sdk==3.6.1 jieba==0.42.1 && \
    rm -rf /root/.cache/pip

# 创建模型目录并训练
RUN mkdir -p models && \
    rasa train --num-threads 1 && \
    rm -rf /tmp/* /var/tmp/*

# 暴露端口
EXPOSE 5005

# 启动命令
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "5005", "--host", "0.0.0.0"] 
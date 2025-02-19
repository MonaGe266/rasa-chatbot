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

# 分步安装依赖
COPY requirements.txt requirements.txt
RUN pip install --upgrade pip && \
    pip install --no-cache-dir numpy==1.23.5 && \
    pip install --no-cache-dir scikit-learn==1.0.2 && \
    pip install --no-cache-dir protobuf==3.20.3 && \
    pip install --no-cache-dir tensorflow-cpu==2.11.0 && \
    pip install --no-cache-dir torch==1.12.1 --extra-index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir transformers==4.28.1 && \
    pip install --no-cache-dir jieba==0.42.1 && \
    pip install --no-cache-dir rasa==3.6.2 rasa-sdk==3.6.1 && \
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
#!/bin/bash

# 更新系统
sudo apt-get update
sudo apt-get upgrade -y

# 安装必要的系统工具
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git

# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 创建部署目录
mkdir -p ~/rasa_project

# 配置防火墙
sudo apt-get install -y ufw
sudo ufw allow 22/tcp
sudo ufw allow 5005/tcp
sudo ufw --force enable

# 创建部署用户
sudo useradd -m -s /bin/bash rasa_user
sudo usermod -aG docker rasa_user

# 设置目录权限
sudo chown -R rasa_user:rasa_user ~/rasa_project

echo "服务器初始化完成！" 
#!/bin/bash

# 确保脚本在错误时停止
set -e

# 检查是否提供了服务器 IP
if [ -z "$1" ]; then
    echo "请提供服务器 IP 地址"
    echo "使用方法: ./deploy.sh <服务器IP>"
    exit 1
fi

SERVER_IP=$1
DEPLOY_PATH="/home/rasa_user/rasa_project"

echo "开始部署 Rasa 到服务器 $SERVER_IP..."

# 打包项目文件
echo "打包项目文件..."
tar --exclude='*.tar.gz' --exclude='node_modules' --exclude='__pycache__' -czf rasa_project.tar.gz .

# 复制文件到服务器
echo "复制文件到服务器..."
scp rasa_project.tar.gz server_setup.sh "root@$SERVER_IP:/root/"

# 在服务器上执行初始化脚本
echo "初始化服务器..."
ssh "root@$SERVER_IP" 'bash -s' < server_setup.sh

# 部署 Rasa
echo "部署 Rasa..."
ssh "root@$SERVER_IP" << EOF
    cd /root
    tar xzf rasa_project.tar.gz -C $DEPLOY_PATH
    chown -R rasa_user:rasa_user $DEPLOY_PATH
    cd $DEPLOY_PATH
    docker-compose down || true
    docker-compose up -d --build
EOF

# 清理本地临时文件
rm rasa_project.tar.gz

echo "部署完成！"
echo "Rasa 服务器地址: http://$SERVER_IP:5005"
echo "请更新 .env.local 文件中的 RASA_SERVER_URL" 
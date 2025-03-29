

#!/bin/bash

# 自动加载 .env 环境变量
set -o allexport
source ~/bitagere-node-tools/.env
set +o allexport

# 使用 .env 配置重启 BitAgere 审计节点

set -o allexport
source "$(dirname "$0")/../.env"
set +o allexport

source /home/ubuntu/RelayAgere/RelayAgere/.venv/bin/activate
cd /home/ubuntu/RelayAgere/RelayAgere

pkill -f auditor.py
nohup $AUDITOR_SCRIPT_PATH $COLD_WALLET_NAME > ~/auditor_restart.log 2>&1 &

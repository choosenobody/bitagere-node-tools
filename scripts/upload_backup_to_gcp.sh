#!/bin/bash
# 上传最近一次的备份文件到 GCP Bucket

set -o allexport
source "$(dirname "$0")/../.env"
set +o allexport

# 获取最新备份文件
BACKUP_FILE=$(ls -t "$BACKUP_DIR"/bitagere_backup_*.tar.gz 2>/dev/null | head -n 1)

# 检查是否存在备份文件
if [ -z "$BACKUP_FILE" ]; then
  echo "[错误] 未找到任何备份文件，请先执行备份。"
  exit 1
fi

# 上传到 GCP
echo "[INFO] 正在上传备份文件：$BACKUP_FILE 到 GCP Bucket：$GCP_BUCKET_NAME ..."
gsutil cp "$BACKUP_FILE" gs://"$GCP_BUCKET_NAME"/

if [ $? -eq 0 ]; then
  echo "✅ 上传成功：$BACKUP_FILE"
else
  echo "❌ 上传失败，请检查 GCP 配置和 Bucket 权限。"
fi

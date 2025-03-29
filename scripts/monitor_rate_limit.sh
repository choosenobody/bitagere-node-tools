#!/bin/bash
# BitAgere 审计节点状态监控 + 限流检测 + 自动重启 + 邮件通知

# ========== 步骤 1：加载 .env 配置 ==========
set -o allexport
source "$(dirname "$0")/../.env"
set +o allexport

# ========== 步骤 2：定义日志路径 ==========
LOG_FILE="$HOME/rate_limit_monitor.log"

# ========== 步骤 3：检查程序是否挂掉 ==========
check_auditor_alive() {
    RUNNING=$(pgrep -f auditor.py)
    if [ -z "$RUNNING" ]; then
        echo "[警告] 审计程序未运行，尝试重启..." >> "$LOG_FILE"
        nohup "$AUDITOR_SCRIPT_PATH" "$COLD_WALLET_NAME" >> "$HOME/auditor_runtime.log" 2>&1 &
        if [ $? -ne 0 ]; then
            echo "[错误] 审计程序启动失败，请检查系统状态。" | \
            mail -s "[严重] BitAgere 审计程序未运行且自动重启失败 $(date +'%F %T')" "$EMAIL_RECIPIENT"
        else
            echo "[INFO] 节点已重启" >> "$LOG_FILE"
        fi
    else
        echo "[INFO] 审计程序运行正常（PID: $RUNNING）" >> "$LOG_FILE"
    fi
}

# ========== 步骤 4：检查是否触发限流 ==========
check_rate_limit() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 检查节点是否触发限流..." >> "$LOG_FILE"
    RESPONSE=$(tail -n 100 "$HOME/auditor_runtime.log" 2>/dev/null | grep -c "ServingRateLimitExceeded")
    
    if [ "$RESPONSE" -gt 0 ]; then
        echo "[警告] 检测到限流，正在重启节点..." >> "$LOG_FILE"

        # 邮件通知
        echo "[通知] BitAgere 节点出现限流错误，正在冷却重启中..." | \
        mail -s "[警告] BitAgere 节点触发限流 $(date +'%F %T')" "$EMAIL_RECIPIENT"

        pkill -f auditor.py
        sleep 1800  # 冷却 30 分钟

        nohup "$AUDITOR_SCRIPT_PATH" "$COLD_WALLET_NAME" >> "$HOME/auditor_runtime.log" 2>&1 &
        if [ $? -ne 0 ]; then
            echo "[错误] BitAgere 节点冷却后重启失败，请检查系统状态。" | \
            mail -s "[严重] BitAgere 节点冷却后重启失败 $(date +'%F %T')" "$EMAIL_RECIPIENT"
        else
            echo "[INFO] 节点重启完成" >> "$LOG_FILE"
        fi
    else
        echo "[INFO] 节点未触发限流，无需操作。" >> "$LOG_FILE"
    fi
}

# ========== 主流程 ==========
check_auditor_alive
check_rate_limit

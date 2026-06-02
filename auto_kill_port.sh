#!/bin/bash

# 自动检查并 kill 占用 7860 端口的服务
PORT=7860

echo "自动检查端口 $PORT 占用情况..."

# 获取占用该端口的进程ID
PID=$(lsof -ti:$PORT 2>/dev/null)

if [ -n "$PID" ]; then
    echo "发现占用端口 $PORT 的进程: $PID"
    echo "正在自动结束这些进程..."
    
    # 获取进程详细信息
    echo "将被结束的进程:"
    ps -p $PID -o pid,user,command 2>/dev/null || echo "无法获取进程详细信息"
    
    # 尝试正常结束进程
    kill $PID 2>/dev/null
    sleep 1
    
    # 如果进程仍在运行，强制结束
    if lsof -ti:$PORT >/dev/null 2>&1; then
        echo "进程仍在运行，尝试强制结束..."
        kill -9 $PID 2>/dev/null
        sleep 1
    fi
    
    # 最终检查
    if lsof -ti:$PORT >/dev/null 2>&1; then
        echo "警告: 无法完全释放端口 $PORT，可能被系统进程占用"
        echo "请手动检查: lsof -i:$PORT"
    else
        echo "成功: 端口 $PORT 已释放"
    fi
else
    echo "端口 $PORT 未被占用"
fi

echo "端口清理完成"
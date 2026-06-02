#!/bin/bash

# 检查并 kill 占用 7860 端口的服务
PORT=7860

echo "检查端口 $PORT 是否被占用..."

# 获取占用该端口的进程ID
PID=$(lsof -ti:$PORT 2>/dev/null)

if [ -n "$PID" ]; then
    echo "发现占用端口 $PORT 的进程: $PID"
    
    # 获取进程详细信息
    echo "进程详细信息:"
    ps -p $PID -o pid,user,command
    
    # 询问用户是否要 kill 进程
    read -p "是否要 kill 这些进程? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "正在 kill 进程 $PID..."
        kill -9 $PID 2>/dev/null
        
        # 等待进程结束
        sleep 2
        
        # 再次检查端口是否释放
        if lsof -ti:$PORT >/dev/null 2>&1; then
            echo "警告: 进程可能仍在运行，尝试强制结束..."
            kill -9 $PID 2>/dev/null
            sleep 1
        fi
        
        if lsof -ti:$PORT >/dev/null 2>&1; then
            echo "错误: 无法释放端口 $PORT"
            exit 1
        else
            echo "成功: 端口 $PORT 已释放"
        fi
    else
        echo "操作取消"
        exit 0
    fi
else
    echo "端口 $PORT 未被占用"
fi

echo "端口检查完成"
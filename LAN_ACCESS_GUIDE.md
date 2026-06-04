# AIpic 局域网访问配置指南

## 概述

本文档介绍如何配置AIpic Web UI以支持局域网访问，使其他设备可以通过网络访问Web界面。

## 快速开始

### 方法1：使用快速配置脚本（推荐）

```bash
# 1. 给脚本添加执行权限
chmod +x webui-lan.sh test_lan_access.sh

# 2. 配置局域网访问（使用默认IP 192.168.50.228）
./webui-lan.sh

# 或指定自定义IP和端口
./webui-lan.sh --ip 192.168.1.100 --port 8080

# 3. 启动服务
./start_lan.sh
```

### 方法2：手动配置

1. 编辑配置文件 `webui-user.sh`：
```bash
# 启用局域网访问
export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0"
```

2. 启动服务：
```bash
./start_aipic.sh
```

## 配置文件详解

### webui-user.sh 配置选项

```bash
# 基础局域网访问配置
export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0"

# GPU优化配置（RTX 4070 16GB）
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --medvram --opt-sdp-attention --xformers"

# CPU模式配置
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --skip-torch-cuda-test --use-cpu all --no-half --precision full"

# 性能优化
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --opt-channelslast"

# 启用API
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --api"

# 自动打开浏览器
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --autolaunch"
```

### 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--listen` | 监听所有网络接口 | 必需 |
| `--port` | 服务端口 | 7860 |
| `--server-name` | 服务器绑定地址 | 0.0.0.0（所有接口） |
| `--medvram` | 中等VRAM优化 | 可选 |
| `--opt-sdp-attention` | 优化注意力机制 | 可选 |
| `--xformers` | 启用xformers加速 | 可选 |
| `--api` | 启用API接口 | 可选 |
| `--autolaunch` | 自动打开浏览器 | 可选 |

## 访问地址

配置完成后，可以通过以下地址访问：

1. **本地访问**：
   ```
   http://127.0.0.1:7860
   ```

2. **局域网访问**：
   ```
   http://[本机IP地址]:7860
   ```
   例如：`http://192.168.50.228:7860`

3. **获取本机IP**：
   ```bash
   # Linux/Mac
   ifconfig | grep "inet " | grep -v 127.0.0.1
   
   # 或使用
   hostname -I
   
   # Windows
   ipconfig | findstr IPv4
   ```

## 测试局域网访问

### 使用测试脚本

```bash
# 测试默认配置
./test_lan_access.sh

# 测试指定IP和端口
./test_lan_access.sh --ip 192.168.1.100 --port 8080

# 快速配置并测试
./test_lan_access.sh --quick-configure
```

### 手动测试

1. **检查服务状态**：
   ```bash
   # 检查端口是否监听
   netstat -tuln | grep 7860
   
   # 或使用
   ss -tuln | grep 7860
   ```

2. **测试本地连接**：
   ```bash
   curl http://127.0.0.1:7860
   ```

3. **测试局域网连接**：
   ```bash
   # 从其他设备测试
   curl http://192.168.50.228:7860
   ```

## 防火墙配置

### Ubuntu/Debian (UFW)

```bash
# 允许端口
sudo ufw allow 7860/tcp

# 检查状态
sudo ufw status

# 启用防火墙
sudo ufw enable
```

### CentOS/RHEL (FirewallD)

```bash
# 允许端口
sudo firewall-cmd --add-port=7860/tcp --permanent
sudo firewall-cmd --reload

# 检查状态
sudo firewall-cmd --list-ports
```

### 通用 (iptables)

```bash
# 允许端口
sudo iptables -A INPUT -p tcp --dport 7860 -j ACCEPT

# 保存规则（Ubuntu）
sudo iptables-save > /etc/iptables/rules.v4

# 保存规则（CentOS）
sudo service iptables save
```

## 故障排除

### 问题1：无法访问服务

**症状**：其他设备无法访问 `http://[IP]:7860`

**解决方案**：
1. 检查服务是否正在运行：
   ```bash
   ps aux | grep python | grep launch.py
   ```

2. 检查服务绑定地址：
   ```bash
   netstat -tuln | grep 7860
   ```
   应该显示 `0.0.0.0:7860` 或 `*:7860`

3. 检查防火墙设置：
   ```bash
   sudo ufw status
   sudo iptables -L -n | grep 7860
   ```

### 问题2：端口被占用

**症状**：启动时提示端口已被占用

**解决方案**：
1. 更改端口号：
   ```bash
   # 修改配置文件
   export COMMANDLINE_ARGS="--listen --port 8080 --server-name 0.0.0.0"
   ```

2. 查找占用进程：
   ```bash
   sudo lsof -i :7860
   sudo netstat -tulpn | grep 7860
   ```

### 问题3：服务启动失败

**症状**：启动脚本报错

**解决方案**：
1. 检查Python环境：
   ```bash
   source venv/bin/activate
   python --version
   pip list | grep torch
   ```

2. 检查依赖：
   ```bash
   pip install -r requirements.txt
   ```

3. 查看日志：
   ```bash
   tail -f log.txt
   ```

### 问题4：性能问题

**症状**：访问缓慢或卡顿

**解决方案**：
1. 启用GPU优化：
   ```bash
   export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0 --medvram --opt-sdp-attention --xformers"
   ```

2. 调整内存设置：
   ```bash
   export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
   ```

3. 使用低内存模式：
   ```bash
   export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0 --lowvram"
   ```

## 高级配置

### 多用户访问

如果需要支持多用户同时访问，可以启用Gradio队列：

```bash
export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0 --gradio-queue"
```

### 身份验证

启用基本身份验证：

```bash
export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0 --gradio-auth username:password"
```

或多个用户：
```bash
export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0 --gradio-auth user1:pass1,user2:pass2"
```

### HTTPS支持

启用TLS/SSL加密：

```bash
export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0 --tls-keyfile key.pem --tls-certfile cert.pem"
```

### 自定义主题

启用深色主题：

```bash
export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0 --theme dark"
```

## 脚本说明

### webui-lan.sh

局域网访问配置脚本，提供以下功能：
- 自动检测本机IP地址
- 配置webui-user.sh文件
- 检查端口占用
- 测试网络连接
- 创建快速启动脚本

**使用方法**：
```bash
./webui-lan.sh [选项]
```

**选项**：
- `--ip IP地址`：指定IP地址
- `--port 端口号`：指定端口号
- `--restore`：恢复原始配置
- `--help`：显示帮助信息

### test_lan_access.sh

局域网访问测试脚本，提供以下功能：
- 测试本地服务状态
- 测试局域网访问
- 检查防火墙设置
- 验证网络连接
- 快速配置局域网访问

**使用方法**：
```bash
./test_lan_access.sh [选项]
```

**选项**：
- `--ip IP地址`：测试指定IP
- `--port 端口号`：测试指定端口
- `--quick-configure`：快速配置
- `--help`：显示帮助信息

### start_lan.sh

快速启动脚本，自动配置并启动服务。

## 安全建议

1. **使用防火墙**：仅允许必要的端口
2. **启用身份验证**：防止未授权访问
3. **使用HTTPS**：加密数据传输
4. **定期更新**：保持软件最新
5. **监控日志**：检查异常访问

## 常见问题

### Q: 为什么其他设备无法访问？
A: 检查以下事项：
1. 服务是否使用 `--listen` 参数启动
2. 防火墙是否允许端口访问
3. 设备是否在同一网络
4. IP地址是否正确

### Q: 如何更改访问端口？
A: 修改配置文件中的 `--port` 参数：
```bash
export COMMANDLINE_ARGS="--listen --port 8080 --server-name 0.0.0.0"
```

### Q: 如何限制访问IP？
A: 使用 `--server-name` 指定特定IP：
```bash
export COMMANDLINE_ARGS="--listen --port 7860 --server-name 192.168.1.100"
```

### Q: 服务启动很慢怎么办？
A: 尝试以下优化：
1. 启用GPU加速
2. 使用 `--medvram` 或 `--lowvram`
3. 禁用安全检查：`--disable-safe-unpickle`

## 联系支持

如果遇到问题，请：
1. 查看日志文件：`log.txt`
2. 检查配置文件：`webui-user.sh`
3. 运行测试脚本：`./test_lan_access.sh`
4. 参考官方文档

## 更新日志

### v1.0.0 (2024-01-01)
- 初始版本发布
- 支持局域网访问配置
- 提供测试和诊断工具
- 完整的文档说明
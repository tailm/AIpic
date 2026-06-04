# AIpic - Ubuntu 24.04 安装部署套件

## 概述

本套件为AIpic（Stable Diffusion Web UI）在Ubuntu 24.04系统上的安装和部署提供完整的解决方案，特别针对Python 3.13和NVIDIA RTX 4070 16GB GPU进行优化。

## 文件说明

### 核心安装脚本
1. **`install_ubuntu_24.sh`** - 主安装脚本
   - 自动检测系统配置
   - 安装系统依赖和NVIDIA驱动
   - 配置Python虚拟环境
   - 安装AIpic和所有依赖
   - 下载基础模型
   - 优化系统设置
   - 创建systemd服务

2. **`start_aipic.sh`** - 启动脚本
   - 检查端口占用
   - 应用性能优化
   - 启动Web UI服务
   - 支持自定义参数

3. **`stop_aipic.sh`** - 停止脚本
   - 安全停止Web UI服务
   - 清理进程

4. **`update_aipic.sh`** - 更新脚本
   - 更新代码仓库
   - 更新Python依赖
   - 更新PyTorch

### 维护脚本
5. **`clean_cache.sh`** - 缓存清理脚本
   - 清理Python缓存
   - 清理日志文件
   - 清理临时文件
   - 清理下载缓存
   - 支持安全/深度清理模式

6. **`optimize_performance.sh`** - 性能优化脚本
   - 清理GPU内存缓存
   - 设置CPU性能模式
   - 优化网络设置
   - 提高系统性能

7. **`start_aipic.sh`** - 智能启动脚本
   - 检查端口占用
   - 应用性能优化
   - 启动Web UI服务
   - 支持自定义参数

8. **`stop_aipic.sh`** - 安全停止脚本
   - 安全停止Web UI服务
   - 清理进程
   - 支持强制停止
   - 清理临时文件

9. **`update_aipic.sh`** - 更新脚本
   - 更新代码仓库
   - 更新Python依赖
   - 更新PyTorch
   - 备份和恢复功能

### 测试脚本
7. **`test_installation.sh`** - 安装测试脚本
   - 测试Python环境
   - 测试虚拟环境
   - 测试依赖安装
   - 测试配置文件
   - 测试网络连接
   - 测试端口可用性

### 文档文件
8. **`UBUNTU_DEPLOYMENT_GUIDE.md`** - 完整部署指南
   - 详细安装步骤
   - 系统要求说明
   - 性能优化指南
   - 故障排除手册
   - 高级配置说明

9. **`QUICK_START_UBUNTU.md`** - 快速开始指南
   - 5分钟安装指南
   - 常用命令速查
   - 快速配置说明
   - 故障排除快速指南

## 快速开始

### 一键安装
```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/tailm/AIpic/main/install_ubuntu_24.sh
chmod +x install_ubuntu_24.sh

# 运行安装脚本
./install_ubuntu_24.sh
```

### 手动安装步骤
1. **安装系统依赖**
   ```bash
   sudo apt update
   sudo apt install -y python3.13 python3.13-venv python3.13-dev git wget
   ```

2. **安装NVIDIA驱动和CUDA**
   ```bash
   sudo apt install -y nvidia-driver-550
   sudo apt install -y cuda-toolkit-12-4
   ```

3. **克隆仓库**
   ```bash
   git clone https://github.com/tailm/AIpic.git
   cd AIpic
   ```

4. **设置虚拟环境**
   ```bash
   python3.13 -m venv venv
   source venv/bin/activate
   pip install --upgrade pip
   ```

5. **安装依赖**
   ```bash
   pip install torch==2.1.0 torchvision==0.16.0 --index-url https://download.pytorch.org/whl/cu121
   pip install -r requirements.txt
   pip install xformers
   ```

6. **下载模型**
   ```bash
   mkdir -p models/Stable-diffusion
   wget -O models/Stable-diffusion/v1-5-pruned-emaonly.safetensors \
       https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors
   ```

7. **启动Web UI**
   ```bash
   ./start_aipic.sh
   ```

## 系统要求

### 最低要求
- **操作系统**: Ubuntu 24.04 LTS
- **CPU**: 4核处理器
- **RAM**: 16GB
- **GPU**: NVIDIA GPU (支持CUDA)
- **存储**: 50GB可用空间

### 推荐配置
- **操作系统**: Ubuntu 24.04 LTS
- **CPU**: 8核或以上处理器
- **RAM**: 32GB或以上
- **GPU**: NVIDIA RTX 4070 16GB或更高
- **存储**: 100GB SSD
- **Python**: 3.13或更高版本

## 功能特性

### 自动安装脚本 (`install_ubuntu_24.sh`)
- ✅ 自动检测系统配置
- ✅ 安装系统依赖
- ✅ 配置NVIDIA驱动和CUDA
- ✅ 创建Python虚拟环境
- ✅ 安装AIpic和所有依赖
- ✅ 下载基础模型
- ✅ 优化系统设置
- ✅ 创建systemd服务
- ✅ 性能调优

### 启动管理脚本
- ✅ `start_aipic.sh` - 智能启动，检查端口占用
- ✅ `stop_aipic.sh` - 安全停止服务
- ✅ `update_aipic.sh` - 一键更新

### 维护脚本
- ✅ `clean_cache.sh` - 多模式缓存清理
- ✅ `optimize_performance.sh` - 系统性能优化

### 测试脚本
- ✅ `test_installation.sh` - 全面安装测试
- ✅ 支持快速/完整测试模式
- ✅ 详细的错误报告

## 使用示例

### 完整安装和测试
```bash
# 1. 运行安装脚本
./install_ubuntu_24.sh

# 2. 测试安装
./test_installation.sh full

# 3. 启动服务
./start_aipic.sh

# 4. 访问Web UI
# 打开浏览器访问: http://localhost:7860
```

### 日常维护
```bash
# 清理缓存（安全模式）
./clean_cache.sh safe

# 优化性能
./optimize_performance.sh

# 更新AIpic
./update_aipic.sh

# 重启服务
./stop_aipic.sh && ./start_aipic.sh
```

### 系统服务管理
```bash
# 启用开机自启
sudo systemctl enable aipic

# 启动服务
sudo systemctl start aipic

# 查看状态
sudo systemctl status aipic

# 查看日志
sudo journalctl -u aipic -f
```

## 配置说明

### Web UI配置 (`webui-user.sh`)
```bash
# GPU优化设置（RTX 4070 16GB）
export COMMANDLINE_ARGS="--medvram --opt-sdp-attention --xformers --listen --port 7860"

# 性能优化
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"

# 启用API
export API=True

# 自动打开浏览器
export LAUNCH_BROWSER=True
```

### 系统服务配置 (`/etc/systemd/system/aipic.service`)
```ini
[Unit]
Description=AIpic Stable Diffusion Web UI
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/home/$USER/AIpic
Environment="PATH=/home/$USER/AIpic/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/home/$USER/AIpic/venv/bin/python launch.py --listen --port 7860 --medvram --opt-sdp-attention --xformers
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

## 故障排除

### 常见问题

1. **CUDA内存不足**
   ```bash
   # 修改webui-user.sh
   export COMMANDLINE_ARGS="--medvram --lowvram --opt-sdp-attention --xformers"
   ```

2. **端口被占用**
   ```bash
   # 查找占用进程
   sudo lsof -i :7860
   
   # 终止进程
   sudo kill -9 <PID>
   
   # 或使用其他端口
   export COMMANDLINE_ARGS="--port 7861"
   ```

3. **模型加载失败**
   ```bash
   # 重新下载模型
   cd models/Stable-diffusion
   rm v1-5-pruned-emaonly.safetensors
   wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors
   ```

4. **Web UI无法启动**
   ```bash
   # 查看详细日志
   python launch.py --listen 2>&1 | tee debug.log
   
   # 检查依赖
   source venv/bin/activate
   pip list | grep torch
   ```

### 性能优化

#### RTX 4070 16GB优化设置
```bash
# webui-user.sh中的优化参数
export COMMANDLINE_ARGS="--medvram --opt-sdp-attention --xformers --no-half-vae"

# 批量大小建议
# txt2img: 2-4张/批次
# img2img: 1-2张/批次
# 高分辨率修复: 1张/批次
```

#### 系统优化
```bash
# 增加交换空间（如果RAM不足）
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 优化swappiness
sudo sysctl vm.swappiness=10
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
```

## 监控和维护

### 资源监控
```bash
# 监控GPU使用
watch -n 1 nvidia-smi

# 监控系统资源
htop

# 监控磁盘使用
df -h

# 监控网络连接
netstat -tulpn | grep :7860
```

### 日志查看
```bash
# 查看实时日志
tail -f log.txt

# 查看systemd服务日志
sudo journalctl -u aipic -f

# 查看错误日志
grep -i error log.txt
```

### 定期维护
```bash
# 每周清理缓存
0 2 * * 0 cd /home/$USER/AIpic && ./clean_cache.sh safe

# 每月更新
0 3 1 * * cd /home/$USER/AIpic && ./update_aipic.sh

# 每天重启服务（可选）
0 4 * * * sudo systemctl restart aipic
```

## 安全建议

### 防火墙配置
```bash
# 只允许本地访问
sudo ufw allow from 127.0.0.1 to any port 7860
sudo ufw allow from ::1 to any port 7860

# 或限制特定IP
sudo ufw allow from 192.168.1.0/24 to any port 7860
```

### 使用反向代理（生产环境）
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:7860;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # 启用SSL
    listen 443 ssl;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
}
```

### 定期备份
```bash
# 备份配置和模型
tar -czf aipic_backup_$(date +%Y%m%d).tar.gz \
    config.json \
    webui-user.sh \
    models/ \
    embeddings/ \
    extensions/
```

## 支持与贡献

### 获取帮助
- **GitHub Issues**: https://github.com/tailm/AIpic/issues
- **文档**: 查看 `UBUNTU_DEPLOYMENT_GUIDE.md`
- **日志文件**: `log.txt`

### 报告问题
```bash
# 收集诊断信息
./test_installation.sh full > diagnosis.log
nvidia-smi >> diagnosis.log
python --version >> diagnosis.log
pip list >> diagnosis.log
```

### 贡献指南
1. Fork仓库
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 许可证

本套件基于MIT许可证发布。详见 [LICENSE](https://github.com/tailm/AIpic/blob/main/LICENSE) 文件。

## 更新日志

### 版本 1.0.0 (2024-01-01)
- 初始版本发布
- 支持Ubuntu 24.04
- 优化RTX 4070 16GB配置
- 完整的安装和部署套件
- 详细的文档和故障排除指南

---

**注意**: 本套件针对Ubuntu 24.04和RTX 4070 16GB进行优化。其他系统或GPU可能需要调整配置参数。建议根据实际硬件性能进行测试和调优。
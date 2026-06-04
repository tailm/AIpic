# AIpic - Stable Diffusion Web UI
# Ubuntu 24.04 部署指南

## 概述

本文档提供在 Ubuntu 24.04 系统上部署 AIpic（Stable Diffusion Web UI）的完整指南，特别针对 Python 3.13 和 NVIDIA RTX 4070 16GB GPU 进行优化。

## 系统要求

### 硬件要求
- **CPU**: 4核或以上（推荐8核）
- **RAM**: 16GB 或以上（推荐32GB）
- **GPU**: NVIDIA RTX 4070 16GB（支持CUDA的NVIDIA GPU）
- **存储**: 至少50GB可用空间（用于模型和依赖）
- **网络**: 稳定互联网连接（用于下载模型）

### 软件要求
- **操作系统**: Ubuntu 24.04 LTS
- **Python**: 3.13 或更高版本
- **CUDA**: 12.1 或更高版本
- **cuDNN**: 8.9 或更高版本
- **NVIDIA驱动**: 550 或更高版本

## 快速安装

### 方法一：使用自动安装脚本（推荐）

1. **下载安装脚本**
   ```bash
   wget https://raw.githubusercontent.com/tailm/AIpic/main/install_ubuntu_24.sh
   chmod +x install_ubuntu_24.sh
   ```

2. **运行安装脚本**
   ```bash
   ./install_ubuntu_24.sh
   ```

3. **按照提示完成安装**
   - 脚本会自动检测系统配置
   - 安装必要的系统依赖
   - 配置Python虚拟环境
   - 下载基础模型
   - 优化系统设置

### 方法二：手动安装

#### 步骤1：安装系统依赖
```bash
# 更新系统
sudo apt update
sudo apt upgrade -y

# 安装基础工具
sudo apt install -y \
    build-essential \
    git \
    wget \
    curl \
    cmake \
    pkg-config \
    python3.13 \
    python3.13-venv \
    python3.13-dev \
    python3-pip

# 安装多媒体库
sudo apt install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libopenblas-dev

# 安装图像处理库
sudo apt install -y \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libwebp-dev \
    libopenexr-dev
```

#### 步骤2：安装NVIDIA驱动和CUDA

```bash
# 添加NVIDIA驱动仓库
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt update

# 安装NVIDIA驱动（RTX 4070推荐）
sudo apt install -y nvidia-driver-550

# 重启系统
sudo reboot

# 验证驱动安装
nvidia-smi

# 安装CUDA Toolkit
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit-12-4

# 配置环境变量
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

# 验证CUDA安装
nvcc --version
```

#### 步骤3：克隆AIpic仓库
```bash
cd ~
git clone https://github.com/tailm/AIpic.git
cd AIpic
```

#### 步骤4：设置Python虚拟环境
```bash
# 创建虚拟环境
python3.13 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 升级pip
pip install --upgrade pip setuptools wheel
```

#### 步骤5：安装Python依赖
```bash
# 安装PyTorch（CUDA 12.1）
pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121

# 安装xformers（内存优化）
pip install xformers

# 安装其他依赖
pip install -r requirements.txt

# 安装性能优化包
pip install \
    triton \
    flash-attn \
    ninja \
    packaging
```

#### 步骤6：下载模型
```bash
# 创建模型目录
mkdir -p models/Stable-diffusion
mkdir -p models/VAE
mkdir -p models/Lora
mkdir -p embeddings

# 下载Stable Diffusion 1.5模型
wget -O models/Stable-diffusion/v1-5-pruned-emaonly.safetensors \
    https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors

# 下载VAE模型
wget -O models/VAE/vae-ft-mse-840000-ema-pruned.safetensors \
    https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors
```

#### 步骤7：配置系统
```bash
# 创建配置文件
cat > webui-user.sh << 'EOF'
#!/usr/bin/env bash

# GPU优化设置（RTX 4070 16GB）
export COMMANDLINE_ARGS="--medvram --opt-sdp-attention --xformers --listen --port 7860"

# 性能优化
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
export CUDA_VISIBLE_DEVICES=0

# 可选：启用API
# export API=True

# 可选：自动打开浏览器
# export LAUNCH_BROWSER=True
EOF

chmod +x webui-user.sh
```

#### 步骤8：启动Web UI
```bash
# 启动脚本
./webui.sh

# 或使用优化启动
./start_aipic.sh
```

## RTX 4070 16GB 优化配置

### VRAM优化设置
RTX 4070 16GB VRAM配置建议：

```bash
# webui-user.sh 中的优化参数
export COMMANDLINE_ARGS="--medvram --opt-sdp-attention --xformers --no-half-vae --disable-nan-check"

# 各参数说明：
# --medvram: 中等VRAM使用模式，适合16GB GPU
# --opt-sdp-attention: 使用优化的注意力实现
# --xformers: 内存高效的注意力机制
# --no-half-vae: VAE不使用半精度，提高稳定性
# --disable-nan-check: 禁用NaN检查，提高性能
```

### 批量大小建议
- **txt2img**: 2-4张/批次
- **img2img**: 1-2张/批次
- **高分辨率修复**: 1张/批次
- **LoRA训练**: 1-2张/批次

### 分辨率设置
- **基础分辨率**: 512x512 或 768x768
- **高分辨率修复**: 最高 1024x1024
- **放大倍数**: 2x（ESRGAN）

## 性能调优

### 系统级优化

1. **增加交换空间**（如果RAM不足）：
   ```bash
   sudo fallocate -l 16G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

2. **优化swappiness**：
   ```bash
   sudo sysctl vm.swappiness=10
   echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
   ```

3. **增加文件描述符限制**：
   ```bash
   echo "fs.file-max = 65535" | sudo tee -a /etc/sysctl.conf
   echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
   echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
   ```

4. **启用GPU持久模式**：
   ```bash
   sudo nvidia-smi -pm 1
   ```

### 应用级优化

1. **使用性能优化脚本**：
   ```bash
   ./optimize_performance.sh
   ```

2. **清理GPU内存缓存**：
   ```bash
   sudo nvidia-smi --gpu-reset
   ```

3. **设置CPU性能模式**：
   ```bash
   for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
       echo "performance" | sudo tee $cpu
   done
   ```

## 系统服务配置

### 创建systemd服务

```bash
sudo tee /etc/systemd/system/aipic.service << EOF
[Unit]
Description=AIpic Stable Diffusion Web UI
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/AIpic
Environment="PATH=$HOME/AIpic/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$HOME/AIpic/venv/bin/python launch.py --listen --port 7860 --medvram --opt-sdp-attention --xformers
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

# 安全加固
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$HOME/AIpic
ReadWritePaths=/tmp

# 资源限制
MemoryLimit=16G
CPUQuota=200%

[Install]
WantedBy=multi-user.target
EOF
```

### 管理服务
```bash
# 重新加载systemd配置
sudo systemctl daemon-reload

# 启用开机自启
sudo systemctl enable aipic

# 启动服务
sudo systemctl start aipic

# 查看状态
sudo systemctl status aipic

# 查看日志
sudo journalctl -u aipic -f
```

## 故障排除

### 常见问题

#### 1. CUDA错误
**症状**: `CUDA error: out of memory` 或 `CUDA error: unknown error`

**解决方案**：
```bash
# 减少VRAM使用
export COMMANDLINE_ARGS="--medvram --lowvram --opt-sdp-attention"

# 清理GPU内存
sudo nvidia-smi --gpu-reset

# 重启服务
sudo systemctl restart aipic
```

#### 2. PyTorch版本不兼容
**症状**: `RuntimeError: CUDA error: no kernel image is available for execution`

**解决方案**：
```bash
# 重新安装正确版本的PyTorch
pip uninstall torch torchvision torchaudio
pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121
```

#### 3. 模型加载失败
**症状**: `Error loading model` 或 `KeyError: 'model.diffusion_model'`

**解决方案**：
```bash
# 检查模型文件完整性
sha256sum models/Stable-diffusion/*.safetensors

# 重新下载模型
rm models/Stable-diffusion/v1-5-pruned-emaonly.safetensors
wget -O models/Stable-diffusion/v1-5-pruned-emaonly.safetensors \
    https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors
```

#### 4. 端口被占用
**症状**: `Address already in use`

**解决方案**：
```bash
# 查找占用端口的进程
sudo lsof -i :7860

# 终止进程
sudo kill -9 <PID>

# 或使用其他端口
export COMMANDLINE_ARGS="--port 7861"
```

### 性能监控

#### GPU监控
```bash
# 实时GPU使用情况
watch -n 1 nvidia-smi

# 详细GPU信息
nvidia-smi --query-gpu=timestamp,name,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used,temperature.gpu --format=csv -l 1
```

#### 系统监控
```bash
# CPU和内存使用
htop

# 磁盘IO
iotop

# 网络连接
netstat -tulpn | grep :7860
```

#### 应用日志
```bash
# 查看实时日志
tail -f ~/AIpic/log.txt

# 查看systemd服务日志
sudo journalctl -u aipic -f
```

## 高级配置

### 多GPU支持
如果系统有多个GPU：

```bash
# 使用特定GPU
export CUDA_VISIBLE_DEVICES=0  # 只使用第一个GPU
# export CUDA_VISIBLE_DEVICES=0,1  # 使用前两个GPU

# 在webui-user.sh中添加
export COMMANDLINE_ARGS="--device-id 0 --medvram --opt-sdp-attention"
```

### 模型管理

#### 添加新模型
```bash
# 下载模型到正确目录
cd ~/AIpic/models/Stable-diffusion
wget -O model_name.safetensors <model_url>

# 在Web UI中选择模型
# Settings -> Stable Diffusion -> Checkpoint
```

#### 使用LoRA模型
```bash
# 下载LoRA模型
cd ~/AIpic/models/Lora
wget -O lora_model.safetensors <lora_url>

# 在提示词中使用
# <lora:lora_model:1.0>
```

### 扩展插件

#### 安装扩展
```bash
# 通过Web UI安装
# Extensions -> Available -> Load from

# 或手动安装
cd ~/AIpic/extensions
git clone <extension_repo_url>
```

#### 常用扩展
1. **ControlNet**: 姿势控制
2. **ADetailer**: 面部修复
3. **Dynamic Prompts**: 动态提示词
4. **Tagger**: 图像标签
5. **Civitai Helper**: 模型管理

### API使用

启用API：
```bash
# 在webui-user.sh中添加
export API=True
export COMMANDLINE_ARGS="--api --listen"
```

API端点：
- `GET /sdapi/v1/sd-models` - 获取模型列表
- `POST /sdapi/v1/txt2img` - 文本生成图像
- `POST /sdapi/v1/img2img` - 图像生成图像
- `GET /sdapi/v1/progress` - 获取生成进度

示例调用：
```bash
curl -X POST http://localhost:7860/sdapi/v1/txt2img \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a beautiful landscape",
    "negative_prompt": "blurry, bad quality",
    "steps": 20,
    "width": 512,
    "height": 512
  }'
```

## 维护和更新

### 定期更新
```bash
# 更新代码
cd ~/AIpic
git pull

# 更新依赖
source venv/bin/activate
pip install --upgrade -r requirements.txt

# 更新PyTorch（如果需要）
pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# 重启服务
sudo systemctl restart aipic
```

### 备份配置
```bash
# 备份重要文件
tar -czf aipic_backup_$(date +%Y%m%d).tar.gz \
    ~/AIpic/config.json \
    ~/AIpic/webui-user.sh \
    ~/AIpic/models/ \
    ~/AIpic/embeddings/ \
    ~/AIpic/extensions/
```

### 清理缓存
```bash
# 清理Python缓存
find ~/AIpic -name "__pycache__" -type d -exec rm -rf {} +
find ~/AIpic -name "*.pyc" -delete

# 清理下载缓存
rm -rf ~/.cache/pip
rm -rf ~/.cache/torch
rm -rf ~/.cache/huggingface
```

## 安全建议

### 1. 防火墙配置
```bash
# 只允许本地访问
sudo ufw allow from 127.0.0.1 to any port 7860
sudo ufw allow from ::1 to any port 7860

# 或限制特定IP
sudo ufw allow from 192.168.1.0/24 to any port 7860
```

### 2. 使用反向代理（生产环境）
```nginx
# Nginx配置示例
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:7860;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 启用SSL
    listen 443 ssl;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
}
```

### 3. 定期更新
```bash
# 设置自动更新（每周）
(crontab -l 2>/dev/null; echo "0 2 * * 0 cd /home/$USER/AIpic && git pull && source venv/bin/activate && pip install -U -r requirements.txt") | crontab -
```

## 性能基准测试

### RTX 4070 16GB 预期性能

| 任务 | 分辨率 | 步数 | 批次大小 | 预计时间 | VRAM使用 |
|------|--------|------|----------|----------|----------|
| txt2img | 512x512 | 20 | 4 | 2-3秒 | 8-10GB |
| txt2img | 768x768 | 20 | 2 | 3-4秒 | 10-12GB |
| img2img | 512x512 | 20 | 2 | 3-4秒 | 9-11GB |
| 高分辨率修复 | 1024x1024 | 20 | 1 | 5-7秒 | 12-14GB |
| LoRA训练 | 512x512 | 1000 | 1 | 15-20分钟 | 14-16GB |

### 优化建议

1. **批量处理**: 使用合适的批次大小平衡速度和内存
2. **缓存模型**: 首次加载后模型会缓存，后续生成更快
3. **使用xformers**: 显著减少内存使用
4. **启用--medvram**: 优化16GB VRAM使用
5. **定期重启**: 清理内存碎片

## 支持与社区

### 官方资源
- **GitHub**: https://github.com/tailm/AIpic
- **文档**: https://github.com/tailm/AIpic/wiki
- **问题追踪**: https://github.com/tailm/AIpic/issues

### 社区支持
- **Discord**: [AIpic社区](https://discord.gg/aipic)
- **Reddit**: r/StableDiffusion
- **Hugging Face**: https://huggingface.co/spaces/stabilityai/stable-diffusion

### 获取帮助
1. 查看日志文件：`~/AIpic/log.txt`
2. 检查系统资源：`nvidia-smi`, `htop`
3. 搜索已知问题：GitHub Issues
4. 在社区提问（提供日志和配置）

## 许可证

AIpic基于MIT许可证发布。详见 [LICENSE](https://github.com/tailm/AIpic/blob/main/LICENSE) 文件。

## 更新日志

### 版本 1.0.0 (2024-01-01)
- 初始版本发布
- 支持Ubuntu 24.04
- 优化RTX 4070 16GB配置
- 完整的安装和部署指南

---

**注意**: 本指南针对Ubuntu 24.04和RTX 4070 16GB进行优化。其他系统或GPU可能需要调整配置参数。建议根据实际硬件性能进行测试和调优。
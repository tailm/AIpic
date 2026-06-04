# AIpic - Ubuntu 24.04 快速开始指南

## 5分钟快速安装

### 步骤1：下载安装脚本
```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/tailm/AIpic/main/install_ubuntu_24.sh

# 添加执行权限
chmod +x install_ubuntu_24.sh
```

### 步骤2：运行安装脚本
```bash
# 运行安装脚本（自动安装所有依赖）
./install_ubuntu_24.sh
```

### 步骤3：启动Web UI
```bash
# 进入项目目录
cd ~/AIpic

# 启动Web UI
./start_aipic.sh
```

### 步骤4：访问Web界面
打开浏览器访问：http://localhost:7860

## 一键安装命令（适用于全新系统）

```bash
# 一键安装命令
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tailm/AIpic/main/install_ubuntu_24.sh)"
```

## 常用命令

### 启动和停止
```bash
# 启动Web UI（智能启动，检查端口占用）
./start_aipic.sh

# 停止Web UI（安全停止，清理进程）
./stop_aipic.sh

# 重启Web UI
./stop_aipic.sh && ./start_aipic.sh
```

### 更新和维护
```bash
# 更新AIpic（更新代码和依赖）
./update_aipic.sh

# 清理缓存（安全模式）
./clean_cache.sh safe

# 性能优化
./optimize_performance.sh

# 测试安装
./test_installation.sh full
```

### 系统服务管理
```bash
# 启用开机自启
sudo systemctl enable aipic

# 启动服务
sudo systemctl start aipic

# 停止服务
sudo systemctl stop aipic

# 查看状态
sudo systemctl status aipic

# 查看日志
sudo journalctl -u aipic -f
```

### 更新和维护
```bash
# 更新代码和依赖
./update_aipic.sh

# 优化性能
./optimize_performance.sh

# 清理缓存
./clean_cache.sh
```

## 快速配置

### 基础配置（webui-user.sh）
```bash
# 复制默认配置
cp webui-user.example.sh webui-user.sh

# 编辑配置
nano webui-user.sh
```

### 推荐配置（RTX 4070 16GB）
```bash
# GPU优化设置
export COMMANDLINE_ARGS="--medvram --opt-sdp-attention --xformers --listen --port 7860"

# 性能优化
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"

# 启用API
export API=True

# 自动打开浏览器
export LAUNCH_BROWSER=True
```

## 下载模型

### 基础模型（必需）
```bash
# 进入模型目录
cd ~/AIpic/models/Stable-diffusion

# 下载Stable Diffusion 1.5
wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors

# 下载VAE模型
cd ../VAE
wget https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors
```

### 可选模型
```bash
# SDXL模型
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# Realistic Vision模型
wget https://huggingface.co/SG161222/Realistic_Vision_V6.0_B1_noVAE/resolve/main/Realistic_Vision_V6.0_B1_noVAE.safetensors
```

## 故障排除快速指南

### 问题1：CUDA内存不足
**解决方案**：
```bash
# 修改webui-user.sh
export COMMANDLINE_ARGS="--medvram --lowvram --opt-sdp-attention --xformers"
```

### 问题2：端口被占用
**解决方案**：
```bash
# 查找占用进程
sudo lsof -i :7860

# 终止进程
sudo kill -9 <PID>

# 或使用其他端口
export COMMANDLINE_ARGS="--port 7861"
```

### 问题3：模型加载失败
**解决方案**：
```bash
# 重新下载模型
cd ~/AIpic/models/Stable-diffusion
rm v1-5-pruned-emaonly.safetensors
wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors
```

### 问题4：Web UI无法启动
**解决方案**：
```bash
# 查看详细日志
cd ~/AIpic
python launch.py --listen 2>&1 | tee debug.log

# 检查Python版本
python --version

# 检查虚拟环境
source venv/bin/activate
pip list | grep torch
```

## 性能优化提示

### 针对RTX 4070 16GB
1. **使用--medvram参数**：优化16GB VRAM使用
2. **启用xformers**：减少内存占用
3. **调整批次大小**：
   - txt2img: 2-4张/批次
   - img2img: 1-2张/批次
4. **分辨率建议**：
   - 基础: 512x512 或 768x768
   - 高分辨率修复: 最高1024x1024

### 系统优化
```bash
# 运行性能优化脚本
./optimize_performance.sh

# 监控GPU使用
watch -n 1 nvidia-smi
```

## 扩展安装

### 常用扩展
```bash
# 通过Web UI安装
# 1. 打开 http://localhost:7860
# 2. 点击 "Extensions" 标签
# 3. 点击 "Available" 标签
# 4. 点击 "Load from"
# 5. 搜索并安装扩展
```

### 推荐扩展
1. **ControlNet** - 姿势控制
2. **ADetailer** - 面部修复
3. **Dynamic Prompts** - 动态提示词
4. **Tagger** - 图像标签
5. **Civitai Helper** - 模型管理

## API使用示例

### 启用API
```bash
# 在webui-user.sh中添加
export API=True
```

### 生成图像
```bash
curl -X POST http://localhost:7860/sdapi/v1/txt2img \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a beautiful landscape, masterpiece, best quality",
    "negative_prompt": "blurry, bad quality, deformed",
    "steps": 20,
    "width": 512,
    "height": 512,
    "cfg_scale": 7,
    "sampler_name": "Euler a"
  }'
```

## 下一步

1. **探索Web UI**：尝试不同的模型和参数
2. **安装扩展**：增强功能
3. **下载更多模型**：从Civitai或HuggingFace
4. **学习提示词工程**：创造更好的图像
5. **加入社区**：获取帮助和分享作品

## 获取帮助

- **GitHub Issues**: https://github.com/tailm/AIpic/issues
- **文档**: 查看 `UBUNTU_DEPLOYMENT_GUIDE.md` 获取详细指南
- **日志文件**: `~/AIpic/log.txt`

---

**提示**: 首次启动可能需要几分钟加载模型。请耐心等待，不要关闭终端。
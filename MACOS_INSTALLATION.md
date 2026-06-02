# Stable Diffusion Web UI macOS 安装部署指南

本文档提供了在 macOS（包括 Apple Silicon M1/M2/M3）上安装和运行 Stable Diffusion Web UI 的完整指南。

## 系统要求

- macOS 10.15 (Catalina) 或更高版本
- Python 3.10.9（推荐）
- 至少 8GB RAM（推荐 16GB+）
- 至少 10GB 可用磁盘空间
- 稳定的网络连接

## 安装步骤

### 1. 安装 Homebrew（如果尚未安装）

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. 安装 Python 3.10

```bash
brew install python@3.10
```

### 3. 克隆项目

```bash
git clone https://github.com/tailm/AIpic.git
cd AIpic
```

### 4. 创建并激活虚拟环境

```bash
python3.10 -m venv venv
source venv/bin/activate
```

### 5. 安装依赖包

由于 macOS ARM 架构的特殊性，需要安装特定版本的依赖包：

#### 方法一：使用修复后的 requirements.txt

```bash
# 安装基础依赖
pip install --upgrade pip
pip install -r requirements.txt
```

#### 方法二：手动安装（如果遇到问题）

```bash
# 1. 安装 PyTorch（macOS ARM 版本）
pip install torch==1.13.1 torchvision==0.14.1

# 2. 安装其他核心依赖
pip install gradio==3.16.2
pip install transformers==4.25.1
pip install accelerate==0.12.0
pip install numpy==1.23.3
pip install Pillow==9.4.0
pip install opencv-python==4.8.1.78
pip install scikit-image>=0.19,<0.20

# 3. 安装修复版本的包
pip install basicsr==1.3.1 --no-deps
pip install facexlib==0.3.0
pip install realesrgan==0.2.9 --no-deps

# 4. 安装其他依赖
pip install torchmetrics<1.0.0
pip install timm==0.6.7
pip install pytorch_lightning==1.7.6
pip install safetensors==0.2.7
pip install omegaconf==2.2.3
pip install kornia==0.6.7
pip install torchdiffeq==0.2.3
pip install torchsde==0.2.5
pip install einops==0.4.1
pip install httpx==0.24.1
pip install httpcore==0.15.0
pip install fastapi==0.94.0
```

### 6. 应用补丁修复

由于 `basicsr==1.3.1` 缺少 `load_file_from_url` 函数，需要手动添加：

```python
# 创建修复脚本 fix_basicsr.py
cat > fix_basicsr.py << 'EOF'
import sys
import os

# 添加 load_file_from_url 函数到 basicsr
import basicsr.utils.download_util as download_util

if not hasattr(download_util, 'load_file_from_url'):
    import requests
    import hashlib
    from tqdm import tqdm
    import os
    
    def load_file_from_url(url, model_dir, progress=True, file_name=None):
        """Download a file from url into model_dir."""
        os.makedirs(model_dir, exist_ok=True)
        
        if file_name is None:
            file_name = os.path.basename(url)
            file_name = file_name.split('?')[0]
            if not file_name or '.' not in file_name:
                file_name = hashlib.md5(url.encode()).hexdigest() + '.pth'
        
        file_path = os.path.join(model_dir, file_name)
        
        if os.path.exists(file_path):
            return file_path
        
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        
        with open(file_path, 'wb') as f:
            if progress and total_size > 0:
                with tqdm(total=total_size, unit='B', unit_scale=True, desc=file_name) as pbar:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            pbar.update(len(chunk))
            else:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
        
        return file_path
    
    download_util.load_file_from_url = load_file_from_url
    print("Successfully added load_file_from_url to basicsr.utils.download_util")

EOF

# 运行修复脚本
python fix_basicsr.py
```

### 7. 配置 webui-user.sh

编辑 `webui-user.sh` 文件，确保包含以下配置：

```bash
#!/bin/bash

# Python 可执行文件路径
python_cmd="/Users/zwj/AIpic/venv/bin/python"

# 命令行参数（重要：跳过 CUDA 测试）
export COMMANDLINE_ARGS="--skip-torch-cuda-test --port 7860"

# 跳过 GFPGAN 安装（macOS ARM 不兼容）
export GFPGAN_PACKAGE=""
```

### 8. 下载模型文件

将 Stable Diffusion 模型文件放入 `models/Stable-diffusion/` 目录：

```bash
mkdir -p models/Stable-diffusion
# 下载 v1-5-pruned-emaonly.safetensors 或其他模型文件
# 可以从 Hugging Face 或 Civitai 下载
```

### 9. 启动 Web UI

```bash
./webui.sh
```

或者直接运行：

```bash
source venv/bin/activate
python launch.py --skip-torch-cuda-test --port 7860
```

### 10. 访问 Web UI

在浏览器中打开：http://127.0.0.1:7860

## 常见问题解决

### 1. "Torch not compiled with CUDA enabled" 错误

**解决方案**：在 `webui-user.sh` 中添加 `--skip-torch-cuda-test` 参数。

### 2. basicsr 缺少 load_file_from_url 函数

**解决方案**：按照步骤 6 应用补丁修复。

### 3. GFPGAN 安装失败（tb-nightly 依赖）

**解决方案**：跳过 GFPGAN 安装，在 `webui-user.sh` 中设置 `export GFPGAN_PACKAGE=""`。

### 4. realesrgan 与 basicsr 版本冲突

**解决方案**：使用 `realesrgan==0.2.9` 和 `basicsr==1.3.1`。

### 5. numpy 版本冲突

**解决方案**：确保使用 `numpy==1.23.3` 和 `opencv-python==4.8.1.78`。

### 6. httpx 与 httpcore 版本不兼容

**解决方案**：使用 `httpx==0.24.1` 和 `httpcore==0.15.0`。

## 性能优化建议

### 1. 使用 CPU 模式（如果没有 GPU 或 GPU 内存不足）

在 `webui-user.sh` 中添加：
```bash
export COMMANDLINE_ARGS="--skip-torch-cuda-test --use-cpu all --no-half"
```

### 2. 减少内存使用

```bash
export COMMANDLINE_ARGS="--skip-torch-cuda-test --medvram --opt-split-attention"
```

### 3. 使用 xformers（仅限 Intel Mac）

```bash
pip install xformers
```

## 文件结构说明

```
AIpic/
├── models/                    # 模型文件目录
│   ├── Stable-diffusion/     # Stable Diffusion 模型
│   ├── GFPGAN/              # GFPGAN 模型（可选）
│   └── RealESRGAN/          # RealESRGAN 模型（可选）
├── outputs/                  # 生成图片输出目录
├── venv/                    # Python 虚拟环境
├── webui.sh                # 启动脚本
├── webui-user.sh           # 用户配置
├── requirements.txt        # 依赖包列表（已修复版本）
├── requirements_macos.txt  # macOS 专用依赖列表
└── MACOS_INSTALLATION.md   # 本安装指南
```

## 更新和升级

### 更新代码

```bash
git pull
```

### 更新依赖

```bash
source venv/bin/activate
pip install --upgrade -r requirements.txt
```

### 重新应用补丁

如果更新后出现问题，重新运行修复脚本：
```bash
python fix_basicsr.py
```

## 故障排除

### Web UI 无法启动

1. 检查端口是否被占用：
   ```bash
   lsof -ti:7860
   ```

2. 更改端口号：
   ```bash
   export COMMANDLINE_ARGS="--skip-torch-cuda-test --port 7862"
   ```

### 导入错误

1. 检查虚拟环境是否激活：
   ```bash
   which python
   # 应该显示 /path/to/AIpic/venv/bin/python
   ```

2. 重新安装依赖：
   ```bash
   pip install --force-reinstall -r requirements.txt
   ```

### 内存不足

1. 使用低内存模式：
   ```bash
   export COMMANDLINE_ARGS="--skip-torch-cuda-test --lowvram"
   ```

2. 减少图片尺寸：
   - 在 Web UI 设置中降低生成图片的分辨率

## 支持与反馈

如果遇到问题，请：

1. 检查日志文件：`webui.log`
2. 查看控制台输出
3. 确保所有步骤都按照本指南执行
4. 在项目 Issues 页面报告问题

## 许可证

本项目基于 Stable Diffusion Web UI，遵循其原始许可证。

## 更新日志

### 2024-01-01
- 初始版本
- 修复了 macOS ARM 上的依赖兼容性问题
- 添加了详细的安装指南

---

**注意**：由于 macOS ARM 架构的特殊性，某些功能（如 GFPGAN、最新版 RealESRGAN）可能无法使用。本指南提供了可行的替代方案和变通方法。
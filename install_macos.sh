#!/bin/bash
# Stable Diffusion Web UI macOS 安装脚本
# 适用于 macOS（包括 Apple Silicon）

set -e  # 遇到错误时退出

echo "========================================="
echo "Stable Diffusion Web UI macOS 安装脚本"
echo "========================================="

# 检查是否在项目目录中
if [ ! -f "webui.sh" ]; then
    echo "错误：请在项目根目录中运行此脚本"
    exit 1
fi

# 检查 Homebrew
if ! command -v brew &> /dev/null; then
    echo "未找到 Homebrew，正在安装..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    source ~/.zshrc
fi

# 检查 Python 3.10
if ! command -v python3.10 &> /dev/null; then
    echo "正在安装 Python 3.10..."
    brew install python@3.10
fi

# 创建虚拟环境
echo "创建虚拟环境..."
python3.10 -m venv venv

# 激活虚拟环境
echo "激活虚拟环境..."
source venv/bin/activate

# 升级 pip
echo "升级 pip..."
pip install --upgrade pip

# 安装依赖
echo "安装依赖包..."
echo "注意：这可能需要一些时间..."

# 安装 PyTorch（macOS ARM 版本）
echo "安装 PyTorch..."
pip install torch==1.13.1 torchvision==0.14.1

# 安装其他核心依赖
echo "安装核心依赖..."
pip install gradio==3.16.2
pip install transformers==4.25.1
pip install accelerate==0.12.0
pip install numpy==1.23.3
pip install Pillow==9.4.0
pip install opencv-python==4.8.1.78
pip install "scikit-image>=0.19,<0.20"

# 安装修复版本的包
echo "安装修复版本的包..."
pip install basicsr==1.3.1 --no-deps
pip install facexlib==0.3.0
pip install realesrgan==0.2.9 --no-deps

# 安装其他依赖
echo "安装其他依赖..."
pip install torchmetrics\<1.0.0
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

# 安装 requirements.txt 中的其他包
echo "安装 requirements.txt 中的其他包..."
pip install blendmodes==2022
pip install fonts
pip install font-roboto
pip install invisible-watermark
pip install requests==2.25.1
pip install GitPython==3.1.30
pip install piexif==1.1.3
pip install jsonmerge==1.8.0
pip install lark==1.1.2
pip install inflection==0.5.1
pip install clean-fid==0.1.29
pip install resize-right==0.0.2
pip install psutil

# 应用补丁修复
echo "应用补丁修复..."
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

python fix_basicsr.py
rm fix_basicsr.py

# 配置 webui-user.sh
echo "配置 webui-user.sh..."
if [ ! -f "webui-user.sh" ]; then
    cp webui-user.sh.example webui-user.sh 2>/dev/null || true
fi

# 确保 webui-user.sh 包含正确的配置
cat > webui-user.sh << 'EOF'
#!/bin/bash
#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

# Install directory without trailing slash
#install_dir="/home/$(whoami)"

# Name of the subdirectory
clone_dir="AIpic"

# Commandline arguments for webui.py
export COMMANDLINE_ARGS="--skip-torch-cuda-test --port 7860"

# python3 executable
python_cmd="/Users/zwj/AIpic/venv/bin/python"

# git executable
#export GIT="git"

# python3 venv without trailing slash (defaults to ${install_dir}/${clone_dir}/venv)
#venv_dir="venv"

# script to launch to start the app
#export LAUNCH_SCRIPT="launch.py"

# install command for torch
#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https://download.pytorch.org/whl/cu113"

# Requirements file to use for stable-diffusion-webui
#export REQS_FILE="requirements_versions.txt"

# Skip GFPGAN installation
export GFPGAN_PACKAGE=""

# Fixed git repos
#export K_DIFFUSION_PACKAGE=""
#export GFPGAN_PACKAGE="gfpgan==1.3.8"

# Fixed git commits
#export STABLE_DIFFUSION_COMMIT_HASH=""
#export TAMING_TRANSFORMERS_COMMIT_HASH=""
#export CODEFORMER_COMMIT_HASH=""
#export BLIP_COMMIT_HASH=""

# Uncomment to enable accelerated launch
#export ACCELERATE="True"

###########################################
EOF

echo "替换 Python 路径..."
sed -i '' "s|/Users/zwj/AIpic/venv/bin/python|$(pwd)/venv/bin/python|g" webui-user.sh

# 创建模型目录
echo "创建模型目录..."
mkdir -p models/Stable-diffusion

echo "========================================="
echo "安装完成！"
echo "========================================="
echo ""
echo "下一步："
echo "1. 将 Stable Diffusion 模型文件放入 models/Stable-diffusion/ 目录"
echo "2. 运行启动命令：./webui.sh"
echo "3. 在浏览器中打开：http://127.0.0.1:7860"
echo ""
echo "如果需要更改端口，请编辑 webui-user.sh 中的 --port 参数"
echo "========================================="
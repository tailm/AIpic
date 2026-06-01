#!/usr/bin/env python3
import os
import sys

# 添加路径以便导入模块
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'repositories/CodeFormer'))

from basicsr.utils.download_util import load_file_from_url

def main():
    # Stable Diffusion 2.1 模型URL
    model_url = "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt"
    
    # 保存路径
    model_dir = "models/Stable-diffusion"
    
    print(f"开始下载 Stable Diffusion 2.1 模型...")
    print(f"URL: {model_url}")
    print(f"保存到: {model_dir}")
    
    try:
        # 使用现有的下载函数
        downloaded_file = load_file_from_url(
            url=model_url,
            model_dir=model_dir,
            progress=True,
            file_name="v2-1_768-ema-pruned.ckpt"
        )
        
        print(f"✅ 下载完成: {downloaded_file}")
        
        # 检查文件大小
        file_size = os.path.getsize(downloaded_file)
        print(f"文件大小: {file_size / 1024 / 1024 / 1024:.2f} GB")
        
        return 0
        
    except Exception as e:
        print(f"❌ 下载失败: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
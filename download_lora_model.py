#!/usr/bin/env python3
import os
import sys
import requests
import time
from tqdm import tqdm

def download_file_with_progress(url, save_path):
    """下载文件并显示进度条"""
    print(f"开始下载: {url}")
    print(f"保存到: {save_path}")
    
    # 创建目录
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    
    # 设置请求头
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        # 尝试获取文件大小
        response = requests.head(url, headers=headers, allow_redirects=True, timeout=30)
        if response.status_code != 200:
            print(f"无法访问文件: HTTP {response.status_code}")
            return False
        
        total_size = int(response.headers.get('content-length', 0))
        
        # 开始下载
        response = requests.get(url, headers=headers, stream=True, timeout=60)
        response.raise_for_status()
        
        with open(save_path, 'wb') as f:
            if total_size == 0:
                # 不知道文件大小，直接写入
                f.write(response.content)
                print("下载完成")
            else:
                # 使用进度条
                chunk_size = 8192
                with tqdm(total=total_size, unit='B', unit_scale=True, desc=os.path.basename(save_path)) as pbar:
                    for chunk in response.iter_content(chunk_size=chunk_size):
                        if chunk:
                            f.write(chunk)
                            pbar.update(len(chunk))
        
        # 验证文件大小
        downloaded_size = os.path.getsize(save_path)
        print(f"下载完成: {save_path}")
        print(f"文件大小: {downloaded_size / 1024 / 1024:.2f} MB")
        
        if total_size > 0 and downloaded_size != total_size:
            print(f"警告: 文件大小不匹配 ({downloaded_size} != {total_size})")
            return False
        
        return True
        
    except Exception as e:
        print(f"下载失败: {e}")
        return False

def main():
    # LoRA 模型文件 URL
    model_url = "https://huggingface.co/tensorart/stable-diffusion-3.5-medium-turbo/resolve/main/lora_sd3.5m_4steps.safetensors"
    
    # 保存路径 - LoRA 模型应该放在 models/Lora 目录
    save_dir = "models/Lora"
    os.makedirs(save_dir, exist_ok=True)
    save_path = os.path.join(save_dir, "lora_sd3.5m_4steps.safetensors")
    
    print("=" * 60)
    print("下载 Stable Diffusion 3.5 Medium Turbo LoRA 模型")
    print("=" * 60)
    
    # 检查文件是否已存在
    if os.path.exists(save_path):
        file_size = os.path.getsize(save_path)
        if file_size > 1000000:  # 大于1MB
            print(f"模型文件已存在: {save_path}")
            print(f"文件大小: {file_size / 1024 / 1024:.2f} MB")
            print("如需重新下载，请先删除现有文件")
            return 0
    
    # 尝试下载
    print(f"模型URL: {model_url}")
    print(f"保存目录: {save_dir}")
    print(f"文件名: lora_sd3.5m_4steps.safetensors")
    print("-" * 60)
    
    # 尝试多次下载
    max_retries = 3
    for attempt in range(max_retries):
        print(f"\n尝试下载 (第 {attempt + 1}/{max_retries} 次)...")
        
        if download_file_with_progress(model_url, save_path):
            print("✅ 下载成功！")
            
            # 验证文件
            if os.path.exists(save_path):
                file_size = os.path.getsize(save_path)
                print(f"✅ 文件验证通过")
                print(f"✅ 文件大小: {file_size / 1024 / 1024:.2f} MB")
                print(f"✅ 保存位置: {save_path}")
                return 0
            else:
                print("❌ 文件下载后不存在")
        
        if attempt < max_retries - 1:
            print(f"等待 5 秒后重试...")
            time.sleep(5)
    
    print("\n❌ 所有下载尝试都失败了")
    print("\n手动下载步骤:")
    print("1. 访问: https://huggingface.co/tensorart/stable-diffusion-3.5-medium-turbo")
    print("2. 找到并下载文件: lora_sd3.5m_4steps.safetensors")
    print(f"3. 将文件保存到: {save_dir}/")
    print("4. 重启 AIpic 服务")
    
    return 1

if __name__ == "__main__":
    sys.exit(main())
#!/usr/bin/env python3
import os
import sys
import requests
import time

def download_with_progress(url, filename):
    """带进度条的下载函数"""
    try:
        # 尝试获取文件大小
        response = requests.head(url, allow_redirects=True, timeout=10)
        if response.status_code != 200:
            print(f"无法访问 URL: {url} (状态码: {response.status_code})")
            return False
            
        total_size = int(response.headers.get('content-length', 0))
        
        # 开始下载
        print(f"开始下载: {url}")
        print(f"文件大小: {total_size / 1024 / 1024 / 1024:.2f} GB" if total_size > 0 else "文件大小: 未知")
        
        response = requests.get(url, stream=True, timeout=30)
        response.raise_for_status()
        
        with open(filename, 'wb') as f:
            downloaded = 0
            chunk_size = 8192
            start_time = time.time()
            
            for chunk in response.iter_content(chunk_size=chunk_size):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    
                    # 显示进度
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        if downloaded % (50 * 1024 * 1024) < chunk_size:  # 每50MB显示一次
                            elapsed = time.time() - start_time
                            speed = downloaded / elapsed / (1024 * 1024) if elapsed > 0 else 0
                            print(f"进度: {percent:.1f}% ({downloaded/(1024*1024*1024):.2f} GB / {total_size/(1024*1024*1024):.2f} GB) - 速度: {speed:.1f} MB/s")
        
        print(f"下载完成: {filename}")
        return True
        
    except Exception as e:
        print(f"下载失败: {e}")
        return False

def main():
    # 尝试多个可能的镜像源
    mirrors = [
        # 官方源（可能需要身份验证）
        "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt",
        
        # 其他可能的源
        "https://cloudflare-ipfs.com/ipfs/QmS6f8dr8Y6qX8q8q8q8q8q8q8q8q8q8q8q8q8q8q8q8q8/v2-1_768-ema-pruned.ckpt",
        
        # 尝试从其他镜像站下载
        "https://mirror.ghproxy.com/https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt",
        
        # 尝试使用代理
        "https://hf-mirror.com/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt",
    ]
    
    save_path = "models/Stable-diffusion/v2-1_768-ema-pruned.ckpt"
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    
    # 检查文件是否已存在
    if os.path.exists(save_path):
        file_size = os.path.getsize(save_path)
        if file_size > 5000000000:  # 大于5GB
            print(f"模型文件已存在: {save_path} ({file_size/1024/1024/1024:.2f} GB)")
            return 0
    
    print("尝试从多个镜像源下载 Stable Diffusion 2.1 模型...")
    
    for i, url in enumerate(mirrors, 1):
        print(f"\n尝试镜像源 {i}: {url}")
        
        # 添加超时和重试
        for retry in range(3):
            try:
                if download_with_progress(url, save_path):
                    # 验证文件大小
                    file_size = os.path.getsize(save_path)
                    if file_size > 1000000000:  # 大于1GB
                        print(f"✅ 下载成功！文件大小: {file_size/1024/1024/1024:.2f} GB")
                        return 0
                    else:
                        print(f"❌ 文件大小异常: {file_size} 字节")
                        os.remove(save_path)
                        break
                else:
                    print(f"❌ 下载失败，重试 {retry + 1}/3...")
                    time.sleep(2)
            except Exception as e:
                print(f"❌ 异常: {e}")
                time.sleep(2)
    
    print("\n所有镜像源都失败了。")
    print("建议手动下载模型:")
    print("1. 访问: https://huggingface.co/stabilityai/stable-diffusion-2-1")
    print("2. 下载文件: v2-1_768-ema-pruned.ckpt")
    print("3. 将文件保存到: models/Stable-diffusion/ 目录")
    print("4. 重启 AIpic")
    
    return 1

if __name__ == "__main__":
    sys.exit(main())
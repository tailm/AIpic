#!/usr/bin/env python3
import os
import requests
import sys
from tqdm import tqdm

def download_file(url, filename):
    """
    下载文件并显示进度条
    """
    # 检查文件是否已存在
    if os.path.exists(filename):
        file_size = os.path.getsize(filename)
        # 如果文件已存在且大小合理，跳过下载
        if file_size > 5000000000:  # 大于5GB
            print(f"文件已存在: {filename} ({file_size/1024/1024/1024:.2f} GB)")
            return True
    
    print(f"开始下载: {url}")
    print(f"保存到: {filename}")
    
    # 设置请求头
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    try:
        # 发送HEAD请求获取文件大小
        response = requests.head(url, headers=headers, allow_redirects=True)
        total_size = int(response.headers.get('content-length', 0))
        
        if total_size == 0:
            print("无法获取文件大小，开始下载...")
        
        # 下载文件
        response = requests.get(url, headers=headers, stream=True, allow_redirects=True)
        response.raise_for_status()
        
        # 创建目录（如果不存在）
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        
        # 下载并显示进度
        with open(filename, 'wb') as f:
            if total_size == 0:
                # 不知道文件大小，直接写入
                f.write(response.content)
                print("下载完成")
            else:
                # 使用进度条
                chunk_size = 8192
                with tqdm(total=total_size, unit='B', unit_scale=True, desc=os.path.basename(filename)) as pbar:
                    for chunk in response.iter_content(chunk_size=chunk_size):
                        if chunk:
                            f.write(chunk)
                            pbar.update(len(chunk))
        
        # 验证文件大小
        downloaded_size = os.path.getsize(filename)
        if total_size > 0 and downloaded_size != total_size:
            print(f"警告: 下载的文件大小不匹配 ({downloaded_size} != {total_size})")
            return False
        
        print(f"下载完成: {filename} ({downloaded_size/1024/1024/1024:.2f} GB)")
        return True
        
    except Exception as e:
        print(f"下载失败: {e}")
        return False

def main():
    # Stable Diffusion 2.1 模型URL
    model_url = "https://huggingface.co/sd2-community/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt"
    
    # 保存路径
    save_path = "models/Stable-diffusion/v2-1_768-ema-pruned.ckpt"
    
    # 下载模型
    success = download_file(model_url, save_path)
    
    if success:
        print("✅ Stable Diffusion 2.1 模型下载完成！")
        return 0
    else:
        print("❌ 下载失败")
        return 1

if __name__ == "__main__":
    sys.exit(main())
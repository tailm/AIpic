#!/usr/bin/env python3
import os
import sys
import requests
import time

def download_file(url, filename):
    """
    下载大文件的简单函数
    """
    # 检查文件是否已存在
    if os.path.exists(filename):
        file_size = os.path.getsize(filename)
        if file_size > 5000000000:  # 大于5GB
            print(f"文件已存在: {filename} ({file_size/1024/1024/1024:.2f} GB)")
            return True
    
    print(f"开始下载: {url}")
    print(f"保存到: {filename}")
    
    # 创建目录
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    # 设置请求头
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        # 尝试使用 requests 下载
        response = requests.get(url, headers=headers, stream=True, timeout=30)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        
        # 下载文件
        with open(filename, 'wb') as f:
            if total_size == 0:
                # 不知道文件大小，直接写入
                f.write(response.content)
                print("下载完成")
            else:
                # 显示进度
                downloaded = 0
                chunk_size = 8192
                start_time = time.time()
                
                for chunk in response.iter_content(chunk_size=chunk_size):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        
                        # 每下载 50MB 显示一次进度
                        if downloaded % (50 * 1024 * 1024) < chunk_size:
                            elapsed = time.time() - start_time
                            mb_downloaded = downloaded / (1024 * 1024)
                            speed = mb_downloaded / elapsed if elapsed > 0 else 0
                            percent = (downloaded / total_size) * 100
                            print(f"进度: {percent:.1f}% ({mb_downloaded:.1f} MB / {total_size/(1024*1024):.1f} MB) - 速度: {speed:.1f} MB/s")
        
        # 验证文件大小
        downloaded_size = os.path.getsize(filename)
        print(f"下载完成: {filename} ({downloaded_size/1024/1024/1024:.2f} GB)")
        
        if total_size > 0 and downloaded_size != total_size:
            print(f"警告: 下载的文件大小不匹配 ({downloaded_size} != {total_size})")
            return False
        
        return True
        
    except Exception as e:
        print(f"下载失败: {e}")
        return False

def main():
    # 尝试多个可能的下载链接
    urls = [
        "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt",
        "https://huggingface.co/stabilityai/stable-diffusion-2-1/blob/main/v2-1_768-ema-pruned.ckpt",
    ]
    
    save_path = "models/Stable-diffusion/v2-1_768-ema-pruned.ckpt"
    
    for url in urls:
        print(f"\n尝试下载链接: {url}")
        if download_file(url, save_path):
            print("✅ 下载成功！")
            return 0
        else:
            print("❌ 下载失败，尝试下一个链接...")
            time.sleep(2)
    
    print("所有下载链接都失败了")
    return 1

if __name__ == "__main__":
    sys.exit(main())
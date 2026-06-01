#!/usr/bin/env python3
import os
import sys
from huggingface_hub import hf_hub_download, snapshot_download

def main():
    # 模型信息
    repo_id = "stabilityai/stable-diffusion-2-1"
    filename = "v2-1_768-ema-pruned.ckpt"
    
    # 保存路径
    save_dir = "models/Stable-diffusion"
    os.makedirs(save_dir, exist_ok=True)
    save_path = os.path.join(save_dir, filename)
    
    print(f"开始下载 Stable Diffusion 2.1 模型...")
    print(f"仓库: {repo_id}")
    print(f"文件: {filename}")
    print(f"保存到: {save_path}")
    
    try:
        # 使用 huggingface_hub 下载单个文件
        print("正在下载模型文件...")
        downloaded_file = hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            local_dir=save_dir,
            local_dir_use_symlinks=False,
            resume_download=True
        )
        
        print(f"✅ 下载完成: {downloaded_file}")
        
        # 检查文件大小
        file_size = os.path.getsize(downloaded_file)
        print(f"文件大小: {file_size / 1024 / 1024 / 1024:.2f} GB")
        
        return 0
        
    except Exception as e:
        print(f"❌ 下载失败: {e}")
        print("尝试使用备用方法...")
        
        try:
            # 尝试下载整个仓库的快照
            print("尝试下载整个仓库...")
            snapshot_path = snapshot_download(
                repo_id=repo_id,
                local_dir=save_dir,
                local_dir_use_symlinks=False,
                allow_patterns=[filename],
                resume_download=True
            )
            
            # 查找下载的文件
            for root, dirs, files in os.walk(snapshot_path):
                for file in files:
                    if file == filename:
                        downloaded_file = os.path.join(root, file)
                        print(f"✅ 下载完成: {downloaded_file}")
                        
                        # 移动文件到目标位置
                        if downloaded_file != save_path:
                            os.rename(downloaded_file, save_path)
                            print(f"文件已移动到: {save_path}")
                        
                        file_size = os.path.getsize(save_path)
                        print(f"文件大小: {file_size / 1024 / 1024 / 1024:.2f} GB")
                        return 0
            
            print("❌ 未找到模型文件")
            return 1
            
        except Exception as e2:
            print(f"❌ 备用方法也失败: {e2}")
            return 1

if __name__ == "__main__":
    sys.exit(main())
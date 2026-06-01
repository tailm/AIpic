#!/usr/bin/env python3
import os
import sys

# 添加路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# 导入 webui 模块
import modules.modelloader as modelloader

def main():
    # 模型 URL
    model_url = "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt"
    
    # 模型目录
    model_path = os.path.join("models", "Stable-diffusion")
    
    print(f"开始下载 Stable Diffusion 2.1 模型...")
    print(f"URL: {model_url}")
    print(f"保存到: {model_path}")
    
    try:
        # 使用 webui 的下载功能
        downloaded_file = modelloader.load_file_from_url(
            url=model_url,
            model_dir=model_path,
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
        
        # 尝试从其他源下载
        print("尝试从其他源下载...")
        
        # 尝试从 Civitai 下载
        civitai_url = "https://civitai.com/api/download/models/4201"
        try:
            print(f"尝试从 Civitai 下载: {civitai_url}")
            downloaded_file = modelloader.load_file_from_url(
                url=civitai_url,
                model_dir=model_path,
                progress=True,
                file_name="v2-1_768-ema-pruned.ckpt"
            )
            
            print(f"✅ 从 Civitai 下载完成: {downloaded_file}")
            file_size = os.path.getsize(downloaded_file)
            print(f"文件大小: {file_size / 1024 / 1024 / 1024:.2f} GB")
            return 0
            
        except Exception as e2:
            print(f"❌ Civitai 下载也失败: {e2}")
            
            # 尝试从其他镜像源下载
            mirror_urls = [
                "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt?download=true",
                "https://huggingface.co/stabilityai/stable-diffusion-2-1/blob/main/v2-1_768-ema-pruned.ckpt?download=true",
            ]
            
            for i, url in enumerate(mirror_urls, 1):
                print(f"\n尝试镜像源 {i}: {url}")
                try:
                    downloaded_file = modelloader.load_file_from_url(
                        url=url,
                        model_dir=model_path,
                        progress=True,
                        file_name=f"v2-1_768-ema-pruned_mirror{i}.ckpt"
                    )
                    
                    # 重命名为标准名称
                    final_path = os.path.join(model_path, "v2-1_768-ema-pruned.ckpt")
                    if downloaded_file != final_path:
                        os.rename(downloaded_file, final_path)
                    
                    print(f"✅ 从镜像源下载完成: {final_path}")
                    file_size = os.path.getsize(final_path)
                    print(f"文件大小: {file_size / 1024 / 1024 / 1024:.2f} GB")
                    return 0
                    
                except Exception as e3:
                    print(f"❌ 镜像源 {i} 失败: {e3}")
            
            print("所有下载源都失败了")
            return 1

if __name__ == "__main__":
    sys.exit(main())
#!/usr/bin/env python3
import os
import sys
import json

def check_lora_models():
    """检查 LoRA 模型是否被正确加载"""
    
    print("=" * 60)
    print("检查 Stable Diffusion WebUI LoRA 模型加载状态")
    print("=" * 60)
    
    # 1. 检查模型文件是否存在
    lora_path = "models/Lora/lora_sd3.5m_4steps.safetensors"
    if os.path.exists(lora_path):
        file_size = os.path.getsize(lora_path)
        print(f"✅ LoRA 模型文件存在: {lora_path}")
        print(f"   文件大小: {file_size / 1024 / 1024:.2f} MB")
    else:
        print(f"❌ LoRA 模型文件不存在: {lora_path}")
        return False
    
    # 2. 检查扩展目录
    lora_ext_path = "extensions-builtin/Lora"
    if os.path.exists(lora_ext_path):
        print(f"✅ LoRA 扩展目录存在: {lora_ext_path}")
        
        # 检查扩展文件
        ext_files = os.listdir(lora_ext_path)
        print(f"   扩展文件数量: {len(ext_files)}")
        
        # 检查关键文件
        key_files = ["lora.py", "ui_extra_networks_lora.py", "extra_networks_lora.py"]
        for file in key_files:
            if os.path.exists(os.path.join(lora_ext_path, file)):
                print(f"   ✅ {file} 存在")
            else:
                print(f"   ⚠️  {file} 不存在")
    else:
        print(f"❌ LoRA 扩展目录不存在: {lora_ext_path}")
        return False
    
    # 3. 检查配置文件
    config_path = "config.json"
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
            
            # 检查 LoRA 相关配置
            lora_enabled = config.get('additional_networks_extra_lora', True)
            print(f"✅ 配置文件存在")
            print(f"   LoRA 扩展启用状态: {'已启用' if lora_enabled else '未启用'}")
        except:
            print(f"⚠️  配置文件存在但无法读取")
    else:
        print(f"⚠️  配置文件不存在，将使用默认设置")
    
    # 4. 检查模型目录结构
    models_dir = "models"
    if os.path.exists(models_dir):
        subdirs = [d for d in os.listdir(models_dir) if os.path.isdir(os.path.join(models_dir, d))]
        print(f"\n📁 模型目录结构:")
        for subdir in sorted(subdirs):
            subdir_path = os.path.join(models_dir, subdir)
            files = [f for f in os.listdir(subdir_path) if os.path.isfile(os.path.join(subdir_path, f))]
            model_files = [f for f in files if f.endswith(('.ckpt', '.safetensors', '.pt', '.pth'))]
            print(f"   {subdir}/: {len(model_files)} 个模型文件")
    
    # 5. 使用说明
    print("\n" + "=" * 60)
    print("使用说明:")
    print("=" * 60)
    print("1. 访问: http://localhost:7860")
    print("2. 在 txt2img 或 img2img 页面")
    print("3. 点击 'Show/hide extra networks' 按钮（通常是一个小箭头或加号）")
    print("4. 选择 'Lora' 标签页")
    print("5. 找到 'lora_sd3.5m_4steps' 模型")
    print("6. 点击模型名称将其添加到提示词中")
    print("7. 调整权重（建议从 0.5-1.0 开始尝试）")
    print("\n注意: LoRA 模型需要与基础模型配合使用")
    print("当前基础模型: v1-5-pruned-emaonly.safetensors")
    
    return True

def main():
    try:
        success = check_lora_models()
        if success:
            print("\n✅ 检查完成 - LoRA 模型已准备就绪")
            return 0
        else:
            print("\n❌ 检查发现问题")
            return 1
    except Exception as e:
        print(f"\n❌ 检查过程中出现错误: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
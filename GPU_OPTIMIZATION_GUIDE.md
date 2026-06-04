# RTX 4070 16GB GPU优化指南

## 概述

本文档提供针对NVIDIA RTX 4070 16GB GPU的AIpic Web UI优化配置指南。RTX 4070具有16GB GDDR6X显存和强大的计算能力，适合运行Stable Diffusion等AI模型。

## 已完成的优化配置

### 1. 基础配置 (`webui-user.sh`)

已启用以下优化参数：

```bash
# 局域网访问 + GPU优化
export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0 --medvram --opt-sdp-attention --xformers --opt-channelslast"
```

### 2. 参数说明

| 参数 | 说明 | RTX 4070 16GB推荐 |
|------|------|-------------------|
| `--medvram` | 中等VRAM优化模式 | ✅ 推荐 |
| `--opt-sdp-attention` | Scaled Dot Product注意力优化 | ✅ 推荐 |
| `--xformers` | xformers加速库 | ✅ 强烈推荐 |
| `--opt-channelslast` | 内存布局优化 | ✅ 推荐 |
| `--listen` | 允许局域网访问 | ✅ 可选 |
| `--server-name 0.0.0.0` | 监听所有网络接口 | ✅ 可选 |

## GPU优化模式

### 模式1：平衡模式（默认推荐）
```bash
export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --medvram --opt-sdp-attention --xformers --opt-channelslast"
```
- **适用场景**：大多数日常使用
- **内存使用**：8-12GB
- **性能**：良好的速度与质量平衡
- **支持分辨率**：最高1024x1024

### 模式2：性能模式
```bash
export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --xformers --opt-sdp-attention --opt-channelslast"
```
- **适用场景**：需要最快生成速度
- **内存使用**：10-14GB
- **性能**：最大化生成速度
- **支持分辨率**：最高768x768

### 模式3：质量模式
```bash
export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --no-half --no-half-vae --precision full"
```
- **适用场景**：需要最高输出质量
- **内存使用**：12-16GB
- **性能**：较慢但质量最好
- **支持分辨率**：最高512x512

### 模式4：低内存模式
```bash
export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --lowvram --xformers"
```
- **适用场景**：处理超大图像或复杂工作流
- **内存使用**：4-8GB
- **性能**：较慢但内存占用低
- **支持分辨率**：最高2048x2048

## 环境变量优化

### PyTorch内存分配优化
```bash
# 在webui-user.sh中添加
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
export CUDA_LAUNCH_BLOCKING=0
export TF_CPP_MIN_LOG_LEVEL=2
export TORCH_CUDA_ARCH_LIST="8.9"  # RTX 4070计算能力
```

### 参数说明
- `PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"`：优化内存分配，减少碎片
- `CUDA_LAUNCH_BLOCKING=0`：禁用同步启动，提高并行性
- `TF_CPP_MIN_LOG_LEVEL=2`：减少TensorFlow日志输出
- `TORCH_CUDA_ARCH_LIST="8.9"`：指定RTX 4070的计算能力

## 使用工具

### 1. GPU优化配置脚本
```bash
# 给脚本添加执行权限
chmod +x webui-gpu-optimized.sh

# 显示GPU优化建议
./webui-gpu-optimized.sh --recommend

# 配置平衡模式（默认）
./webui-gpu-optimized.sh balanced

# 配置性能模式
./webui-gpu-optimized.sh performance

# 配置质量模式
./webui-gpu-optimized.sh quality

# 配置低内存模式
./webui-gpu-optimized.sh lowvram

# 自定义模式
./webui-gpu-optimized.sh custom
```

### 2. GPU性能测试脚本
```bash
# 创建性能测试脚本
./webui-gpu-optimized.sh --test

# 运行性能测试
./test_gpu_performance.sh
```

测试内容包括：
- CUDA可用性检查
- GPU内存带宽测试
- 计算性能测试（矩阵乘法）
- AIpic相关操作测试
- 内存使用情况测试

## 安装和验证

### 1. 验证CUDA安装
```bash
# 激活虚拟环境
source venv/bin/activate

# 检查PyTorch CUDA支持
python -c "import torch; print('PyTorch版本:', torch.__version__); print('CUDA可用:', torch.cuda.is_available()); print('GPU数量:', torch.cuda.device_count())"

# 检查GPU信息
python -c "
import torch
if torch.cuda.is_available():
    for i in range(torch.cuda.device_count()):
        props = torch.cuda.get_device_properties(i)
        print(f'GPU {i}: {props.name}')
        print(f'  显存: {props.total_memory / 1024**3:.2f} GB')
        print(f'  计算能力: {props.major}.{props.minor}')
else:
    print('CUDA不可用')
"
```

### 2. 安装xformers（如需要）
```bash
# 对于Linux系统
pip install xformers

# 对于Windows系统
pip install xformers --index-url https://download.pytorch.org/whl/cu118
```

### 3. 验证优化效果
```bash
# 启动服务时观察日志
./start_aipic.sh

# 监控GPU使用
nvidia-smi

# 或使用更详细的监控
watch -n 1 nvidia-smi
```

## 性能调优建议

### 1. 批量大小优化
- **RTX 4070 16GB推荐**：批大小2-4
- **小分辨率（512x512）**：可尝试批大小4-8
- **大分辨率（1024x1024）**：建议批大小1-2

### 2. 分辨率设置
| 分辨率 | 推荐批大小 | 预计VRAM使用 |
|--------|------------|--------------|
| 512x512 | 4-8 | 8-12GB |
| 768x768 | 2-4 | 10-14GB |
| 1024x1024 | 1-2 | 12-16GB |
| 1280x720 | 2-3 | 10-13GB |
| 1920x1080 | 1 | 14-16GB |

### 3. 高分辨率修复（Hires Fix）
- **启用条件**：基础分辨率≤512x512
- **放大倍数**：1.5-2.0倍
- **去噪强度**：0.3-0.5
- **VRAM占用**：增加2-4GB

### 4. 模型选择优化
- **标准模型**：SD 1.5, SD 2.1 - 适合大多数场景
- **XL模型**：SDXL - 需要更多VRAM，建议使用`--medvram`
- **自定义模型**：根据模型大小调整参数

## 故障排除

### 问题1：CUDA不可用
**症状**：`torch.cuda.is_available()`返回False

**解决方案**：
```bash
# 检查NVIDIA驱动
nvidia-smi

# 重新安装PyTorch CUDA版本
pip uninstall torch torchvision -y
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118

# 验证安装
python -c "import torch; print(torch.cuda.is_available())"
```

### 问题2：内存不足（OOM）
**症状**：`CUDA out of memory`

**解决方案**：
1. 降低批大小
2. 降低分辨率
3. 启用低内存模式：
   ```bash
   export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --lowvram"
   ```
4. 清理GPU缓存：
   ```python
   import torch
   torch.cuda.empty_cache()
   ```

### 问题3：xformers安装失败
**症状**：无法导入xformers

**解决方案**：
```bash
# 尝试不同版本
pip install xformers==0.0.20

# 或从源码编译
pip install -U -I --no-deps https://github.com/C43H66N12O12S2/stable-diffusion-webui/releases/download/linux/xformers-0.0.21.dev544-cp310-cp310-linux_x86_64.whl
```

### 问题4：生成速度慢
**症状**：图像生成时间过长

**解决方案**：
1. 启用所有优化：
   ```bash
   export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --xformers --opt-sdp-attention --opt-channelslast"
   ```
2. 禁用安全检查：
   ```bash
   export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --disable-safe-unpickle --no-hashing"
   ```
3. 使用更快的采样器：Euler a, DPM++ 2M

## 监控和诊断

### 1. 实时监控
```bash
# 监控GPU使用
nvidia-smi -l 1

# 监控进程
watch -n 1 "ps aux | grep python | grep -v grep"

# 查看日志
tail -f ~/.cache/AIpic/log.txt
```

### 2. 性能基准测试
```bash
# 运行内置基准测试
./test_gpu_performance.sh

# 测试不同配置
export COMMANDLINE_ARGS="--medvram --xformers"
./start_aipic.sh --test

export COMMANDLINE_ARGS="--opt-sdp-attention --xformers"
./start_aipic.sh --test
```

### 3. 内存使用分析
```python
# 在Python交互环境中
import torch
print(f"已分配: {torch.cuda.memory_allocated()/1024**3:.2f} GB")
print(f"缓存: {torch.cuda.memory_reserved()/1024**3:.2f} GB")
print(f"最大已分配: {torch.cuda.max_memory_allocated()/1024**3:.2f} GB")
```

## 最佳实践

### 1. 启动优化
```bash
# 使用优化脚本
./start_aipic.sh

# 或直接使用优化参数
python launch.py --listen --port 7860 --medvram --xformers --opt-sdp-attention --opt-channelslast
```

### 2. 日常使用建议
- **工作流**：先使用低分辨率生成草图，再用高分辨率修复
- **批处理**：合理设置批大小，避免OOM
- **模型管理**：及时卸载不用的模型释放内存
- **定期重启**：长时间运行后重启服务清理内存

### 3. 高级优化
```bash
# 组合优化参数
export COMMANDLINE_ARGS="--listen --port 7860 --medvram --xformers --opt-sdp-attention --opt-channelslast --disable-safe-unpickle --no-hashing --api --autolaunch"

# 环境变量优化
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
export CUDA_LAUNCH_BLOCKING=0
export TF_CPP_MIN_LOG_LEVEL=2
```

## 性能预期

### RTX 4070 16GB性能参考
| 任务 | 512x512 | 768x768 | 1024x1024 |
|------|---------|---------|-----------|
| 文本生成图像 | 2-4秒 | 4-8秒 | 8-15秒 |
| 图像到图像 | 3-5秒 | 6-10秒 | 12-20秒 |
| 高分辨率修复 | 5-8秒 | 10-15秒 | 20-30秒 |
| 批处理（4张） | 8-12秒 | 15-25秒 | 30-50秒 |

### VRAM使用参考
| 操作 | 最小VRAM | 典型VRAM | 最大VRAM |
|------|----------|----------|----------|
| 模型加载 | 2GB | 3GB | 4GB |
| 512x512生成 | 4GB | 6GB | 8GB |
| 1024x1024生成 | 8GB | 10GB | 12GB |
| 高分辨率修复 | 10GB | 12GB | 14GB |
| 批处理（4张） | +2GB | +3GB | +4GB |

## 更新和维护

### 1. 定期更新
```bash
# 更新AIpic
git pull

# 更新依赖
pip install -r requirements.txt --upgrade

# 更新xformers
pip install xformers --upgrade
```

### 2. 清理缓存
```bash
# 清理PyTorch缓存
python -c "import torch; torch.cuda.empty_cache()"

# 清理临时文件
rm -rf ~/.cache/AIpic/tmp/*
```

### 3. 性能调优
定期运行性能测试，根据结果调整参数：
```bash
./test_gpu_performance.sh
```

## 支持与反馈

如果遇到问题：
1. 检查日志文件：`~/.cache/AIpic/log.txt`
2. 运行诊断脚本：`./test_gpu_performance.sh`
3. 参考官方文档
4. 在社区寻求帮助

## 版本历史

### v1.0.0 (2024-01-01)
- 初始版本发布
- RTX 4070 16GB优化配置
- 完整的性能测试工具
- 详细的故障排除指南
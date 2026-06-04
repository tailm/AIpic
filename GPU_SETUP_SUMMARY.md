# RTX 4070 16GB GPU加速配置总结

## 已完成的工作

### 1. GPU优化配置文件 (`webui-user.sh`)

已配置以下优化参数：
```bash
# 局域网访问 + GPU优化
export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0 --medvram --opt-sdp-attention --xformers --opt-channelslast"
```

### 2. 创建的优化工具

#### webui-gpu-optimized.sh
**功能**: GPU优化配置脚本
**使用方法**:
```bash
# 显示优化建议
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

# 创建性能测试脚本
./webui-gpu-optimized.sh --test
```

#### check_gpu_setup.sh
**功能**: GPU配置检查脚本
**检查项目**:
- NVIDIA驱动状态
- CUDA工具包安装
- PyTorch CUDA支持
- xformers安装状态
- 配置文件检查
- 快速性能测试

**使用方法**:
```bash
./check_gpu_setup.sh
```

#### test_gpu_performance.sh
**功能**: GPU性能测试脚本（由webui-gpu-optimized.sh生成）
**测试项目**:
- CUDA可用性检查
- 内存带宽测试
- 计算性能测试
- AIpic相关操作测试
- 内存使用情况测试

**使用方法**:
```bash
./test_gpu_performance.sh
```

### 3. 优化参数说明

| 参数 | 作用 | RTX 4070 16GB推荐 |
|------|------|-------------------|
| `--medvram` | 中等VRAM优化模式 | ✅ 推荐 |
| `--opt-sdp-attention` | Scaled Dot Product注意力优化 | ✅ 推荐 |
| `--xformers` | xformers加速库 | ✅ 强烈推荐 |
| `--opt-channelslast` | 内存布局优化 | ✅ 推荐 |
| `--listen` | 允许局域网访问 | ✅ 可选 |
| `--server-name 0.0.0.0` | 监听所有网络接口 | ✅ 可选 |

### 4. 环境变量优化（可选）

在`webui-user.sh`中添加以下环境变量可进一步优化性能：
```bash
# GPU环境变量优化
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
export CUDA_LAUNCH_BLOCKING=0
export TF_CPP_MIN_LOG_LEVEL=2
export TORCH_CUDA_ARCH_LIST="8.9"  # RTX 4070计算能力
```

## 部署步骤

### 步骤1：验证GPU环境
```bash
# 运行GPU检查脚本
./check_gpu_setup.sh

# 如果检查失败，安装必要的组件
# 1. 确保NVIDIA驱动已安装
# 2. 安装CUDA工具包（11.8或12.1）
# 3. 安装PyTorch CUDA版本
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
# 4. 安装xformers
pip install xformers
```

### 步骤2：配置GPU优化
```bash
# 使用优化脚本配置
./webui-gpu-optimized.sh balanced

# 或手动编辑webui-user.sh
# 添加：--medvram --opt-sdp-attention --xformers --opt-channelslast
```

### 步骤3：测试性能
```bash
# 运行性能测试
./test_gpu_performance.sh

# 预期输出应显示：
# ✅ CUDA可用: True
# ✅ GPU: NVIDIA GeForce RTX 4070
# ✅ 显存: 16.00 GB
# ✅ 计算性能: > 100 GFLOPS
```

### 步骤4：启动服务
```bash
# 使用优化脚本启动
./start_aipic.sh

# 或直接启动
./webui.sh
```

### 步骤5：验证GPU加速
1. 查看启动日志，确认GPU被识别
2. 使用`nvidia-smi`监控GPU使用情况
3. 测试图像生成速度

## 性能预期

### RTX 4070 16GB基准性能
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

## 故障排除

### 问题1：CUDA不可用
**症状**: `torch.cuda.is_available()`返回False

**解决方案**:
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
**症状**: `CUDA out of memory`

**解决方案**:
1. 降低批大小
2. 降低分辨率
3. 启用低内存模式：
   ```bash
   # 编辑webui-user.sh
   export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --lowvram"
   ```
4. 清理GPU缓存：
   ```python
   import torch
   torch.cuda.empty_cache()
   ```

### 问题3：xformers安装失败
**解决方案**:
```bash
# 尝试不同版本
pip install xformers==0.0.20

# 或从预编译包安装
pip install -U -I --no-deps https://github.com/C43H66N12O12S2/stable-diffusion-webui/releases/download/linux/xformers-0.0.21.dev544-cp310-cp310-linux_x86_64.whl
```

### 问题4：生成速度慢
**解决方案**:
1. 确保所有优化参数已启用
2. 检查GPU使用率：`nvidia-smi`
3. 尝试不同的采样器（如Euler a）
4. 禁用不必要的扩展

## 监控和维护

### 实时监控
```bash
# 监控GPU使用
nvidia-smi -l 1

# 监控进程
watch -n 1 "ps aux | grep python | grep -v grep"

# 查看日志
tail -f ~/.cache/AIpic/log.txt
```

### 定期维护
```bash
# 清理GPU缓存
python -c "import torch; torch.cuda.empty_cache()"

# 更新依赖
pip install -r requirements.txt --upgrade

# 更新xformers
pip install xformers --upgrade
```

### 性能调优
```bash
# 运行性能测试
./test_gpu_performance.sh

# 根据测试结果调整参数
# 编辑webui-user.sh中的COMMANDLINE_ARGS
```

## 最佳实践

### 1. 工作流优化
- **草图阶段**: 使用512x512分辨率快速生成
- **精修阶段**: 使用高分辨率修复（Hires Fix）
- **批处理**: 合理设置批大小，避免OOM
- **模型管理**: 及时卸载不用的模型

### 2. 参数调优
```bash
# 平衡模式（日常使用）
export COMMANDLINE_ARGS="--medvram --xformers --opt-sdp-attention --opt-channelslast"

# 性能模式（快速生成）
export COMMANDLINE_ARGS="--xformers --opt-sdp-attention --opt-channelslast"

# 质量模式（最佳输出）
export COMMANDLINE_ARGS="--no-half --no-half-vae --precision full"

# 低内存模式（超大图像）
export COMMANDLINE_ARGS="--lowvram --xformers"
```

### 3. 环境优化
```bash
# 在启动前设置环境变量
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
export CUDA_LAUNCH_BLOCKING=0
export TF_CPP_MIN_LOG_LEVEL=2
```

## 验证清单

### 部署前检查
- [ ] NVIDIA驱动已安装 (`nvidia-smi`可用)
- [ ] CUDA工具包已安装 (`nvcc --version`)
- [ ] PyTorch CUDA版本已安装 (`torch.cuda.is_available()`返回True)
- [ ] xformers已安装 (`import xformers`成功)
- [ ] 配置文件已优化 (`webui-user.sh`包含GPU参数)

### 部署后验证
- [ ] 服务正常启动 (`./start_aipic.sh`无错误)
- [ ] GPU被正确识别（日志显示GPU信息）
- [ ] 图像生成速度符合预期
- [ ] VRAM使用在合理范围内（< 14GB）
- [ ] 局域网访问正常（如配置）

### 性能验证
- [ ] 运行`./test_gpu_performance.sh`通过所有测试
- [ ] 512x512图像生成时间<5秒
- [ ] 无内存不足错误
- [ ] GPU使用率在生成时>80%

## 支持资源

### 文档
- `GPU_OPTIMIZATION_GUIDE.md` - 详细优化指南
- `LAN_ACCESS_GUIDE.md` - 局域网访问指南
- `LAN_SETUP_SUMMARY.md` - 部署总结

### 脚本工具
- `webui-gpu-optimized.sh` - GPU优化配置
- `check_gpu_setup.sh` - GPU环境检查
- `test_gpu_performance.sh` - 性能测试
- `start_aipic.sh` - 优化启动脚本

### 故障排除
1. 查看日志：`tail -f ~/.cache/AIpic/log.txt`
2. 运行检查：`./check_gpu_setup.sh`
3. 测试性能：`./test_gpu_performance.sh`
4. 调整配置：`./webui-gpu-optimized.sh`

## 更新日志

### v1.0.0 (2024-01-01)
- 初始版本发布
- RTX 4070 16GB优化配置
- 完整的GPU检查工具
- 性能测试套件
- 详细的故障排除指南

### 配置总结
您的RTX 4070 16GB GPU已配置为：
- ✅ 启用GPU加速 (`--medvram --xformers --opt-sdp-attention --opt-channelslast`)
- ✅ 支持局域网访问 (`--listen --server-name 0.0.0.0`)
- ✅ 提供多种优化模式（平衡/性能/质量/低内存）
- ✅ 包含完整的监控和测试工具
- ✅ 详细的文档和故障排除指南

现在可以运行 `./check_gpu_setup.sh` 验证配置，然后使用 `./start_aipic.sh` 启动优化后的AIpic服务。
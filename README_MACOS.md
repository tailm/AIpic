# Stable Diffusion Web UI - macOS 安装指南

本指南提供了在 macOS（包括 Apple Silicon M1/M2/M3）上安装和运行 Stable Diffusion Web UI 的完整说明。

## 快速开始

### 方法一：使用安装脚本（推荐）

1. 克隆项目：
   ```bash
   git clone https://github.com/tailm/AIpic.git
   cd AIpic
   ```

2. 运行安装脚本：
   ```bash
   ./install_macos.sh
   ```

3. 下载模型文件：
   - 将 Stable Diffusion 模型文件（如 `v1-5-pruned-emaonly.safetensors`）放入 `models/Stable-diffusion/` 目录

4. 启动 Web UI：
   ```bash
   ./webui.sh
   ```

5. 在浏览器中打开：http://127.0.0.1:7860

### 方法二：手动安装

详细步骤请参考 [MACOS_INSTALLATION.md](MACOS_INSTALLATION.md)。

## 文件说明

### 关键文件

1. **`requirements.txt`** - 修复了版本依赖的包列表
2. **`requirements_macos.txt`** - macOS 专用依赖列表（包含详细说明）
3. **`install_macos.sh`** - 一键安装脚本
4. **`MACOS_INSTALLATION.md`** - 完整的安装部署文档
5. **`webui-user.sh`** - 配置文件（已预配置 macOS 参数）

### 已修复的问题

1. **torch/torchvision 版本兼容性**：使用 macOS ARM 兼容版本
2. **httpx/httpcore 版本冲突**：使用兼容版本
3. **basicsr 缺少 load_file_from_url 函数**：已通过补丁修复
4. **GFPGAN tb-nightly 依赖问题**：跳过安装
5. **realesrgan 版本冲突**：使用兼容版本
6. **numpy 版本冲突**：使用兼容版本

## 配置说明

### webui-user.sh 关键配置

```bash
# 跳过 CUDA 测试（macOS 必需）
export COMMANDLINE_ARGS="--skip-torch-cuda-test --port 7860"

# 使用正确的 Python 路径
python_cmd="/path/to/AIpic/venv/bin/python"

# 跳过 GFPGAN 安装
export GFPGAN_PACKAGE=""
```

### 可选参数

- `--medvram`：中等 VRAM 模式
- `--lowvram`：低 VRAM 模式
- `--no-half`：不使用半精度（解决某些兼容性问题）
- `--use-cpu all`：完全使用 CPU（无 GPU 时）
- `--listen`：允许网络访问
- `--share`：创建公共链接

## 故障排除

### 常见问题

1. **"Torch not compiled with CUDA enabled"**
   - 确保 `webui-user.sh` 中包含 `--skip-torch-cuda-test`

2. **"ModuleNotFoundError: No module named 'basicsr.utils.download_util'"**
   - 运行修复脚本：`python fix_basicsr.py`

3. **端口被占用**
   - 更改端口号：`--port 7862`

4. **内存不足**
   - 添加 `--medvram` 或 `--lowvram` 参数
   - 减少生成图片的分辨率

### 日志文件

- 控制台输出：查看启动时的错误信息
- `webui.log`：详细的日志文件

## 性能优化

### 对于 Apple Silicon Mac

```bash
# 在 webui-user.sh 中添加
export COMMANDLINE_ARGS="--skip-torch-cuda-test --use-cpu all --no-half"
```

### 对于 Intel Mac

```bash
# 在 webui-user.sh 中添加
export COMMANDLINE_ARGS="--skip-torch-cuda-test --xformers"
```

## 更新

### 更新代码

```bash
git pull
```

### 更新依赖

```bash
source venv/bin/activate
pip install --upgrade -r requirements.txt
```

### 重新应用补丁

如果更新后出现导入错误：
```bash
python fix_basicsr.py
```

## 支持

如果遇到问题：

1. 查看 [MACOS_INSTALLATION.md](MACOS_INSTALLATION.md) 中的故障排除部分
2. 检查日志文件
3. 确保按照指南的所有步骤操作

## 许可证

本项目基于 Stable Diffusion Web UI，遵循其原始许可证。

---

**注意**：由于 macOS ARM 架构的限制，某些功能（如 GFPGAN、最新版 RealESRGAN）可能无法使用。本配置提供了最佳的兼容性方案。
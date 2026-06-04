# RTX 4070 16GB AIpic部署检查清单

## 部署前准备

### 硬件要求检查
- [ ] **GPU**: NVIDIA RTX 4070 16GB
- [ ] **内存**: ≥16GB 系统内存
- [ ] **存储**: ≥50GB 可用空间（用于模型和缓存）
- [ ] **网络**: 稳定的网络连接（用于下载模型）

### 软件要求检查
- [ ] **操作系统**: Ubuntu 24.04 LTS（推荐）或其他Linux发行版
- [ ] **Python**: 3.10-3.13
- [ ] **CUDA**: 11.8 或 12.1
- [ ] **NVIDIA驱动**: ≥525.60.11

## 安装步骤

### 步骤1：系统准备
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础依赖
sudo apt install -y python3-pip python3-venv git wget curl

# 安装NVIDIA驱动（如未安装）
sudo apt install -y nvidia-driver-535  # 或最新版本
```

### 步骤2：CUDA安装
```bash
# 检查CUDA版本
nvcc --version

# 如果未安装，安装CUDA 12.1
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit-12-1
```

### 步骤3：项目部署
```bash
# 克隆项目（如果尚未克隆）
git clone <项目地址>
cd AIpic

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 安装PyTorch CUDA版本
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# 安装xformers
pip install xformers
```

## 配置步骤

### 步骤4：GPU优化配置
```bash
# 给脚本添加执行权限
chmod +x webui-gpu-optimized.sh check_gpu_setup.sh test_gpu_performance.sh

# 检查GPU环境
./check_gpu_setup.sh

# 配置GPU优化（平衡模式）
./webui-gpu-optimized.sh balanced

# 验证配置
cat webui-user.sh | grep COMMANDLINE_ARGS
# 应该输出：export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0 --medvram --opt-sdp-attention --xformers --opt-channelslast"
```

### 步骤5：局域网访问配置
```bash
# 如果需要局域网访问，确保配置正确
cat webui-user.sh | grep COMMANDLINE_ARGS
# 应该包含：--listen --server-name 0.0.0.0

# 如果需要特定IP，运行
./webui-lan.sh --ip 192.168.50.228 --port 7860
```

## 验证步骤

### 步骤6：环境验证
```bash
# 验证Python环境
python --version
# 应该输出：Python 3.10+ 

# 验证PyTorch CUDA
python -c "import torch; print('PyTorch:', torch.__version__); print('CUDA:', torch.cuda.is_available())"
# 应该输出：CUDA: True

# 验证GPU信息
python -c "
import torch
if torch.cuda.is_available():
    for i in range(torch.cuda.device_count()):
        props = torch.cuda.get_device_properties(i)
        print(f'GPU {i}: {props.name}')
        print(f'  显存: {props.total_memory / 1024**3:.2f} GB')
else:
    print('CUDA不可用')
"
# 应该显示RTX 4070和16GB显存
```

### 步骤7：性能测试
```bash
# 运行性能测试
./test_gpu_performance.sh

# 检查测试结果
# 应该显示：
# ✅ CUDA可用: True
# ✅ GPU: NVIDIA GeForce RTX 4070
# ✅ 显存: 16.00 GB
# ✅ 计算性能: > 100 GFLOPS
```

### 步骤8：服务启动测试
```bash
# 测试启动（不实际运行）
python launch.py --help

# 检查参数解析
python launch.py --skip-torch-cuda-test --dry-run
```

## 最终部署

### 步骤9：启动服务
```bash
# 方法1：使用优化启动脚本
./start_aipic.sh

# 方法2：直接启动
./webui.sh

# 方法3：使用systemd服务（生产环境）
sudo cp aipic.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable aipic
sudo systemctl start aipic
sudo systemctl status aipic
```

### 步骤10：验证服务
```bash
# 检查服务状态
curl -s http://127.0.0.1:7860 | head -5

# 检查日志
tail -f ~/.cache/AIpic/log.txt

# 监控GPU使用
watch -n 1 nvidia-smi
```

## 故障排除检查点

### 问题：CUDA不可用
```bash
# 检查NVIDIA驱动
nvidia-smi

# 检查CUDA版本
nvcc --version

# 重新安装PyTorch
pip uninstall torch torchvision -y
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
```

### 问题：内存不足（OOM）
```bash
# 检查当前配置
cat webui-user.sh | grep COMMANDLINE_ARGS

# 切换到低内存模式
./webui-gpu-optimized.sh lowvram

# 监控内存使用
nvidia-smi -l 1
```

### 问题：启动失败
```bash
# 查看详细日志
python launch.py --skip-torch-cuda-test 2>&1 | tee debug.log

# 检查依赖
pip list | grep -E "(torch|xformers|gradio)"

# 清理缓存
rm -rf ~/.cache/AIpic
```

### 问题：生成速度慢
```bash
# 检查GPU使用率
nvidia-smi

# 验证优化参数
./check_gpu_setup.sh

# 尝试性能模式
./webui-gpu-optimized.sh performance
```

## 生产环境优化

### 系统优化
```bash
# 调整系统参数
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 调整文件描述符限制
echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
```

### GPU优化
```bash
# 设置GPU持久模式
sudo nvidia-smi -pm 1

# 设置GPU功率限制（可选）
sudo nvidia-smi -pl 200  # 200W，根据实际情况调整
```

### 服务管理
```bash
# 创建systemd服务文件
sudo tee /etc/systemd/system/aipic.service << EOF
[Unit]
Description=AIpic Web UI Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/path/to/AIpic
Environment="PATH=/path/to/AIpic/venv/bin"
ExecStart=/path/to/AIpic/venv/bin/python launch.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable aipic
sudo systemctl start aipic
```

## 监控和维护

### 日常监控
```bash
# 查看服务状态
sudo systemctl status aipic

# 查看GPU状态
nvidia-smi

# 查看日志
sudo journalctl -u aipic -f

# 查看资源使用
htop
```

### 定期维护
```bash
# 每周清理缓存
find ~/.cache/AIpic -type f -name "*.tmp" -delete
find ~/.cache/AIpic -type f -mtime +7 -delete

# 每月更新
cd /path/to/AIpic
git pull
source venv/bin/activate
pip install -r requirements.txt --upgrade

# 季度性能测试
./test_gpu_performance.sh > performance_$(date +%Y%m%d).log
```

### 备份和恢复
```bash
# 备份配置
cp webui-user.sh webui-user.sh.backup.$(date +%Y%m%d)

# 备份模型
tar -czf models_backup_$(date +%Y%m%d).tar.gz models/

# 恢复配置
cp webui-user.sh.backup.20240101 webui-user.sh
```

## 安全检查

### 网络安全
- [ ] 防火墙配置正确（端口7860）
- [ ] 使用强密码（如果启用身份验证）
- [ ] 定期更新系统和软件
- [ ] 监控异常访问日志

### 数据安全
- [ ] 定期备份模型和配置
- [ ] 使用版本控制管理配置
- [ ] 加密敏感数据
- [ ] 设置访问日志

### 性能安全
- [ ] 监控GPU温度（<85°C）
- [ ] 监控显存使用（<90%）
- [ ] 设置资源限制
- [ ] 定期清理临时文件

## 成功标准

### 部署成功标志
- [ ] 服务正常启动（无错误日志）
- [ ] GPU被正确识别和使用
- [ ] 图像生成功能正常
- [ ] 局域网访问正常（如配置）
- [ ] 性能符合预期（512x512图像<5秒）

### 性能达标标准
- [ ] GPU使用率在生成时>80%
- [ ] 显存使用<14GB（16GB显卡）
- [ ] 响应时间<2秒（Web界面）
- [ ] 无内存泄漏（长时间运行稳定）

### 稳定性标准
- [ ] 连续运行24小时无崩溃
- [ ] 内存使用稳定（无持续增长）
- [ ] GPU温度正常（<85°C）
- [ ] 网络连接稳定

## 紧急恢复

### 服务崩溃恢复
```bash
# 停止服务
sudo systemctl stop aipic

# 清理GPU内存
python -c "import torch; torch.cuda.empty_cache()"

# 重启服务
sudo systemctl start aipic
```

### 配置错误恢复
```bash
# 恢复备份配置
cp webui-user.sh.backup.latest webui-user.sh

# 重置虚拟环境
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 数据损坏恢复
```bash
# 从备份恢复模型
tar -xzf models_backup_latest.tar.gz

# 清理缓存
rm -rf ~/.cache/AIpic

# 重新启动
./start_aipic.sh
```

## 支持资源

### 文档
- `GPU_OPTIMIZATION_GUIDE.md` - GPU优化详细指南
- `LAN_ACCESS_GUIDE.md` - 局域网访问配置
- `GPU_SETUP_SUMMARY.md` - GPU设置总结
- `README.md` - 项目主文档

### 工具脚本
- `webui-gpu-optimized.sh` - GPU优化配置
- `check_gpu_setup.sh` - 环境检查
- `test_gpu_performance.sh` - 性能测试
- `start_aipic.sh` - 优化启动
- `webui-lan.sh` - 局域网配置

### 联系支持
- 查看日志：`tail -f ~/.cache/AIpic/log.txt`
- 运行诊断：`./check_gpu_setup.sh`
- 性能测试：`./test_gpu_performance.sh`
- 调整配置：`./webui-gpu-optimized.sh`

## 完成确认

### 最终验证清单
- [ ] 所有安装步骤完成
- [ ] 所有配置步骤完成
- [ ] 所有验证测试通过
- [ ] 服务正常运行
- [ ] 性能符合预期
- [ ] 监控系统就绪
- [ ] 备份策略就绪
- [ ] 文档完整更新

### 部署完成标志
当所有检查项都标记为完成时，表示RTX 4070 16GB的AIpic部署成功。现在可以：

1. **开始使用**：访问 `http://服务器IP:7860`
2. **监控性能**：使用 `nvidia-smi` 和日志监控
3. **定期维护**：按照维护计划执行
4. **问题反馈**：记录任何问题并参考故障排除指南

**部署完成！** 🎉
#!/usr/bin/env bash

#################################################
# GPU配置检查脚本
# 验证RTX 4070 16GB的AIpic配置
#################################################

set -e

# 颜色代码
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数：打印彩色输出
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 函数：检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 函数：检查NVIDIA驱动
check_nvidia_driver() {
    print_info "检查NVIDIA驱动..."
    
    if command_exists nvidia-smi; then
        print_success "找到nvidia-smi命令"
        
        # 获取驱动信息
        local driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
        print_info "驱动版本: $driver_version"
        
        # 获取GPU信息
        local gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | head -1)
        if [ -n "$gpu_info" ]; then
            local gpu_name=$(echo "$gpu_info" | cut -d',' -f1)
            local gpu_memory=$(echo "$gpu_info" | cut -d',' -f2)
            print_success "GPU: $gpu_name"
            print_success "显存: ${gpu_memory}MB"
            
            # 检查是否是RTX 4070
            if echo "$gpu_name" | grep -qi "RTX 4070"; then
                print_success "✅ 检测到RTX 4070 GPU"
            else
                print_warning "⚠️  检测到GPU: $gpu_name (预期RTX 4070)"
            fi
            
            # 检查显存是否足够
            if [ "$gpu_memory" -ge 15000 ]; then
                print_success "✅ 显存充足 (${gpu_memory}MB ≥ 15GB)"
            else
                print_warning "⚠️  显存可能不足 (${gpu_memory}MB < 15GB)"
            fi
        else
            print_error "无法获取GPU信息"
            return 1
        fi
    else
        print_error "未找到nvidia-smi命令"
        print_info "请安装NVIDIA驱动: https://www.nvidia.com/Download/index.aspx"
        return 1
    fi
    
    return 0
}

# 函数：检查CUDA工具包
check_cuda_toolkit() {
    print_info "检查CUDA工具包..."
    
    if command_exists nvcc; then
        local cuda_version=$(nvcc --version | grep "release" | awk '{print $6}' | cut -d',' -f1)
        print_success "CUDA版本: $cuda_version"
        
        # 检查CUDA版本兼容性
        if [[ "$cuda_version" == "11."* ]] || [[ "$cuda_version" == "12."* ]]; then
            print_success "✅ CUDA版本兼容 ($cuda_version)"
        else
            print_warning "⚠️  CUDA版本可能不兼容 ($cuda_version)"
            print_info "推荐版本: CUDA 11.8 或 12.1"
        fi
    else
        print_warning "未找到nvcc命令"
        print_info "CUDA工具包可能未安装或未在PATH中"
    fi
    
    # 检查CUDA库
    local cuda_lib_paths=(
        "/usr/local/cuda/lib64"
        "/usr/lib/x86_64-linux-gnu"
        "/usr/local/cuda-12.1/lib64"
        "/usr/local/cuda-11.8/lib64"
    )
    
    local found_lib=false
    for path in "${cuda_lib_paths[@]}"; do
        if [ -d "$path" ] && [ -f "$path/libcudart.so" ]; then
            print_success "找到CUDA库: $path"
            found_lib=true
            break
        fi
    done
    
    if [ "$found_lib" = false ]; then
        print_warning "未找到CUDA库文件"
    fi
    
    return 0
}

# 函数：检查PyTorch CUDA支持
check_pytorch_cuda() {
    print_info "检查PyTorch CUDA支持..."
    
    # 激活虚拟环境
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    fi
    
    # 检查Python环境
    if ! command_exists python; then
        print_error "未找到python命令"
        return 1
    fi
    
    # 运行Python检查脚本
    python -c "
import sys
import subprocess

try:
    import torch
    print('PyTorch版本:', torch.__version__)
    
    # 检查CUDA
    cuda_available = torch.cuda.is_available()
    print('CUDA可用:', cuda_available)
    
    if cuda_available:
        print('CUDA版本:', torch.version.cuda)
        print('GPU数量:', torch.cuda.device_count())
        
        for i in range(torch.cuda.device_count()):
            props = torch.cuda.get_device_properties(i)
            print(f'GPU {i}: {props.name}')
            print(f'  显存: {props.total_memory / 1024**3:.2f} GB')
            print(f'  计算能力: {props.major}.{props.minor}')
            
            # 检查计算能力兼容性
            compute_capability = props.major + props.minor / 10
            if compute_capability >= 8.0:
                print(f'  ✅ 计算能力兼容 ({compute_capability} ≥ 8.0)')
            else:
                print(f'  ⚠️  计算能力可能不兼容 ({compute_capability} < 8.0)')
    else:
        print('❌ CUDA不可用')
        print('建议:')
        print('  1. 检查NVIDIA驱动')
        print('  2. 安装PyTorch CUDA版本: pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118')
        print('  3. 验证CUDA工具包安装')
        
except ImportError as e:
    print('❌ 无法导入torch:', str(e))
    print('建议: pip install torch torchvision')
except Exception as e:
    print('❌ 检查过程中出错:', str(e))
" 2>&1 | while IFS= read -r line; do
        if [[ "$line" == *"✅"* ]] || [[ "$line" == *"CUDA可用: True"* ]]; then
            echo -e "${GREEN}$line${NC}"
        elif [[ "$line" == *"❌"* ]] || [[ "$line" == *"CUDA可用: False"* ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ "$line" == *"⚠️"* ]] || [[ "$line" == *"警告"* ]]; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo -e "${BLUE}$line${NC}"
        fi
    done
    
    # 检查返回状态
    local pytorch_check=$(python -c "import torch; print(torch.cuda.is_available())" 2>/dev/null || echo "False")
    
    if [ "$pytorch_check" = "True" ]; then
        return 0
    else
        return 1
    fi
}

# 函数：检查xformers
check_xformers() {
    print_info "检查xformers..."
    
    python -c "
try:
    import xformers
    import xformers.ops
    print('✅ xformers版本:', xformers.__version__)
    
    # 测试xformers功能
    import torch
    if torch.cuda.is_available():
        # 创建测试张量
        batch_size = 2
        seq_len = 64
        num_heads = 8
        head_dim = 64
        
        query = torch.randn(batch_size, seq_len, num_heads, head_dim).cuda()
        key = torch.randn(batch_size, seq_len, num_heads, head_dim).cuda()
        value = torch.randn(batch_size, seq_len, num_heads, head_dim).cuda()
        
        # 测试注意力计算
        output = xformers.ops.memory_efficient_attention(query, key, value)
        print('✅ xformers注意力计算测试通过')
    else:
        print('⚠️  CUDA不可用，跳过xformers功能测试')
        
except ImportError as e:
    print('❌ 未安装xformers:', str(e))
    print('建议: pip install xformers')
except Exception as e:
    print('❌ xformers检查出错:', str(e))
" 2>&1 | while IFS= read -r line; do
        if [[ "$line" == *"✅"* ]]; then
            echo -e "${GREEN}$line${NC}"
        elif [[ "$line" == *"❌"* ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ "$line" == *"⚠️"* ]]; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo -e "${BLUE}$line${NC}"
        fi
    done
}

# 函数：检查配置文件
check_config_file() {
    print_info "检查配置文件..."
    
    local config_file="webui-user.sh"
    
    if [ -f "$config_file" ]; then
        print_success "找到配置文件: $config_file"
        
        # 检查COMMANDLINE_ARGS
        if grep -q "export COMMANDLINE_ARGS=" "$config_file"; then
            local args=$(grep "export COMMANDLINE_ARGS=" "$config_file" | cut -d'"' -f2)
            print_info "当前配置: $args"
            
            # 检查GPU相关参数
            local has_gpu_opt=false
            
            if [[ "$args" == *"--medvram"* ]] || [[ "$args" == *"--lowvram"* ]]; then
                print_success "✅ 已配置VRAM优化"
                has_gpu_opt=true
            else
                print_warning "⚠️  未配置VRAM优化参数 (建议添加 --medvram)"
            fi
            
            if [[ "$args" == *"--xformers"* ]]; then
                print_success "✅ 已启用xformers"
                has_gpu_opt=true
            else
                print_warning "⚠️  未启用xformers (建议添加 --xformers)"
            fi
            
            if [[ "$args" == *"--opt-sdp-attention"* ]]; then
                print_success "✅ 已启用注意力优化"
                has_gpu_opt=true
            else
                print_info "ℹ️  可考虑添加 --opt-sdp-attention"
            fi
            
            if [[ "$args" == *"--opt-channelslast"* ]]; then
                print_success "✅ 已启用内存布局优化"
                has_gpu_opt=true
            else
                print_info "ℹ️  可考虑添加 --opt-channelslast"
            fi
            
            if [ "$has_gpu_opt" = true ]; then
                print_success "✅ GPU优化配置已启用"
            else
                print_warning "⚠️  GPU优化配置不完整"
                print_info "运行 ./webui-gpu-optimized.sh 进行优化配置"
            fi
        else
            print_warning "未找到COMMANDLINE_ARGS配置"
            print_info "请运行 ./webui-gpu-optimized.sh 进行配置"
        fi
    else
        print_warning "配置文件不存在: $config_file"
        print_info "创建默认配置: cp webui-user.sh.example webui-user.sh"
    fi
}

# 函数：检查系统要求
check_system_requirements() {
    print_info "检查系统要求..."
    
    # 检查Python版本
    local python_version=$(python --version 2>&1 | awk '{print $2}')
    print_info "Python版本: $python_version"
    
    # 检查PyTorch版本要求
    python -c "
import torch
if hasattr(torch, '__version__'):
    version = torch.__version__.split('+')[0]
    major, minor, patch = map(int, version.split('.')[:3])
    
    # PyTorch 1.13+ 推荐
    if major > 1 or (major == 1 and minor >= 13):
        print('✅ PyTorch版本兼容:', torch.__version__)
    else:
        print('⚠️  PyTorch版本较旧:', torch.__version__)
        print('建议升级到 1.13+')
else:
    print('❌ 无法获取PyTorch版本')
" 2>&1 | while IFS= read -r line; do
        if [[ "$line" == *"✅"* ]]; then
            echo -e "${GREEN}$line${NC}"
        elif [[ "$line" == *"❌"* ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ "$line" == *"⚠️"* ]]; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo -e "${BLUE}$line${NC}"
        fi
    done
    
    # 检查内存
    if command_exists free; then
        local total_mem=$(free -g | awk '/^Mem:/{print $2}')
        print_info "系统内存: ${total_mem}GB"
        
        if [ "$total_mem" -ge 16 ]; then
            print_success "✅ 系统内存充足 (${total_mem}GB ≥ 16GB)"
        elif [ "$total_mem" -ge 8 ]; then
            print_warning "⚠️  系统内存可能不足 (${total_mem}GB < 16GB)"
        else
            print_error "❌ 系统内存不足 (${total_mem}GB < 8GB)"
        fi
    fi
    
    # 检查磁盘空间
    local disk_space=$(df -h . | awk 'NR==2 {print $4}')
    print_info "磁盘可用空间: $disk_space"
}

# 函数：运行快速测试
run_quick_test() {
    print_info "运行快速GPU测试..."
    
    cat > /tmp/quick_gpu_test.py << 'PYEOF'
import torch
import time

print("=" * 50)
print("GPU快速测试")
print("=" * 50)

# 测试1: CUDA可用性
print("\n1. CUDA可用性测试:")
cuda_available = torch.cuda.is_available()
print(f"   CUDA可用: {cuda_available}")

if cuda_available:
    # 测试2: 设备信息
    print("\n2. 设备信息:")
    for i in range(torch.cuda.device_count()):
        props = torch.cuda.get_device_properties(i)
        print(f"   GPU {i}: {props.name}")
        print(f"     显存: {props.total_memory / 1024**3:.2f} GB")
        print(f"     计算能力: {props.major}.{props.minor}")
    
    # 测试3: 张量计算
    print("\n3. 张量计算测试:")
    device = torch.device('cuda')
    
    # 创建张量
    size = 1024
    a = torch.randn(size, size, device=device)
    b = torch.randn(size, size, device=device)
    
    # 预热
    for _ in range(10):
        _ = torch.matmul(a, b)
    
    # 性能测试
    torch.cuda.synchronize()
    start_time = time.time()
    
    iterations = 100
    for _ in range(iterations):
        c = torch.matmul(a, b)
    
    torch.cuda.synchronize()
    elapsed = time.time() - start_time
    
    # 计算FLOPS
    flops = 2 * (size ** 3) * iterations
    gflops = flops / elapsed / 1e9
    
    print(f"   矩阵大小: {size}x{size}")
    print(f"   迭代次数: {iterations}")
    print(f"   计算时间: {elapsed:.3f} 秒")
    print(f"   计算性能: {gflops:.2f} GFLOPS")
    
    # 测试4: 内存带宽
    print("\n4. 内存带宽测试:")
    size_bytes = 100 * 1024 * 1024  # 100MB
    data_cpu = torch.randn(size_bytes // 4, dtype=torch.float32)
    
    # CPU -> GPU
    start = time.time()
    data_gpu = data_cpu.to(device)
    torch.cuda.synchronize()
    cpu_to_gpu_time = time.time() - start
    
    # GPU -> CPU
    start = time.time()
    data_cpu_back = data_gpu.cpu()
    torch.cuda.synchronize()
    gpu_to_cpu_time = time.time() - start
    
    size_gb = size_bytes / (1024**3)
    cpu_to_gpu_bw = size_gb / cpu_to_gpu_time
    gpu_to_cpu_bw = size_gb / gpu_to_cpu_time
    
    print(f"   数据大小: 100 MB")
    print(f"   CPU->GPU带宽: {cpu_to_gpu_bw:.2f} GB/s")
    print(f"   GPU->CPU带宽: {gpu_to_cpu_bw:.2f} GB/s")
    
    # 测试5: 内存使用
    print("\n5. 内存使用测试:")
    torch.cuda.empty_cache()
    initial = torch.cuda.memory_allocated()
    
    # 分配内存
    tensors = []
    for i in range(5):
        try:
            t = torch.randn(256, 256, 256, device=device)  # ~64MB
            tensors.append(t)
            current = torch.cuda.memory_allocated()
            print(f"   已分配: {current / 1024**3:.2f} GB")
        except RuntimeError as e:
            print(f"   分配失败: {str(e)}")
            break
    
    # 清理
    del tensors
    torch.cuda.empty_cache()
    final = torch.cuda.memory_allocated()
    
    print(f"   最终内存: {final / 1024**3:.2f} GB")
    
    print("\n" + "=" * 50)
    print("测试完成!")
    print("=" * 50)
    
else:
    print("\n❌ CUDA不可用，跳过GPU测试")
    print("建议:")
    print("  1. 检查NVIDIA驱动安装")
    print("  2. 安装PyTorch CUDA版本")
    print("  3. 验证CUDA工具包")

PYEOF

    python /tmp/quick_gpu_test.py
    rm -f /tmp/quick_gpu_test.py
}

# 主函数
main() {
    echo ""
    print_info "================================================"
    print_info "RTX 4070 16GB GPU配置检查"
    print_info "================================================"
    echo ""
    
    # 检查系统要求
    check_system_requirements
    
    echo ""
    print_info "--- NVIDIA驱动检查 ---"
    if ! check_nvidia_driver; then
        print_error "NVIDIA驱动检查失败"
        return 1
    fi
    
    echo ""
    print_info "--- CUDA工具包检查 ---"
    check_cuda_toolkit
    
    echo ""
    print_info "--- PyTorch CUDA支持检查 ---"
    if ! check_pytorch_cuda; then
        print_error "PyTorch CUDA支持检查失败"
        return 1
    fi
    
    echo ""
    print_info "--- xformers检查 ---"
    check_xformers
    
    echo ""
    print_info "--- 配置文件检查 ---"
    check_config_file
    
    echo ""
    print_info "--- 快速性能测试 ---"
    run_quick_test
    
    echo ""
    print_success "================================================"
    print_success "检查完成!"
    print_success "================================================"
    echo ""
    
    # 提供建议
    print_info "下一步建议:"
    print_info "  1. 运行完整性能测试: ./test_gpu_performance.sh"
    print_info "  2. 优化配置: ./webui-gpu-optimized.sh"
    print_info "  3. 启动AIpic: ./start_aipic.sh"
    print_info "  4. 监控GPU: watch -n 1 nvidia-smi"
    echo ""
}

# 运行主函数
main "$@"
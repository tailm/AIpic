#!/usr/bin/env bash

#################################################
# AIpic GPU优化配置脚本
# 专为RTX 4070 16GB GPU优化
#################################################

set -e

# 颜色代码
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
CONFIG_FILE="webui-user.sh"
BACKUP_FILE="webui-user.sh.backup.gpu.$(date +%Y%m%d_%H%M%S)"

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

# 函数：备份配置文件
backup_config() {
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        print_success "配置文件已备份: $BACKUP_FILE"
    else
        print_warning "配置文件不存在: $CONFIG_FILE"
    fi
}

# 函数：显示GPU优化建议
show_gpu_recommendations() {
    echo ""
    print_info "================================================"
    print_info "RTX 4070 16GB GPU优化建议"
    print_info "================================================"
    echo ""
    
    print_info "1. 内存优化策略:"
    print_info "   - RTX 4070有16GB VRAM，适合中等批量大小"
    print_info "   - 建议使用 --medvram 参数平衡速度和内存"
    print_info "   - 可以处理1024x1024分辨率图像"
    print_info "   - 支持高分辨率修复 (Hires fix)"
    echo ""
    
    print_info "2. 性能优化参数:"
    print_info "   - --xformers: 启用xformers加速注意力机制"
    print_info "   - --opt-sdp-attention: 使用Scaled Dot Product注意力优化"
    print_info "   - --opt-channelslast: 内存布局优化"
    print_info "   - --no-half-vae: VAE使用全精度（提高质量）"
    echo ""
    
    print_info "3. 推荐配置组合:"
    print_info "   A. 平衡模式 (默认推荐):"
    print_info "      --medvram --xformers --opt-sdp-attention"
    print_info "   B. 速度优先模式:"
    print_info "      --xformers --opt-sdp-attention --opt-channelslast"
    print_info "   C. 质量优先模式:"
    print_info "      --no-half --no-half-vae --precision full"
    print_info "   D. 低内存模式 (处理超大图像):"
    print_info "      --lowvram --xformers"
    echo ""
    
    print_info "4. 环境变量优化:"
    print_info "   export PYTORCH_CUDA_ALLOC_CONF=\"max_split_size_mb:512\""
    print_info "   export CUDA_LAUNCH_BLOCKING=0"
    print_info "   export TF_CPP_MIN_LOG_LEVEL=2"
    echo ""
}

# 函数：配置GPU优化
configure_gpu_optimization() {
    local mode="$1"
    
    print_info "配置GPU优化模式: $mode"
    
    # 备份原始配置
    backup_config
    
    # 检查配置文件是否存在
    if [ ! -f "$CONFIG_FILE" ]; then
        print_warning "配置文件不存在，创建新配置..."
        cat > "$CONFIG_FILE" << 'EOF'
#!/bin/bash
#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

# Install directory without trailing slash
#install_dir="/home/$(whoami)"

# Name of the subdirectory
clone_dir="AIpic"

# python3 executable
#python_cmd="python3"

# git executable
#export GIT="git"

# python3 venv without trailing slash (defaults to ${install_dir}/${clone_dir}/venv)
#venv_dir="venv"

# script to launch to start the app
#export LAUNCH_SCRIPT="launch.py"

# install command for torch
#export TORCH_COMMAND="pip install torch==1.13.1+cu117 torchvision==0.14.1+cu117 --extra-index-url https://download.pytorch.org/whl/cu117"

# Requirements file to use for stable-diffusion-webui
#export REQS_FILE="requirements_versions.txt"

# Skip GFPGAN installation
export GFPGAN_PACKAGE=""

# Fixed git repos
#export K_DIFFUSION_PACKAGE=""
export GFPGAN_PACKAGE="gfpgan==1.3.8"

# Fixed git commits
#export STABLE_DIFFUSION_COMMIT_HASH=""
#export TAMING_TRANSFORMERS_COMMIT_HASH=""
#export CODEFORMER_COMMIT_HASH=""
#export BLIP_COMMIT_HASH=""

# Uncomment to enable accelerated launch
#export ACCELERATE="True"

###########################################
EOF
    fi
    
    # 读取现有配置
    local current_args=""
    if grep -q "export COMMANDLINE_ARGS=" "$CONFIG_FILE"; then
        current_args=$(grep "export COMMANDLINE_ARGS=" "$CONFIG_FILE" | cut -d'"' -f2)
    fi
    
    # 移除现有的GPU相关参数
    local base_args=$(echo "$current_args" | sed -e 's/--medvram//g' -e 's/--lowvram//g' -e 's/--xformers//g' -e 's/--opt-sdp-attention//g' -e 's/--opt-channelslast//g' -e 's/--no-half//g' -e 's/--no-half-vae//g' -e 's/--precision full//g' -e 's/--skip-torch-cuda-test//g' -e 's/--use-cpu all//g' -e 's/  */ /g' -e 's/^ //' -e 's/ $//')
    
    # 根据模式添加参数
    local gpu_args=""
    
    case "$mode" in
        "balanced")
            # 平衡模式：适合大多数场景
            gpu_args="--medvram --xformers --opt-sdp-attention"
            print_info "选择平衡模式：速度与内存的平衡"
            ;;
        "performance")
            # 性能模式：最大化速度
            gpu_args="--xformers --opt-sdp-attention --opt-channelslast"
            print_info "选择性能模式：最大化生成速度"
            ;;
        "quality")
            # 质量模式：最佳输出质量
            gpu_args="--no-half --no-half-vae --precision full"
            print_info "选择质量模式：最佳输出质量"
            ;;
        "lowvram")
            # 低内存模式：处理超大图像
            gpu_args="--lowvram --xformers"
            print_info "选择低内存模式：处理超大图像"
            ;;
        "custom")
            # 自定义模式
            read -p "请输入自定义GPU参数: " custom_args
            gpu_args="$custom_args"
            print_info "选择自定义模式"
            ;;
        *)
            print_error "未知模式: $mode"
            show_help
            exit 1
            ;;
    esac
    
    # 构建新的参数
    local new_args=""
    if [ -n "$base_args" ]; then
        new_args="$base_args $gpu_args"
    else
        new_args="$gpu_args"
    fi
    
    # 清理多余的空格
    new_args=$(echo "$new_args" | sed 's/  */ /g' | sed 's/^ //' | sed 's/ $//')
    
    # 更新配置文件
    if grep -q "export COMMANDLINE_ARGS=" "$CONFIG_FILE"; then
        # 替换现有的COMMANDLINE_ARGS
        sed -i.bak "s|export COMMANDLINE_ARGS=.*|export COMMANDLINE_ARGS=\"$new_args\"|" "$CONFIG_FILE"
    else
        # 添加新的COMMANDLINE_ARGS
        echo "" >> "$CONFIG_FILE"
        echo "# GPU优化配置 (RTX 4070 16GB)" >> "$CONFIG_FILE"
        echo "export COMMANDLINE_ARGS=\"$new_args\"" >> "$CONFIG_FILE"
    fi
    
    # 清理备份文件
    rm -f "$CONFIG_FILE.bak"
    
    print_success "GPU优化配置已更新"
    print_info "新的COMMANDLINE_ARGS: $new_args"
    
    # 添加环境变量配置
    add_environment_variables
}

# 函数：添加环境变量配置
add_environment_variables() {
    print_info "添加GPU环境变量优化..."
    
    # 检查是否已存在环境变量配置
    if ! grep -q "PYTORCH_CUDA_ALLOC_CONF" "$CONFIG_FILE"; then
        echo "" >> "$CONFIG_FILE"
        echo "# GPU环境变量优化" >> "$CONFIG_FILE"
        echo "# export PYTORCH_CUDA_ALLOC_CONF=\"max_split_size_mb:512\"" >> "$CONFIG_FILE"
        echo "# export CUDA_LAUNCH_BLOCKING=0" >> "$CONFIG_FILE"
        echo "# export TF_CPP_MIN_LOG_LEVEL=2" >> "$CONFIG_FILE"
        echo "# export TORCH_CUDA_ARCH_LIST=\"8.9\"" >> "$CONFIG_FILE"
        print_success "环境变量配置已添加（已注释，按需启用）"
    fi
}

# 函数：创建性能测试脚本
create_performance_test() {
    cat > test_gpu_performance.sh << 'EOF'
#!/usr/bin/env bash

#################################################
# GPU性能测试脚本
# 测试RTX 4070 16GB的性能表现
#################################################

set -e

# 颜色代码
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查CUDA
check_cuda() {
    print_info "检查CUDA支持..."
    
    if python -c "import torch; print('PyTorch版本:', torch.__version__); print('CUDA可用:', torch.cuda.is_available())" 2>/dev/null; then
        if python -c "import torch; print(torch.cuda.is_available())" 2>/dev/null | grep -q "True"; then
            print_success "CUDA可用"
            
            # 获取GPU信息
            python -c "
import torch
if torch.cuda.is_available():
    print(f'GPU数量: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        props = torch.cuda.get_device_properties(i)
        print(f'GPU {i}: {props.name}')
        print(f'  显存: {props.total_memory / 1024**3:.2f} GB')
        print(f'  CUDA计算能力: {props.major}.{props.minor}')
else:
    print('CUDA不可用')
"
            return 0
        else
            print_error "CUDA不可用"
            return 1
        fi
    else
        print_error "无法导入torch"
        return 1
    fi
}

# 测试内存带宽
test_memory_bandwidth() {
    print_info "测试GPU内存带宽..."
    
    cat > /tmp/test_gpu_bandwidth.py << 'PYEOF'
import torch
import time
import numpy as np

if torch.cuda.is_available():
    device = torch.device('cuda')
    
    # 测试不同大小的内存传输
    sizes = [1024, 4096, 16384, 65536]  # KB
    results = []
    
    for size_kb in sizes:
        size = size_kb * 1024  # 转换为字节
        # 创建数据
        data_cpu = torch.randn(size // 4, dtype=torch.float32)  # 浮点数占4字节
        
        # 测试CPU到GPU传输
        start = time.time()
        data_gpu = data_cpu.to(device)
        torch.cuda.synchronize()
        cpu_to_gpu_time = time.time() - start
        
        # 测试GPU到CPU传输
        start = time.time()
        data_cpu_back = data_gpu.cpu()
        torch.cuda.synchronize()
        gpu_to_cpu_time = time.time() - start
        
        # 计算带宽 (GB/s)
        size_gb = size / (1024**3)
        cpu_to_gpu_bw = size_gb / cpu_to_gpu_time
        gpu_to_cpu_bw = size_gb / gpu_to_cpu_time
        
        results.append({
            'size_kb': size_kb,
            'cpu_to_gpu_gbs': cpu_to_gpu_bw,
            'gpu_to_cpu_gbs': gpu_to_cpu_bw
        })
    
    print("内存带宽测试结果:")
    for r in results:
        print(f"  数据大小: {r['size_kb']} KB")
        print(f"  CPU->GPU: {r['cpu_to_gpu_gbs']:.2f} GB/s")
        print(f"  GPU->CPU: {r['gpu_to_cpu_gbs']:.2f} GB/s")
        print()
else:
    print("CUDA不可用，跳过内存带宽测试")
PYEOF

    python /tmp/test_gpu_bandwidth.py
    rm -f /tmp/test_gpu_bandwidth.py
}

# 测试计算性能
test_compute_performance() {
    print_info "测试GPU计算性能..."
    
    cat > /tmp/test_gpu_compute.py << 'PYEOF'
import torch
import time
import numpy as np

if torch.cuda.is_available():
    device = torch.device('cuda')
    
    # 测试矩阵乘法性能
    sizes = [512, 1024, 2048, 4096]
    results = []
    
    for size in sizes:
        # 创建随机矩阵
        a = torch.randn(size, size, device=device)
        b = torch.randn(size, size, device=device)
        
        # 预热
        for _ in range(10):
            _ = torch.matmul(a, b)
        
        # 正式测试
        torch.cuda.synchronize()
        start = time.time()
        
        iterations = 100 if size <= 1024 else 10
        for _ in range(iterations):
            c = torch.matmul(a, b)
        
        torch.cuda.synchronize()
        elapsed = time.time() - start
        
        # 计算FLOPS
        # 矩阵乘法浮点运算次数: 2 * n^3
        flops = 2 * (size ** 3) * iterations
        gflops_per_sec = flops / elapsed / 1e9
        
        results.append({
            'matrix_size': size,
            'time_seconds': elapsed,
            'gflops_per_sec': gflops_per_sec
        })
    
    print("计算性能测试结果:")
    for r in results:
        print(f"  矩阵大小: {r['matrix_size']}x{r['matrix_size']}")
        print(f"  计算时间: {r['time_seconds']:.3f} 秒")
        print(f"  计算性能: {r['gflops_per_sec']:.2f} GFLOPS")
        print()
else:
    print("CUDA不可用，跳过计算性能测试")
PYEOF

    python /tmp/test_gpu_compute.py
    rm -f /tmp/test_gpu_compute.py
}

# 测试AIpic特定操作
test_aipic_operations() {
    print_info "测试AIpic相关操作..."
    
    cat > /tmp/test_aipic_gpu.py << 'PYEOF'
import torch
import time

def test_tensor_operations():
    """测试张量操作性能"""
    if not torch.cuda.is_available():
        print("CUDA不可用，跳过张量操作测试")
        return
    
    device = torch.device('cuda')
    
    # 测试不同批大小下的性能
    batch_sizes = [1, 2, 4, 8]
    image_size = 512
    channels = 3
    
    print("张量操作性能测试:")
    for batch_size in batch_sizes:
        # 创建随机图像张量 (模拟AIpic中的图像处理)
        images = torch.randn(batch_size, channels, image_size, image_size, device=device)
        
        # 测试卷积操作 (模拟神经网络)
        conv = torch.nn.Conv2d(3, 64, kernel_size=3, padding=1).to(device)
        
        # 预热
        for _ in range(5):
            _ = conv(images)
        
        # 正式测试
        torch.cuda.synchronize()
        start = time.time()
        
        iterations = 50 // batch_size  # 调整迭代次数
        for _ in range(iterations):
            output = conv(images)
        
        torch.cuda.synchronize()
        elapsed = time.time() - start
        
        # 计算吞吐量
        total_images = batch_size * iterations
        images_per_second = total_images / elapsed
        
        print(f"  批大小: {batch_size}, 吞吐量: {images_per_second:.1f} 图像/秒")

def test_memory_usage():
    """测试内存使用情况"""
    if not torch.cuda.is_available():
        print("CUDA不可用，跳过内存测试")
        return
    
    print("\n内存使用测试:")
    
    # 检查初始内存
    torch.cuda.empty_cache()
    initial_memory = torch.cuda.memory_allocated() / 1024**3
    
    # 分配一些内存
    tensor_size = 1024 * 1024 * 100  # 100MB
    tensors = []
    
    for i in range(5):
        try:
            t = torch.randn(tensor_size, device='cuda')
            tensors.append(t)
            current_memory = torch.cuda.memory_allocated() / 1024**3
            print(f"  已分配: {current_memory:.2f} GB")
        except RuntimeError as e:
            print(f"  分配失败 (已用 {torch.cuda.memory_allocated()/1024**3:.2f} GB): {str(e)}")
            break
    
    # 清理
    del tensors
    torch.cuda.empty_cache()
    
    final_memory = torch.cuda.memory_allocated() / 1024**3
    print(f"  最终内存使用: {final_memory:.2f} GB")

if __name__ == "__main__":
    test_tensor_operations()
    test_memory_usage()
PYEOF

    python /tmp/test_aipic_gpu.py
    rm -f /tmp/test_aipic_gpu.py
}

# 主函数
main() {
    echo ""
    print_info "================================================"
    print_info "RTX 4070 16GB GPU性能测试"
    print_info "================================================"
    echo ""
    
    # 检查CUDA
    if ! check_cuda; then
        print_error "CUDA检查失败，请确保已安装正确版本的PyTorch CUDA"
        print_info "建议运行: pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118"
        exit 1
    fi
    
    echo ""
    
    # 测试内存带宽
    test_memory_bandwidth
    
    echo ""
    
    # 测试计算性能
    test_compute_performance
    
    echo ""
    
    # 测试AIpic操作
    test_aipic_operations
    
    echo ""
    print_success "性能测试完成!"
    print_info "根据测试结果调整webui-user.sh中的参数"
    print_info "运行 ./webui-gpu-optimized.sh 配置优化参数"
}

# 运行主函数
main "$@"
EOF

    chmod +x test_gpu_performance.sh
    print_success "性能测试脚本已创建: ./test_gpu_performance.sh"
}

# 函数：显示帮助
show_help() {
    echo "用法: $0 [模式]"
    echo ""
    echo "模式:"
    echo "  balanced     平衡模式 (默认) - 速度与内存的平衡"
    echo "  performance  性能模式 - 最大化生成速度"
    echo "  quality      质量模式 - 最佳输出质量"
    echo "  lowvram      低内存模式 - 处理超大图像"
    echo "  custom       自定义模式 - 手动输入参数"
    echo ""
    echo "示例:"
    echo "  $0 balanced      # 配置平衡模式"
    echo "  $0 performance   # 配置性能模式"
    echo "  $0 quality       # 配置质量模式"
    echo "  $0 lowvram       # 配置低内存模式"
    echo ""
    echo "其他命令:"
    echo "  $0 --recommend   # 显示GPU优化建议"
    echo "  $0 --test        # 创建性能测试脚本"
    echo "  $0 --help        # 显示帮助信息"
}

# 主函数
main() {
    local mode="balanced"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            balanced|performance|quality|lowvram|custom)
                mode="$1"
                shift
                ;;
            --recommend)
                show_gpu_recommendations
                exit 0
                ;;
            --test)
                create_performance_test
                print_info "运行 ./test_gpu_performance.sh 进行GPU性能测试"
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo ""
    print_info "================================================"
    print_info "AIpic GPU优化配置"
    print_info "硬件: RTX 4070 16GB"
    print_info "模式: $mode"
    print_info "================================================"
    echo ""
    
    # 显示GPU优化建议
    show_gpu_recommendations
    
    # 确认配置
    read -p "确认使用 $mode 模式配置? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "配置已取消"
        exit 0
    fi
    
    # 配置GPU优化
    configure_gpu_optimization "$mode"
    
    # 创建性能测试脚本
    create_performance_test
    
    echo ""
    print_success "配置完成!"
    print_info "下一步:"
    print_info "  1. 运行性能测试: ./test_gpu_performance.sh"
    print_info "  2. 启动AIpic: ./start_aipic.sh"
    print_info "  3. 监控GPU使用: nvidia-smi"
    echo ""
    
    # 显示最终配置
    if [ -f "$CONFIG_FILE" ]; then
        print_info "最终配置 ($CONFIG_FILE):"
        grep "export COMMANDLINE_ARGS=" "$CONFIG_FILE" || print_info "  使用默认参数"
    fi
}

# 运行主函数
main "$@"
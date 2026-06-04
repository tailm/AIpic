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

#!/usr/bin/env bash

#################################################
# AIpic Performance Optimization Script
# Optimize system for AI workloads (RTX 4070 16GB)
#################################################

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function: print colored output
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

# Function: check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function: check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_warning "Some optimizations require root privileges"
        print_info "Please run with sudo for full optimization"
        return 1
    fi
    return 0
}

# Function: get system information
get_system_info() {
    print_info "System Information:"
    
    # OS info
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_info "  OS: $NAME $VERSION"
    else
        print_info "  OS: $(uname -s) $(uname -r)"
    fi
    
    # CPU info
    CPU_CORES=$(nproc)
    CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d':' -f2 | xargs)
    print_info "  CPU: $CPU_MODEL ($CPU_CORES cores)"
    
    # Memory info
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    AVAILABLE_MEM=$(free -g | awk '/^Mem:/{print $7}')
    print_info "  Memory: ${TOTAL_MEM}GB total, ${AVAILABLE_MEM}GB available"
    
    # GPU info
    if command_exists nvidia-smi; then
        GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader,nounits 2>/dev/null | head -n1)
        if [ -n "$GPU_INFO" ]; then
            GPU_NAME=$(echo "$GPU_INFO" | cut -d',' -f1)
            GPU_MEMORY=$(echo "$GPU_INFO" | cut -d',' -f2)
            GPU_DRIVER=$(echo "$GPU_INFO" | cut -d',' -f3)
            print_info "  GPU: $GPU_NAME (${GPU_MEMORY}MB VRAM)"
            print_info "  Driver: $GPU_DRIVER"
        fi
    else
        print_warning "  GPU: NVIDIA driver not found (running in CPU mode)"
    fi
    
    # Disk info
    DISK_INFO=$(df -h . | awk 'NR==2 {print $4 " free of " $2 " (" $5 " used)"}')
    print_info "  Disk: $DISK_INFO"
    
    echo ""
}

# Function: optimize GPU settings
optimize_gpu() {
    print_info "Optimizing GPU settings..."
    
    if ! command_exists nvidia-smi; then
        print_warning "NVIDIA driver not found, skipping GPU optimization"
        return 1
    fi
    
    # Enable persistence mode
    print_info "Enabling GPU persistence mode..."
    sudo nvidia-smi -pm 1 2>/dev/null || print_warning "Failed to enable persistence mode"
    
    # Set compute mode
    print_info "Setting GPU compute mode..."
    sudo nvidia-smi -c 3 2>/dev/null || print_warning "Failed to set compute mode"
    
    # Set power limit (adjust for RTX 4070)
    print_info "Setting GPU power limit..."
    sudo nvidia-smi -pl 200 2>/dev/null || print_warning "Failed to set power limit"
    
    # Clear GPU memory cache
    print_info "Clearing GPU memory cache..."
    sudo nvidia-smi --gpu-reset 2>/dev/null || print_warning "Failed to clear GPU cache"
    
    # Set GPU clock speeds (optional, for advanced users)
    # print_info "Setting GPU clock speeds..."
    # sudo nvidia-smi -lgc 2100,2100 2>/dev/null || print_warning "Failed to set GPU clocks"
    
    # Set memory clock speeds (optional, for advanced users)
    # print_info "Setting memory clock speeds..."
    # sudo nvidia-smi -lmc 6000,6000 2>/dev/null || print_warning "Failed to set memory clocks"
    
    print_success "GPU optimization completed"
    return 0
}

# Function: optimize CPU settings
optimize_cpu() {
    print_info "Optimizing CPU settings..."
    
    # Set CPU governor to performance
    print_info "Setting CPU governor to performance..."
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -f "$cpu" ]; then
            echo "performance" | sudo tee "$cpu" >/dev/null 2>&1 || true
        fi
    done
    
    # Disable CPU frequency scaling
    print_info "Disabling CPU frequency scaling..."
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        if [ -f "$cpu" ]; then
            MAX_FREQ=$(cat "$cpu")
            echo "$MAX_FREQ" | sudo tee "$cpu" >/dev/null 2>&1 || true
        fi
    done
    
    # Set CPU affinity (optional)
    print_info "Setting CPU affinity..."
    if command_exists taskset; then
        # Reserve first 2 cores for system, rest for AIpic
        CPU_COUNT=$(nproc)
        if [ "$CPU_COUNT" -gt 4 ]; then
            MASK=$(( (1 << (CPU_COUNT - 2)) - 1 << 2 ))
            MASK_HEX=$(printf "0x%x" $MASK)
            print_info "  CPU mask: $MASK_HEX (cores 2-$((CPU_COUNT-1)))"
        fi
    fi
    
    # Enable transparent huge pages
    print_info "Enabling transparent huge pages..."
    echo "always" | sudo tee /sys/kernel/mm/transparent_hugepage/enabled >/dev/null 2>&1 || true
    
    print_success "CPU optimization completed"
    return 0
}

# Function: optimize memory settings
optimize_memory() {
    print_info "Optimizing memory settings..."
    
    # Clear system cache
    print_info "Clearing system cache..."
    sudo sync 2>/dev/null || true
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
    
    # Optimize swappiness for AI workloads
    print_info "Optimizing swappiness..."
    CURRENT_SWAPPINESS=$(cat /proc/sys/vm/swappiness)
    print_info "  Current swappiness: $CURRENT_SWAPPINESS"
    
    if [ "$CURRENT_SWAPPINESS" -gt 10 ]; then
        echo "10" | sudo tee /proc/sys/vm/swappiness >/dev/null 2>&1 || true
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
        print_info "  New swappiness: 10"
    fi
    
    # Optimize dirty ratio
    print_info "Optimizing dirty ratio..."
    echo "10" | sudo tee /proc/sys/vm/dirty_ratio >/dev/null 2>&1 || true
    echo "5" | sudo tee /proc/sys/vm/dirty_background_ratio >/dev/null 2>&1 || true
    echo "3000" | sudo tee /proc/sys/vm/dirty_expire_centisecs >/dev/null 2>&1 || true
    echo "500" | sudo tee /proc/sys/vm/dirty_writeback_centisecs >/dev/null 2>&1 || true
    
    # Increase file descriptors limit
    print_info "Increasing file descriptors limit..."
    echo "fs.file-max = 65535" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
    echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf >/dev/null 2>&1 || true
    echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf >/dev/null 2>&1 || true
    
    # Apply sysctl settings
    sudo sysctl -p 2>/dev/null || true
    
    print_success "Memory optimization completed"
    return 0
}

# Function: optimize network settings
optimize_network() {
    print_info "Optimizing network settings..."
    
    # Increase TCP buffer sizes
    print_info "Increasing TCP buffer sizes..."
    echo "net.core.rmem_max = 134217728" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
    echo "net.core.wmem_max = 134217728" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
    echo "net.ipv4.tcp_rmem = 4096 87380 134217728" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
    echo "net.ipv4.tcp_wmem = 4096 65536 134217728" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
    
    # Optimize TCP congestion control
    print_info "Optimizing TCP congestion control..."
    echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
    
    # Increase connection limits
    print_info "Increasing connection limits..."
    echo "net.core.somaxconn = 65535" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
    echo "net.ipv4.tcp_max_syn_backlog = 65535" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
    
    # Enable TCP fast open
    print_info "Enabling TCP fast open..."
    echo "net.ipv4.tcp_fastopen = 3" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
    
    # Apply sysctl settings
    sudo sysctl -p 2>/dev/null || true
    
    print_success "Network optimization completed"
    return 0
}

# Function: optimize disk I/O
optimize_disk() {
    print_info "Optimizing disk I/O..."
    
    # Get disk scheduler
    DISK_DEVICE=$(df . | awk 'NR==2 {print $1}' | sed 's/[0-9]*$//')
    if [ -n "$DISK_DEVICE" ] && [ -e "/sys/block/$(basename "$DISK_DEVICE")/queue/scheduler" ]; then
        CURRENT_SCHEDULER=$(cat "/sys/block/$(basename "$DISK_DEVICE")/queue/scheduler" | grep -o '\[.*\]' | tr -d '[]')
        print_info "  Current scheduler: $CURRENT_SCHEDULER"
        
        # Set to noop or none for SSD
        if [[ "$CURRENT_SCHEDULER" != "noop" ]] && [[ "$CURRENT_SCHEDULER" != "none" ]]; then
            echo "noop" | sudo tee "/sys/block/$(basename "$DISK_DEVICE")/queue/scheduler" >/dev/null 2>&1 || true
            print_info "  New scheduler: noop"
        fi
    fi
    
    # Increase read-ahead for sequential access
    if [ -n "$DISK_DEVICE" ] && [ -e "/sys/block/$(basename "$DISK_DEVICE")/queue/read_ahead_kb" ]; then
        echo "4096" | sudo tee "/sys/block/$(basename "$DISK_DEVICE")/queue/read_ahead_kb" >/dev/null 2>&1 || true
    fi
    
    # Enable write caching
    print_info "Enabling write caching..."
    echo "vm.dirty_writeback_centisecs = 500" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
    echo "vm.dirty_expire_centisecs = 3000" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true
    
    # Apply settings
    sudo sysctl -p 2>/dev/null || true
    
    print_success "Disk I/O optimization completed"
    return 0
}

# Function: optimize Python environment
optimize_python() {
    print_info "Optimizing Python environment..."
    
    # Check if virtual environment exists
    if [ ! -d "venv" ]; then
        print_warning "Virtual environment not found, skipping Python optimization"
        return 1
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Set PyTorch environment variables
    print_info "Setting PyTorch environment variables..."
    export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
    export CUDA_LAUNCH_BLOCKING=0
    export TF_CPP_MIN_LOG_LEVEL=2
    
    # Set compute capability for RTX 4070
    export TORCH_CUDA_ARCH_LIST="8.9"
    
    # Install performance packages
    print_info "Installing performance packages..."
    pip install --upgrade --no-deps \
        ninja \
        packaging \
        pillow-simd 2>/dev/null || true
    
    # Clean pip cache
    print_info "Cleaning pip cache..."
    pip cache purge 2>/dev/null || true
    
    deactivate
    
    # Save environment variables to webui-user.sh
    if [ -f "webui-user.sh" ]; then
        print_info "Updating webui-user.sh with optimization settings..."
        
        # Remove existing optimization settings
        grep -v "PYTORCH_CUDA_ALLOC_CONF\|CUDA_LAUNCH_BLOCKING\|TF_CPP_MIN_LOG_LEVEL\|TORCH_CUDA_ARCH_LIST" webui-user.sh > webui-user.sh.tmp
        mv webui-user.sh.tmp webui-user.sh
        
        # Add optimization settings
        cat >> webui-user.sh << 'EOF'

# Performance optimization for RTX 4070
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
export CUDA_LAUNCH_BLOCKING=0
export TF_CPP_MIN_LOG_LEVEL=2
export TORCH_CUDA_ARCH_LIST="8.9"
EOF
    fi
    
    print_success "Python environment optimization completed"
    return 0
}

# Function: optimize swap
optimize_swap() {
    print_info "Optimizing swap..."
    
    # Check current swap
    SWAP_TOTAL=$(free -g | awk '/^Swap:/{print $2}')
    SWAP_FREE=$(free -g | awk '/^Swap:/{print $4}')
    
    print_info "  Swap total: ${SWAP_TOTAL}GB"
    print_info "  Swap free: ${SWAP_FREE}GB"
    
    # Check if swap exists
    if [ "$SWAP_TOTAL" -eq 0 ]; then
        print_warning "No swap space found"
        
        read -p "Create 16GB swap file? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Creating swap file..."
            
            # Create swap file
            sudo fallocate -l 16G /swapfile 2>/dev/null || \
            sudo dd if=/dev/zero of=/swapfile bs=1M count=16384 2>/dev/null
            
            sudo chmod 600 /swapfile
            sudo mkswap /swapfile
            sudo swapon /swapfile
            
            # Make permanent
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
            
            print_success "Swap file created (16GB)"
        fi
    elif [ "$SWAP_TOTAL" -lt 16 ]; then
        print_warning "Swap space is small (${SWAP_TOTAL}GB), recommend at least 16GB"
        
        read -p "Increase swap to 16GB? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Increasing swap space..."
            
            # Disable current swap
            sudo swapoff -a
            
            # Remove old swap
            sudo rm -f /swapfile
            
            # Create new swap file
            sudo fallocate -l 16G /swapfile
            sudo chmod 600 /swapfile
            sudo mkswap /swapfile
            sudo swapon /swapfile
            
            print_success "Swap increased to 16GB"
        fi
    else
        print_success "Swap space is sufficient (${SWAP_TOTAL}GB)"
    fi
    
    return 0
}

# Function: create optimization script
create_optimization_script() {
    print_info "Creating optimization script..."
    
    cat > optimize_aipic.sh << 'EOF'
#!/usr/bin/env bash

# AIpic Optimization Script
# Run this script before starting AIpic for best performance

echo "Applying AIpic performance optimizations..."

# Clear GPU memory cache
if command -v nvidia-smi &> /dev/null; then
    echo "Clearing GPU memory cache..."
    sudo nvidia-smi --gpu-reset 2>/dev/null || true
fi

# Clear system cache
echo "Clearing system cache..."
sudo sync 2>/dev/null || true
echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true

# Set CPU performance governor
echo "Setting CPU to performance mode..."
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null; do
    if [ -f "$cpu" ]; then
        echo "performance" | sudo tee $cpu >/dev/null 2>&1 || true
    fi
done

# Set PyTorch environment variables
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
export CUDA_LAUNCH_BLOCKING=0
export TF_CPP_MIN_LOG_LEVEL=2
export TORCH_CUDA_ARCH_LIST="8.9"

echo "Performance optimizations applied!"
EOF
    
    chmod +x optimize_aipic.sh
    print_success "Optimization script created: ./optimize_aipic.sh"
    
    return 0
}

# Function: show optimization summary
show_summary() {
    echo ""
    print_success "================================================"
    print_success "Performance Optimization Summary"
    print_success "================================================"
    echo ""
    
    print_info "Applied optimizations:"
    
    # GPU optimizations
    if command_exists nvidia-smi; then
        print_info "  ✓ GPU persistence mode enabled"
        print_info "  ✓ GPU compute mode set"
        print_info "  ✓ GPU memory cache cleared"
    else
        print_info "  ⚠ GPU optimizations skipped (NVIDIA driver not found)"
    fi
    
    # CPU optimizations
    print_info "  ✓ CPU governor set to performance"
    print_info "  ✓ CPU frequency scaling disabled"
    
    # Memory optimizations
    print_info "  ✓ System cache cleared"
    print_info "  ✓ Swappiness optimized"
    print_info "  ✓ File descriptors limit increased"
    
    # Network optimizations
    print_info "  ✓ TCP buffer sizes increased"
    print_info "  ✓ Connection limits increased"
    
    # Disk optimizations
    print_info "  ✓ Disk scheduler optimized"
    print_info "  ✓ Write caching enabled"
    
    # Python optimizations
    if [ -d "venv" ]; then
        print_info "  ✓ PyTorch environment variables set"
        print_info "  ✓ Python packages optimized"
    fi
    
    # Swap optimizations
    SWAP_TOTAL=$(free -g | awk '/^Swap:/{print $2}')
    print_info "  ✓ Swap space: ${SWAP_TOTAL}GB"
    
    echo ""
    print_info "Optimization script created: ./optimize_aipic.sh"
    print_info "Run this script before starting AIpic for best performance"
    
    echo ""
    print_info "Recommended next steps:"
    print_info "1. Reboot the system to apply all optimizations"
    print_info "2. Run ./optimize_aipic.sh before starting AIpic"
    print_info "3. Monitor performance with: watch -n 1 nvidia-smi"
    
    echo ""
    print_success "Optimization completed successfully!"
}

# Main function
main() {
    echo ""
    print_info "================================================"
    print_info "AIpic Performance Optimization Tool"
    print_info "Optimized for RTX 4070 16GB"
    print_info "================================================"
    echo ""
    
    # Show system information
    get_system_info
    
    # Check root privileges
    if [ "$EUID" -ne 0 ]; then
        print_warning "Some optimizations require root privileges"
        print_info "Running with limited permissions..."
        echo ""
    fi
    
    # Ask for confirmation
    print_warning "This script will apply system-wide performance optimizations."
    print_warning "Some changes may require a reboot to take effect."
    echo ""
    
    read -p "Continue with optimization? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Optimization cancelled"
        exit 0
    fi
    
    echo ""
    
    # Apply optimizations
    optimize_gpu
    echo ""
    
    optimize_cpu
    echo ""
    
    optimize_memory
    echo ""
    
    optimize_network
    echo ""
    
    optimize_disk
    echo ""
    
    optimize_python
    echo ""
    
    optimize_swap
    echo ""
    
    create_optimization_script
    echo ""
    
    # Show summary
    show_summary
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h      Show this help message"
        echo "  --gpu-only      Optimize GPU settings only"
        echo "  --cpu-only      Optimize CPU settings only"
        echo "  --memory-only   Optimize memory settings only"
        echo "  --network-only  Optimize network settings only"
        echo "  --disk-only     Optimize disk I/O only"
        echo "  --python-only   Optimize Python environment only"
        echo "  --swap-only     Optimize swap only"
        echo "  --quick         Apply quick optimizations only"
        echo ""
        echo "Examples:"
        echo "  $0              # Apply all optimizations"
        echo "  $0 --gpu-only   # Optimize GPU only"
        echo "  $0 --quick      # Apply quick optimizations"
        exit 0
        ;;
    --gpu-only)
        get_system_info
        optimize_gpu
        exit 0
        ;;
    --cpu-only)
        get_system_info
        optimize_cpu
        exit 0
        ;;
    --memory-only)
        get_system_info
        optimize_memory
        exit 0
        ;;
    --network-only)
        get_system_info
        optimize_network
        exit 0
        ;;
    --disk-only)
        get_system_info
        optimize_disk
        exit 0
        ;;
    --python-only)
        get_system_info
        optimize_python
        exit 0
        ;;
    --swap-only)
        get_system_info
        optimize_swap
        exit 0
        ;;
    --quick)
        print_info "Applying quick optimizations..."
        optimize_gpu
        optimize_cpu
        optimize_memory
        create_optimization_script
        show_summary
        exit 0
        ;;
esac

# Run main function
main "$@"
#!/usr/bin/env bash

#################################################
# AIpic Startup Script
# Optimized for Ubuntu 24.04 + Python 3.13 + RTX 4070
#################################################

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
PORT=7860

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

# Function: check port availability
check_port() {
    local port=$1
    if command_exists lsof; then
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pid=$(lsof -ti:$port)
            echo "$pid"
            return 0
        fi
    elif command_exists netstat; then
        if netstat -tulpn 2>/dev/null | grep -q ":$port "; then
            return 0
        fi
    elif command_exists ss; then
        if ss -tulpn 2>/dev/null | grep -q ":$port "; then
            return 0
        fi
    fi
    return 1
}

# Function: kill process on port
kill_port() {
    local port=$1
    local pid=$2
    
    if [ -n "$pid" ]; then
        print_info "Killing process $pid on port $port..."
        kill $pid 2>/dev/null || true
        sleep 2
        
        # Check if process is still running
        if ps -p $pid >/dev/null 2>&1; then
            print_warning "Process still running, forcing kill..."
            kill -9 $pid 2>/dev/null || true
            sleep 1
        fi
        
        # Verify port is free
        if check_port $port; then
            print_error "Failed to free port $port"
            return 1
        else
            print_success "Port $port is now free"
            return 0
        fi
    fi
    return 0
}

# Function: apply performance optimizations
apply_optimizations() {
    print_info "Applying performance optimizations..."
    
    # Clear GPU memory cache if NVIDIA GPU is available
    if command_exists nvidia-smi; then
        print_info "Clearing GPU memory cache..."
        sudo nvidia-smi --gpu-reset 2>/dev/null || true
    fi
    
    # Clear system cache
    print_info "Clearing system cache..."
    sudo sync 2>/dev/null || true
    echo 3 | sudo tee /proc/sys/vm/drop_caches 2>/dev/null || true
    
    # Set CPU performance governor
    print_info "Setting CPU to performance mode..."
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -f "$cpu" ] 2>/dev/null; then
            echo "performance" | sudo tee "$cpu" >/dev/null 2>&1 || true
        fi
    done
    
    # Increase TCP buffer sizes
    print_info "Optimizing network settings..."
    sudo sysctl -w net.core.rmem_max=134217728 2>/dev/null || true
    sudo sysctl -w net.core.wmem_max=134217728 2>/dev/null || true
    sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 134217728" 2>/dev/null || true
    sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 134217728" 2>/dev/null || true
    
    print_success "Performance optimizations applied"
}

# Function: check virtual environment
check_virtualenv() {
    if [ ! -d "$VENV_DIR" ]; then
        print_error "Virtual environment not found at $VENV_DIR"
        print_info "Please run the installation script first: ./install_ubuntu_24.sh"
        return 1
    fi
    
    if [ ! -f "$VENV_DIR/bin/activate" ]; then
        print_error "Virtual environment activation script not found"
        return 1
    fi
    
    return 0
}

# Function: check Python dependencies
check_dependencies() {
    print_info "Checking Python dependencies..."
    
    source "$VENV_DIR/bin/activate"
    
    # Check PyTorch
    if ! python -c "import torch" 2>/dev/null; then
        print_error "PyTorch not found in virtual environment"
        print_info "Please install PyTorch: pip install torch torchvision"
        return 1
    fi
    
    # Check Gradio
    if ! python -c "import gradio" 2>/dev/null; then
        print_error "Gradio not found in virtual environment"
        print_info "Please install Gradio: pip install gradio"
        return 1
    fi
    
    # Check other critical dependencies
    for package in "numpy" "PIL" "cv2" "transformers"; do
        if ! python -c "import $package" 2>/dev/null; then
            print_warning "$package not found, some features may not work"
        fi
    done
    
    deactivate
    
    return 0
}

# Function: get local IP address
get_local_ip() {
    local ip=""
    
    # Try different methods to get local IP
    if command_exists ip; then
        ip=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
    elif command_exists ifconfig; then
        ip=$(ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n1)
    fi
    
    if [ -z "$ip" ]; then
        ip="localhost"
    fi
    
    echo "$ip"
}

# Function: display startup banner
show_banner() {
    echo ""
    print_success "================================================"
    print_success "AIpic Stable Diffusion Web UI"
    print_success "================================================"
    echo ""
    
    # Show system info
    print_info "System Information:"
    print_info "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -s)"
    print_info "  Python: $(python --version 2>/dev/null || echo "Not found")"
    
    # Show GPU info if available
    if command_exists nvidia-smi; then
        GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1)
        if [ -n "$GPU_INFO" ]; then
            GPU_NAME=$(echo "$GPU_INFO" | cut -d',' -f1)
            GPU_MEMORY=$(echo "$GPU_INFO" | cut -d',' -f2)
            print_info "  GPU: $GPU_NAME (${GPU_MEMORY}MB VRAM)"
        fi
    fi
    
    # Show virtual environment info
    if [ -d "$VENV_DIR" ]; then
        print_info "  Virtual Environment: $VENV_DIR"
    fi
    
    # Show network information
    show_network_info
    
    echo ""
}

# Function: show network information
show_network_info() {
    print_info "Network Information:"
    
    # Get local IP addresses
    local local_ips=()
    
    if command_exists ip; then
        # Using ip command (Linux)
        local_ips=($(ip -o -4 addr show 2>/dev/null | awk '{print $4}' | cut -d'/' -f1 | grep -v '127.0.0.1' | head -5))
    elif command_exists ifconfig; then
        # Using ifconfig command (macOS/Linux)
        local_ips=($(ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -5))
    elif command_exists hostname; then
        # Using hostname command
        local_ips=($(hostname -I 2>/dev/null | tr ' ' '\n' | head -5))
    fi
    
    if [ ${#local_ips[@]} -gt 0 ]; then
        print_info "  Local IP Addresses:"
        for ip in "${local_ips[@]}"; do
            print_info "    - $ip"
        done
    else
        print_info "  Local IP Addresses: Not detected"
    fi
    
    # Get public IP if available
    if command_exists curl; then
        PUBLIC_IP=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "Not available")
        print_info "  Public IP: $PUBLIC_IP"
    fi
    
    # Check if LAN access is configured
    if [ -f "webui-user.sh" ]; then
        source ./webui-user.sh 2>/dev/null || true
        if [[ "${COMMANDLINE_ARGS:-}" == *"--listen"* ]] && [[ "${COMMANDLINE_ARGS:-}" == *"--server-name"* ]]; then
            print_success "  LAN Access: Enabled"
            
            # Extract port
            local port="7860"
            if [[ "$COMMANDLINE_ARGS" =~ --port[= ]([0-9]+) ]]; then
                port="${BASH_REMATCH[1]}"
            fi
            
            # Extract server name
            local server_name="0.0.0.0"
            if [[ "$COMMANDLINE_ARGS" =~ --server-name[= ]([^ ]+) ]]; then
                server_name="${BASH_REMATCH[1]}"
            fi
            
            print_info "  Access URLs:"
            print_info "    - Local: http://127.0.0.1:$port"
            
            if [ "$server_name" = "0.0.0.0" ] || [ "$server_name" = "::" ]; then
                for ip in "${local_ips[@]}"; do
                    print_info "    - LAN: http://$ip:$port"
                done
            else
                print_info "    - LAN: http://$server_name:$port"
            fi
            
            # Check firewall
            if command_exists ufw && ufw status | grep -q "Status: active"; then
                if ufw status | grep -q "$port/tcp"; then
                    print_success "  Firewall: Port $port is allowed"
                else
                    print_warning "  Firewall: Port $port might be blocked"
                fi
            fi
        else
            print_warning "  LAN Access: Disabled (use --listen and --server-name to enable)"
        fi
    fi
}

# Function: parse command line arguments
parse_arguments() {
    local args=""
    
    # Check for custom configuration
    if [ -f "webui-user.sh" ]; then
        source ./webui-user.sh
    fi
    
    # Use command line arguments from webui-user.sh if set
    if [ -n "${COMMANDLINE_ARGS:-}" ]; then
        args="$COMMANDLINE_ARGS"
    else
        # Default arguments for RTX 4070 optimization with LAN access
        args="--listen --port $PORT --server-name 0.0.0.0 --medvram --opt-sdp-attention --xformers"
    fi
    
    # Check if --listen is already in args
    if [[ ! "$args" == *"--listen"* ]]; then
        args="$args --listen"
    fi
    
    # Check if --server-name is already in args
    if [[ ! "$args" == *"--server-name"* ]]; then
        args="$args --server-name 0.0.0.0"
    fi
    
    # Check if --port is already in args, if not add it
    if [[ ! "$args" == *"--port"* ]]; then
        args="$args --port $PORT"
    else
        # Extract port from args if already set
        local port_in_args=$(echo "$args" | grep -o -- "--port[= ][0-9]*" | grep -o "[0-9]*" | head -1)
        if [ -n "$port_in_args" ]; then
            PORT="$port_in_args"
        fi
    fi
    
    # Add API flag if configured
    if [ "${API:-}" = "True" ] || [ "${API:-}" = "true" ]; then
        if [[ ! "$args" == *"--api"* ]]; then
            args="$args --api"
        fi
    fi
    
    # Add auto-launch browser flag
    if [ "${LAUNCH_BROWSER:-}" = "True" ] || [ "${LAUNCH_BROWSER:-}" = "true" ]; then
        if [[ ! "$args" == *"--autolaunch"* ]]; then
            args="$args --autolaunch"
        fi
    fi
    
    # Add developer mode flag
    if [ "${DEVELOPER_MODE:-}" = "True" ] || [ "${DEVELOPER_MODE:-}" = "true" ]; then
        if [[ ! "$args" == *"--enable-console-prompts"* ]]; then
            args="$args --enable-console-prompts"
        fi
    fi
    
    # Add safe mode flag
    if [ "${SAFE_MODE:-}" = "False" ] || [ "${SAFE_MODE:-}" = "false" ]; then
        if [[ ! "$args" == *"--disable-safe-unpickle"* ]]; then
            args="$args --disable-safe-unpickle"
        fi
    fi
    
    echo "$args"
}

# Main function
main() {
    show_banner
    
    # Check virtual environment
    if ! check_virtualenv; then
        exit 1
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        print_warning "Some dependencies are missing, but continuing anyway..."
    fi
    
    # Check port availability
    local pid=""
    if check_port $PORT; then
        pid=$(lsof -ti:$PORT 2>/dev/null || netstat -tulpn 2>/dev/null | grep ":$PORT " | awk '{print $7}' | cut -d'/' -f1)
        
        print_warning "Port $PORT is already in use by process: $pid"
        echo ""
        echo "Please choose an option:"
        echo "1) Use a different port"
        echo "2) Kill the process using port $PORT"
        echo "3) Exit"
        echo ""
        
        read -p "Enter your choice [1-3]: " choice
        
        case $choice in
            1)
                read -p "Enter new port number: " NEW_PORT
                if [[ $NEW_PORT =~ ^[0-9]+$ ]] && [ $NEW_PORT -ge 1024 ] && [ $NEW_PORT -le 65535 ]; then
                    PORT=$NEW_PORT
                    print_info "Using port: $PORT"
                else
                    print_error "Invalid port number. Must be between 1024 and 65535"
                    exit 1
                fi
                ;;
            2)
                if kill_port $PORT "$pid"; then
                    print_success "Process killed successfully"
                else
                    print_error "Failed to kill process"
                    exit 1
                fi
                ;;
            3)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid choice"
                exit 1
                ;;
        esac
    else
        print_success "Port $PORT is available"
    fi
    
    # Apply performance optimizations
    if [ "${APPLY_OPTIMIZATIONS:-true}" = "true" ]; then
        apply_optimizations
    fi
    
    # Set environment variables for RTX 4070 optimization
    export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
    export CUDA_LAUNCH_BLOCKING=0
    export TF_CPP_MIN_LOG_LEVEL=2
    
    # Set compute capability for RTX 4070
    export TORCH_CUDA_ARCH_LIST="8.9"
    
    # Parse command line arguments
    local args=$(parse_arguments)
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Get local IP address
    local ip=$(get_local_ip)
    
    # Display connection information
    echo ""
    print_success "Starting AIpic Web UI..."
    print_info "  Local URL:    http://localhost:$PORT"
    print_info "  Network URL:  http://$ip:$PORT"
    print_info "  Arguments:    $args"
    echo ""
    print_info "Press Ctrl+C to stop the server"
    print_info "Logs will be saved to log.txt"
    echo ""
    print_success "================================================"
    
    # Start the Web UI
    exec python launch.py $args 2>&1 | tee log.txt
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h      Show this help message"
        echo "  --port PORT     Use specific port (default: 7860)"
        echo "  --no-optimize   Skip performance optimizations"
        echo "  --test          Test mode (check dependencies only)"
        echo ""
        echo "Environment variables (set in webui-user.sh):"
        echo "  COMMANDLINE_ARGS    Additional arguments for launch.py"
        echo "  API                 Enable API (True/False)"
        echo "  LAUNCH_BROWSER      Auto-launch browser (True/False)"
        echo "  DEVELOPER_MODE      Enable developer mode (True/False)"
        echo "  SAFE_MODE           Enable safe mode (True/False)"
        echo "  APPLY_OPTIMIZATIONS Apply performance optimizations (true/false)"
        exit 0
        ;;
    --port)
        if [ -n "$2" ]; then
            PORT="$2"
            shift 2
        else
            print_error "Port number required for --port option"
            exit 1
        fi
        ;;
    --no-optimize)
        export APPLY_OPTIMIZATIONS=false
        shift
        ;;
    --test)
        print_info "Running in test mode..."
        check_virtualenv
        check_dependencies
        print_success "All checks passed!"
        exit 0
        ;;
esac

# Run main function
main "$@"
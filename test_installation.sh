#!/usr/bin/env bash

#################################################
# AIpic 安装测试脚本
# 测试安装脚本的关键功能
#################################################

set -e

# 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        print_success "命令 $1 存在"
        return 0
    else
        print_error "命令 $1 不存在"
        return 1
    fi
}

# 函数：检查文件是否存在
check_file() {
    if [ -f "$1" ]; then
        print_success "文件 $1 存在"
        return 0
    else
        print_error "文件 $1 不存在"
        return 1
    fi
}

# 函数：检查目录是否存在
check_directory() {
    if [ -d "$1" ]; then
        print_success "目录 $1 存在"
        return 0
    else
        print_error "目录 $1 不存在"
        return 1
    fi
}

# 函数：测试Python环境
test_python_environment() {
    print_info "测试Python环境..."
    
    # 检查Python版本
    if command -v python3.13 >/dev/null 2>&1; then
        PYTHON_VERSION=$(python3.13 --version 2>&1)
        print_success "Python版本: $PYTHON_VERSION"
    else
        print_warning "Python 3.13 未安装，测试Python 3"
        if command -v python3 >/dev/null 2>&1; then
            PYTHON_VERSION=$(python3 --version 2>&1)
            print_info "Python版本: $PYTHON_VERSION"
        else
            print_error "Python 3 未安装"
            return 1
        fi
    fi
    
    # 检查pip
    if command -v pip3 >/dev/null 2>&1; then
        PIP_VERSION=$(pip3 --version 2>&1 | head -n1)
        print_success "pip版本: $PIP_VERSION"
    else
        print_error "pip 未安装"
        return 1
    fi
    
    return 0
}

# 函数：测试虚拟环境
test_virtual_environment() {
    print_info "测试虚拟环境..."
    
    if [ -d "venv" ]; then
        print_success "虚拟环境目录存在"
        
        # 检查激活脚本
        if [ -f "venv/bin/activate" ]; then
            print_success "虚拟环境激活脚本存在"
            
            # 测试Python路径
            VENV_PYTHON=$(venv/bin/python -c "import sys; print(sys.executable)" 2>/dev/null || true)
            if [[ "$VENV_PYTHON" == *"venv"* ]]; then
                print_success "虚拟环境Python路径正确: $VENV_PYTHON"
            else
                print_warning "虚拟环境Python路径可能不正确: $VENV_PYTHON"
            fi
        else
            print_error "虚拟环境激活脚本不存在"
            return 1
        fi
    else
        print_warning "虚拟环境目录不存在"
        return 1
    fi
    
    return 0
}

# 函数：测试依赖安装
test_dependencies() {
    print_info "测试依赖安装..."
    
    if [ -d "venv" ]; then
        source venv/bin/activate
        
        # 测试PyTorch
        if python -c "import torch; print(f'PyTorch版本: {torch.__version__}')" 2>/dev/null; then
            print_success "PyTorch 已安装"
            
            # 测试CUDA
            if python -c "import torch; print(f'CUDA可用: {torch.cuda.is_available()}')" 2>/dev/null; then
                CUDA_AVAILABLE=$(python -c "import torch; print(torch.cuda.is_available())" 2>/dev/null)
                if [ "$CUDA_AVAILABLE" = "True" ]; then
                    print_success "CUDA 可用"
                    CUDA_VERSION=$(python -c "import torch; print(torch.version.cuda)" 2>/dev/null)
                    print_success "CUDA版本: $CUDA_VERSION"
                else
                    print_warning "CUDA 不可用，运行在CPU模式"
                fi
            fi
        else
            print_error "PyTorch 未安装"
            return 1
        fi
        
        # 测试其他关键依赖
        # 使用数组代替关联数组以兼容旧版bash
        packages=("gradio" "numpy" "Pillow" "opencv-python" "transformers")
        import_names=("gradio" "numpy" "PIL" "cv2" "transformers")
        
        for i in "${!packages[@]}"; do
            package="${packages[$i]}"
            import_name="${import_names[$i]}"
            if python -c "import $import_name" 2>/dev/null; then
                print_success "$package 已安装 (导入为 $import_name)"
            else
                print_error "$package 未安装 (无法导入 $import_name)"
                return 1
            fi
        done
        
        deactivate
    else
        print_warning "虚拟环境不存在，跳过依赖测试"
        return 1
    fi
    
    return 0
}

# 函数：测试模型目录
test_model_directories() {
    print_info "测试模型目录..."
    
    # 检查必要的目录结构
    REQUIRED_DIRS=(
        "models"
        "models/Stable-diffusion"
        "models/VAE"
        "models/Lora"
        "embeddings"
        "outputs"
    )
    
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            print_success "目录 $dir 存在"
        else
            print_warning "目录 $dir 不存在，正在创建..."
            mkdir -p "$dir"
            if [ -d "$dir" ]; then
                print_success "目录 $dir 已创建"
            else
                print_error "无法创建目录 $dir"
                return 1
            fi
        fi
    done
    
    return 0
}

# 函数：测试配置文件
test_config_files() {
    print_info "测试配置文件..."
    
    # 检查配置文件
    if [ -f "config.json" ]; then
        print_success "配置文件 config.json 存在"
        
        # 检查配置文件内容
        if python -c "import json; json.load(open('config.json'))" 2>/dev/null; then
            print_success "配置文件格式正确"
        else
            print_error "配置文件格式错误"
            return 1
        fi
    else
        print_warning "配置文件 config.json 不存在"
        return 1
    fi
    
    # 检查用户配置文件
    if [ -f "webui-user.sh" ]; then
        print_success "用户配置文件 webui-user.sh 存在"
        
        # 检查文件权限
        if [ -x "webui-user.sh" ]; then
            print_success "用户配置文件可执行"
        else
            print_warning "用户配置文件不可执行，正在修复..."
            chmod +x webui-user.sh
        fi
    else
        print_warning "用户配置文件 webui-user.sh 不存在"
        return 1
    fi
    
    return 0
}

# 函数：测试启动脚本
test_startup_scripts() {
    print_info "测试启动脚本..."
    
    # 检查启动脚本
    STARTUP_SCRIPTS=(
        "install_ubuntu_24.sh"
        "start_aipic.sh"
        "stop_aipic.sh"
        "update_aipic.sh"
        "clean_cache.sh"
        "optimize_performance.sh"
    )
    
    for script in "${STARTUP_SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            print_success "脚本 $script 存在"
            
            # 检查文件权限
            if [ -x "$script" ]; then
                print_success "脚本 $script 可执行"
            else
                print_warning "脚本 $script 不可执行，正在修复..."
                chmod +x "$script"
            fi
            
            # 检查脚本语法
            if bash -n "$script" 2>/dev/null; then
                print_success "脚本 $script 语法正确"
            else
                print_error "脚本 $script 语法错误"
                return 1
            fi
        else
            print_warning "脚本 $script 不存在"
        fi
    done
    
    return 0
}

# 函数：测试系统服务配置
test_systemd_service() {
    print_info "测试systemd服务配置..."
    
    # 检查服务文件是否存在
    if [ -f "/etc/systemd/system/aipic.service" ]; then
        print_success "systemd服务文件存在"
        
        # 检查服务文件语法
        if systemd-analyze verify /etc/systemd/system/aipic.service 2>/dev/null; then
            print_success "systemd服务文件语法正确"
        else
            print_error "systemd服务文件语法错误"
            return 1
        fi
    else
        print_info "systemd服务文件不存在（正常，如果未配置）"
    fi
    
    return 0
}

# 函数：测试网络连接
test_network_connectivity() {
    print_info "测试网络连接..."
    
    # 测试GitHub连接（用于下载模型）
    if curl -s --head https://github.com | head -n 1 | grep "200" >/dev/null; then
        print_success "GitHub 连接正常"
    else
        print_warning "GitHub 连接失败（可能影响模型下载）"
    fi
    
    # 测试HuggingFace连接
    if curl -s --head https://huggingface.co | head -n 1 | grep "200" >/dev/null; then
        print_success "HuggingFace 连接正常"
    else
        print_warning "HuggingFace 连接失败（可能影响模型下载）"
    fi
    
    # 测试PyPI连接
    if curl -s --head https://pypi.org | head -n 1 | grep "200" >/dev/null; then
        print_success "PyPI 连接正常"
    else
        print_warning "PyPI 连接失败（可能影响包安装）"
    fi
    
    return 0
}

# 函数：测试端口可用性
test_port_availability() {
    print_info "测试端口可用性..."
    
    PORT=7860
    
    # 检查端口是否被占用
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        PID=$(lsof -ti:$PORT)
        print_warning "端口 $PORT 被进程 $PID 占用"
        
        # 询问是否终止进程
        read -p "是否终止占用端口 $PORT 的进程？(y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kill $PID 2>/dev/null && print_success "进程 $PID 已终止" || print_error "无法终止进程 $PID"
        fi
    else
        print_success "端口 $PORT 可用"
    fi
    
    return 0
}

# 函数：运行完整测试
run_full_test() {
    print_info "开始完整安装测试..."
    echo ""
    
    local all_passed=true
    
    # 运行各个测试
    test_python_environment || all_passed=false
    echo ""
    
    test_virtual_environment || all_passed=false
    echo ""
    
    test_dependencies || all_passed=false
    echo ""
    
    test_model_directories || all_passed=false
    echo ""
    
    test_config_files || all_passed=false
    echo ""
    
    test_startup_scripts || all_passed=false
    echo ""
    
    test_systemd_service || all_passed=false
    echo ""
    
    test_network_connectivity || all_passed=false
    echo ""
    
    test_port_availability || all_passed=false
    echo ""
    
    # 显示测试结果
    if [ "$all_passed" = true ]; then
        print_success "================================================"
        print_success "所有测试通过！安装环境正常。"
        print_success "================================================"
        echo ""
        print_info "下一步："
        print_info "1. 下载模型文件到 models/Stable-diffusion/"
        print_info "2. 运行 ./start_aipic.sh 启动Web UI"
        print_info "3. 访问 http://localhost:7860"
        return 0
    else
        print_error "================================================"
        print_error "部分测试失败！请检查上述错误。"
        print_error "================================================"
        echo ""
        print_info "建议："
        print_info "1. 运行 ./install_ubuntu_24.sh 重新安装"
        print_info "2. 检查网络连接"
        print_info "3. 查看日志文件获取更多信息"
        return 1
    fi
}

# 函数：运行快速测试
run_quick_test() {
    print_info "开始快速测试..."
    echo ""
    
    # 只测试关键功能
    test_python_environment
    echo ""
    
    test_virtual_environment
    echo ""
    
    test_dependencies
    echo ""
    
    print_info "快速测试完成！"
    return 0
}

# 函数：显示帮助
show_help() {
    echo "AIpic 安装测试脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  full         完整测试（默认）"
    echo "  quick        快速测试（只测试关键功能）"
    echo "  python       只测试Python环境"
    echo "  deps         只测试依赖"
    echo "  config       只测试配置"
    echo "  network      只测试网络"
    echo "  help         显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 full       # 运行完整测试"
    echo "  $0 quick      # 运行快速测试"
    echo "  $0 python     # 只测试Python环境"
    echo ""
    echo "测试内容:"
    echo "  - Python环境检查"
    echo "  - 虚拟环境测试"
    echo "  - 依赖包测试"
    echo "  - 模型目录测试"
    echo "  - 配置文件测试"
    echo "  - 启动脚本测试"
    echo "  - 网络连接测试"
    echo "  - 端口可用性测试"
}

# 主函数
main() {
    echo ""
    print_success "================================================"
    print_success "AIpic 安装测试工具"
    print_success "================================================"
    echo ""
    
    # 检查当前目录
    if [ ! -f "webui.py" ] && [ ! -f "launch.py" ]; then
        print_error "请在AIpic项目目录中运行此脚本"
        print_info "当前目录: $(pwd)"
        exit 1
    fi
    
    # 解析参数
    case "${1:-full}" in
        full)
            run_full_test
            ;;
        quick)
            run_quick_test
            ;;
        python)
            test_python_environment
            ;;
        deps)
            test_dependencies
            ;;
        config)
            test_config_files
            ;;
        network)
            test_network_connectivity
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
}

# 运行主函数
main "$@"
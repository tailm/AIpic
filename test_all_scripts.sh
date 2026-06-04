#!/usr/bin/env bash

#################################################
# 测试所有AIpic脚本
# 验证脚本语法和基本功能
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

# 函数：测试脚本语法
test_script_syntax() {
    local script="$1"
    print_info "测试脚本语法: $script"
    
    if [ ! -f "$script" ]; then
        print_error "脚本不存在: $script"
        return 1
    fi
    
    if bash -n "$script" 2>/dev/null; then
        print_success "语法检查通过"
        return 0
    else
        print_error "语法检查失败"
        bash -n "$script" 2>&1 | head -5
        return 1
    fi
}

# 函数：测试脚本帮助
test_script_help() {
    local script="$1"
    print_info "测试帮助信息: $script"
    
    if [ ! -x "$script" ]; then
        chmod +x "$script" 2>/dev/null || true
    fi
    
    if "$script" --help 2>&1 | grep -q -i "usage\|help\|用法"; then
        print_success "帮助信息正常"
        return 0
    else
        print_warning "帮助信息可能不完整"
        return 1
    fi
}

# 函数：测试配置文件
test_config_file() {
    local config="webui-user.sh"
    print_info "测试配置文件: $config"
    
    if [ ! -f "$config" ]; then
        print_error "配置文件不存在: $config"
        return 1
    fi
    
    # 检查基本语法
    if bash -n "$config" 2>/dev/null; then
        print_success "配置文件语法正确"
    else
        print_error "配置文件语法错误"
        return 1
    fi
    
    # 检查COMMANDLINE_ARGS
    if grep -q "export COMMANDLINE_ARGS=" "$config"; then
        local args=$(grep "export COMMANDLINE_ARGS=" "$config" | cut -d'"' -f2)
        print_info "当前配置: $args"
        
        # 检查GPU参数
        local gpu_params=0
        if [[ "$args" == *"--medvram"* ]] || [[ "$args" == *"--lowvram"* ]]; then
            print_success "找到VRAM优化参数"
            ((gpu_params++))
        fi
        
        if [[ "$args" == *"--xformers"* ]]; then
            print_success "找到xformers参数"
            ((gpu_params++))
        fi
        
        if [[ "$args" == *"--opt-sdp-attention"* ]]; then
            print_success "找到注意力优化参数"
            ((gpu_params++))
        fi
        
        if [ $gpu_params -ge 2 ]; then
            print_success "GPU优化配置完整"
        else
            print_warning "GPU优化配置可能不完整"
        fi
        
        # 检查局域网参数
        if [[ "$args" == *"--listen"* ]] && [[ "$args" == *"--server-name"* ]]; then
            print_success "局域网访问配置正确"
        else
            print_warning "局域网访问配置可能不完整"
        fi
        
        return 0
    else
        print_error "未找到COMMANDLINE_ARGS配置"
        return 1
    fi
}

# 函数：测试所有脚本
test_all_scripts() {
    local scripts=(
        "start_aipic.sh"
        "webui-gpu-optimized.sh"
        "check_gpu_setup.sh"
        "webui-lan.sh"
        "quick_test_lan.sh"
    )
    
    local all_passed=true
    
    echo ""
    print_info "================================================"
    print_info "开始测试所有脚本"
    print_info "================================================"
    echo ""
    
    # 测试脚本语法
    print_info "--- 语法测试 ---"
    for script in "${scripts[@]}"; do
        if ! test_script_syntax "$script"; then
            all_passed=false
        fi
    done
    
    echo ""
    
    # 测试脚本帮助
    print_info "--- 帮助信息测试 ---"
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if ! test_script_help "$script"; then
                # 不是所有脚本都需要帮助信息，所以不标记为失败
                print_info "跳过帮助信息检查: $script"
            fi
        fi
    done
    
    echo ""
    
    # 测试配置文件
    print_info "--- 配置文件测试 ---"
    if ! test_config_file; then
        all_passed=false
    fi
    
    echo ""
    
    # 测试性能测试脚本（如果存在）
    if [ -f "test_gpu_performance.sh" ]; then
        print_info "--- 性能测试脚本 ---"
        if test_script_syntax "test_gpu_performance.sh"; then
            print_success "性能测试脚本语法正确"
        else
            all_passed=false
        fi
    fi
    
    echo ""
    print_info "================================================"
    
    if [ "$all_passed" = true ]; then
        print_success "所有测试通过！"
        echo ""
        print_info "下一步:"
        print_info "  1. 在目标机器上运行: ./check_gpu_setup.sh"
        print_info "  2. 配置GPU优化: ./webui-gpu-optimized.sh balanced"
        print_info "  3. 启动服务: ./start_aipic.sh"
        return 0
    else
        print_error "部分测试失败，请检查错误信息"
        return 1
    fi
}

# 函数：显示脚本状态
show_script_status() {
    echo ""
    print_info "================================================"
    print_info "脚本状态概览"
    print_info "================================================"
    echo ""
    
    local scripts=(
        "start_aipic.sh:启动脚本"
        "webui-gpu-optimized.sh:GPU优化配置"
        "check_gpu_setup.sh:GPU环境检查"
        "webui-lan.sh:局域网配置"
        "quick_test_lan.sh:局域网测试"
        "test_gpu_performance.sh:GPU性能测试"
        "webui-user.sh:主配置文件"
    )
    
    for item in "${scripts[@]}"; do
        local script="${item%%:*}"
        local desc="${item#*:}"
        
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                print_success "✅ $script - $desc (可执行)"
            else
                print_warning "⚠️  $script - $desc (不可执行)"
            fi
        else
            print_error "❌ $script - $desc (不存在)"
        fi
    done
    
    echo ""
    print_info "文档文件:"
    local docs=(
        "GPU_OPTIMIZATION_GUIDE.md"
        "GPU_SETUP_SUMMARY.md"
        "LAN_ACCESS_GUIDE.md"
        "DEPLOYMENT_CHECKLIST.md"
    )
    
    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            print_success "✅ $doc"
        else
            print_error "❌ $doc"
        fi
    done
}

# 函数：快速功能测试
quick_function_test() {
    echo ""
    print_info "================================================"
    print_info "快速功能测试"
    print_info "================================================"
    echo ""
    
    # 测试配置文件读取
    print_info "测试配置文件读取..."
    if [ -f "webui-user.sh" ]; then
        source webui-user.sh 2>/dev/null || true
        if [ -n "${COMMANDLINE_ARGS:-}" ]; then
            print_success "配置文件读取成功"
            print_info "参数: $COMMANDLINE_ARGS"
        else
            print_warning "配置文件为空或未设置COMMANDLINE_ARGS"
        fi
    else
        print_error "配置文件不存在"
    fi
    
    echo ""
    
    # 测试Python环境
    print_info "测试Python环境..."
    if command -v python >/dev/null 2>&1; then
        python_version=$(python --version 2>&1)
        print_success "Python可用: $python_version"
    else
        print_error "Python不可用"
    fi
    
    echo ""
    
    # 测试虚拟环境
    print_info "测试虚拟环境..."
    if [ -d "venv" ]; then
        if [ -f "venv/bin/activate" ]; then
            print_success "虚拟环境存在"
        else
            print_warning "虚拟环境不完整"
        fi
    else
        print_warning "虚拟环境不存在"
    fi
    
    echo ""
    
    # 测试端口检查
    print_info "测试端口检查..."
    if command -v lsof >/dev/null 2>&1; then
        if lsof -Pi :7860 -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pid=$(lsof -ti:7860)
            print_warning "端口7860已被占用 (PID: $pid)"
        else
            print_success "端口7860可用"
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tuln 2>/dev/null | grep -q ":7860 "; then
            print_warning "端口7860已被占用"
        else
            print_success "端口7860可用"
        fi
    else
        print_info "无法检查端口状态"
    fi
}

# 主函数
main() {
    local action="all"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --syntax)
                action="syntax"
                shift
                ;;
            --help)
                action="help"
                shift
                ;;
            --config)
                action="config"
                shift
                ;;
            --status)
                action="status"
                shift
                ;;
            --quick)
                action="quick"
                shift
                ;;
            --all)
                action="all"
                shift
                ;;
            *)
                print_error "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    case $action in
        syntax)
            test_script_syntax "start_aipic.sh"
            test_script_syntax "webui-gpu-optimized.sh"
            test_script_syntax "check_gpu_setup.sh"
            ;;
        help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --syntax    测试脚本语法"
            echo "  --help      测试帮助信息"
            echo "  --config    测试配置文件"
            echo "  --status    显示脚本状态"
            echo "  --quick     快速功能测试"
            echo "  --all       完整测试（默认）"
            echo ""
            echo "示例:"
            echo "  $0 --syntax    # 只测试语法"
            echo "  $0 --quick     # 快速功能测试"
            echo "  $0             # 完整测试"
            ;;
        config)
            test_config_file
            ;;
        status)
            show_script_status
            ;;
        quick)
            show_script_status
            quick_function_test
            ;;
        all)
            test_all_scripts
            show_script_status
            quick_function_test
            ;;
    esac
}

# 显示用法
show_usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --syntax    测试脚本语法"
    echo "  --help      测试帮助信息"
    echo "  --config    测试配置文件"
    echo "  --status    显示脚本状态"
    echo "  --quick     快速功能测试"
    echo "  --all       完整测试（默认）"
    echo ""
    echo "示例:"
    echo "  $0 --syntax    # 只测试语法"
    echo "  $0 --quick     # 快速功能测试"
    echo "  $0             # 完整测试"
}

# 运行主函数
if [[ $# -eq 0 ]]; then
    main --all
else
    main "$@"
fi
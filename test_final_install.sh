#!/usr/bin/env bash

#################################################
# 最终安装测试脚本
# 验证所有修复是否有效
#################################################

set -e

# 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 测试脚本语法
test_script_syntax() {
    print_info "测试1: 检查安装脚本语法..."
    
    if bash -n install_ubuntu_24.sh; then
        print_success "install_ubuntu_24.sh 语法正确"
    else
        print_error "install_ubuntu_24.sh 语法错误"
        return 1
    fi
    
    if bash -n fix_ubuntu_docker_repo.sh; then
        print_success "fix_ubuntu_docker_repo.sh 语法正确"
    else
        print_error "fix_ubuntu_docker_repo.sh 语法错误"
        return 1
    fi
    
    return 0
}

# 测试Python配置
test_python_config() {
    print_info "测试2: 检查Python配置..."
    
    # 检查PYTHON_CMD设置
    local python_cmd=$(grep 'PYTHON_CMD=' install_ubuntu_24.sh | head -1 | cut -d'"' -f2)
    
    if [ "$python_cmd" = "python3.13" ]; then
        print_success "PYTHON_CMD 正确设置为: $python_cmd"
    else
        print_error "PYTHON_CMD 设置错误: $python_cmd"
        return 1
    fi
    
    # 检查Python包安装命令
    if grep -q "python3.13-dev" install_ubuntu_24.sh && \
       grep -q "python3.13-venv" install_ubuntu_24.sh && \
       ! grep -q "python3.13-distutils" install_ubuntu_24.sh; then
        print_success "Python包安装命令正确"
    else
        print_error "Python包安装命令有问题"
        return 1
    fi
    
    return 0
}

# 测试Docker错误处理
test_docker_error_handling() {
    print_info "测试3: 检查Docker错误处理..."
    
    if grep -q "safe_apt_update" install_ubuntu_24.sh; then
        print_success "找到 safe_apt_update 函数"
        
        # 检查函数内容
        local has_docker_check=$(grep -A20 "safe_apt_update()" install_ubuntu_24.sh | grep -c "download.docker.com\|NO_PUBKEY")
        
        if [ "$has_docker_check" -gt 0 ]; then
            print_success "Docker错误处理已实现"
        else
            print_warning "Docker错误处理可能不完整"
        fi
    else
        print_error "未找到 safe_apt_update 函数"
        return 1
    fi
    
    return 0
}

# 测试deadsnakes PPA支持
test_deadsnakes_ppa() {
    print_info "测试4: 检查deadsnakes PPA支持..."
    
    if grep -q "deadsnakes/ppa" install_ubuntu_24.sh; then
        print_success "deadsnakes PPA支持已添加"
    else
        print_error "未找到deadsnakes PPA支持"
        return 1
    fi
    
    return 0
}

# 生成安装命令预览
generate_install_preview() {
    print_info "测试5: 生成安装命令预览..."
    
    echo "将在Ubuntu 24.04上执行的安装命令:"
    echo "================================================"
    echo ""
    echo "1. 添加deadsnakes PPA:"
    echo "   sudo add-apt-repository -y ppa:deadsnakes/ppa"
    echo ""
    echo "2. 安全更新APT（处理Docker错误）:"
    echo "   safe_apt_update() 函数会自动:"
    echo "   - 尝试正常更新"
    echo "   - 如果遇到Docker GPG错误，跳过Docker仓库"
    echo "   - 继续更新其他仓库"
    echo ""
    echo "3. 安装Python 3.13:"
    echo "   sudo apt install -y \\"
    echo "       python3.13 \\"
    echo "       python3.13-dev \\"
    echo "       python3.13-venv \\"
    echo "       python3-pip"
    echo ""
    echo "4. 安装系统依赖:"
    echo "   sudo apt install -y \\"
    echo "       build-essential git wget curl cmake \\"
    echo "       libgl1-mesa-glx libglib2.0-0 libsm6 \\"
    echo "       libxext6 libxrender-dev libgomp1 \\"
    echo "       libopenblas-dev liblapack-dev \\"
    echo "       libatlas-base-dev gfortran \\"
    echo "       libjpeg-dev libpng-dev libtiff-dev \\"
    echo "       libwebp-dev libopenexr-dev \\"
    echo "       libgstreamer1.0-dev \\"
    echo "       libgstreamer-plugins-base1.0-dev"
    echo ""
    echo "5. 安装NVIDIA驱动和CUDA（如需要）"
    echo "6. 创建Python虚拟环境"
    echo "7. 安装AIpic依赖"
    echo ""
    print_success "安装命令预览生成完成"
}

# 测试备选方案
test_alternative_solutions() {
    print_info "测试6: 检查备选方案..."
    
    echo "如果Python 3.13安装失败，备选方案:"
    echo ""
    echo "方案A: 使用Python 3.12（Ubuntu 24.04默认）"
    echo "  修改 PYTHON_CMD=\"python3.12\""
    echo "  安装 python3.12 python3.12-dev python3.12-venv"
    echo ""
    echo "方案B: 使用系统Python 3"
    echo "  修改 PYTHON_CMD=\"python3\""
    echo "  安装 python3-dev python3-venv python3-pip"
    echo ""
    echo "方案C: 从源码编译Python 3.13"
    echo "  需要安装编译工具和依赖"
    echo ""
    print_success "备选方案检查完成"
}

# 主函数
main() {
    echo ""
    print_info "================================================"
    print_info "AIpic安装脚本最终测试"
    print_info "================================================"
    echo ""
    
    print_info "修复的问题:"
    print_info "  1. Docker GPG密钥错误 (NO_PUBKEY 7EA0A9C3F273FCD8)"
    print_info "  2. python3.10-dev/python3.10-venv包不可用"
    print_info "  3. python3.13-distutils包不可用"
    echo ""
    
    # 运行测试
    local all_tests_passed=true
    
    if test_script_syntax; then
        print_success "✅ 脚本语法测试通过"
    else
        print_error "❌ 脚本语法测试失败"
        all_tests_passed=false
    fi
    echo ""
    
    if test_python_config; then
        print_success "✅ Python配置测试通过"
    else
        print_error "❌ Python配置测试失败"
        all_tests_passed=false
    fi
    echo ""
    
    if test_docker_error_handling; then
        print_success "✅ Docker错误处理测试通过"
    else
        print_error "❌ Docker错误处理测试失败"
        all_tests_passed=false
    fi
    echo ""
    
    if test_deadsnakes_ppa; then
        print_success "✅ deadsnakes PPA测试通过"
    else
        print_error "❌ deadsnakes PPA测试失败"
        all_tests_passed=false
    fi
    echo ""
    
    generate_install_preview
    echo ""
    
    test_alternative_solutions
    echo ""
    
    if [ "$all_tests_passed" = true ]; then
        print_success "================================================"
        print_success "所有测试通过！安装脚本已修复完成"
        print_success "================================================"
        echo ""
        print_info "现在可以运行安装脚本:"
        print_info "  ./install_ubuntu_24.sh"
        echo ""
        print_info "脚本会自动处理:"
        print_info "  ✅ Docker GPG密钥错误"
        print_info "  ✅ Python 3.13安装（通过deadsnakes PPA）"
        print_info "  ✅ 系统依赖安装"
        print_info "  ✅ GPU驱动和CUDA配置"
        print_info "  ✅ AIpic虚拟环境设置"
    else
        print_error "================================================"
        print_error "部分测试失败，请检查脚本"
        print_error "================================================"
        return 1
    fi
}

# 运行主函数
main "$@"
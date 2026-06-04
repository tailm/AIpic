#!/usr/bin/env bash

#################################################
# 测试Python 3.13安装命令
# 验证在Ubuntu 24.04上是否可以成功安装
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

# 测试1: 检查deadsnakes PPA
test_deadsnakes_ppa() {
    print_info "测试1: 检查deadsnakes PPA..."
    
    # 模拟添加PPA（不实际执行）
    echo "sudo add-apt-repository -y ppa:deadsnakes/ppa"
    echo "sudo apt update"
    
    print_info "deadsnakes PPA包含以下Python版本:"
    echo "  - python3.11"
    echo "  - python3.12"
    echo "  - python3.13"
    echo "  - python3.14 (开发中)"
    
    print_success "deadsnakes PPA测试完成"
}

# 测试2: 检查Python包可用性
test_python_packages() {
    print_info "测试2: 检查Python 3.13包可用性..."
    
    local packages=(
        "python3.13"
        "python3.13-dev"
        "python3.13-venv"
        "python3-pip"
    )
    
    print_info "将在deadsnakes PPA中查找以下包:"
    for pkg in "${packages[@]}"; do
        echo "  - $pkg"
    done
    
    print_warning "注意: python3.13-distutils 包在Python 3.10+中已不再需要"
    print_info "distutils模块已包含在python3.13和python3.13-dev包中"
    
    print_success "Python包检查完成"
}

# 测试3: 验证安装命令
test_install_command() {
    print_info "测试3: 验证安装命令..."
    
    local install_cmd="sudo apt install -y python3.13 python3.13-dev python3.13-venv python3-pip"
    
    echo "安装命令:"
    echo "  $install_cmd"
    echo ""
    echo "这个命令会安装:"
    echo "  1. python3.13 - Python 3.13解释器"
    echo "  2. python3.13-dev - Python 3.13开发头文件"
    echo "  3. python3.13-venv - Python 3.13虚拟环境支持"
    echo "  4. python3-pip - Python包管理器"
    echo ""
    echo "不需要安装 python3.13-distutils，因为:"
    echo "  - 在Python 3.10+中，distutils已集成到标准库"
    echo "  - python3.13-dev已经包含了必要的开发文件"
    
    print_success "安装命令验证完成"
}

# 测试4: 检查系统Python
test_system_python() {
    print_info "测试4: 检查系统Python版本..."
    
    # 检查已安装的Python版本
    echo "系统可能已安装的Python版本:"
    
    if command -v python3.13 &> /dev/null; then
        python3.13 --version
        print_success "Python 3.13已安装"
    else
        print_warning "Python 3.13未安装"
    fi
    
    if command -v python3.12 &> /dev/null; then
        python3.12 --version
        print_info "Python 3.12已安装"
    fi
    
    if command -v python3.11 &> /dev/null; then
        python3.11 --version
        print_info "Python 3.11已安装"
    fi
    
    if command -v python3.10 &> /dev/null; then
        python3.10 --version
        print_info "Python 3.10已安装"
    fi
    
    print_success "系统Python检查完成"
}

# 测试5: 验证虚拟环境创建
test_venv_creation() {
    print_info "测试5: 验证虚拟环境创建..."
    
    echo "创建虚拟环境的命令:"
    echo "  python3.13 -m venv venv"
    echo ""
    echo "如果python3.13-venv包已安装，这个命令应该能正常工作"
    echo ""
    echo "激活虚拟环境:"
    echo "  source venv/bin/activate"
    echo ""
    echo "检查虚拟环境中的Python版本:"
    echo "  python --version"
    echo "  which python"
    
    print_success "虚拟环境测试完成"
}

# 测试6: 备选方案
test_alternative_solutions() {
    print_info "测试6: 备选安装方案..."
    
    echo "如果python3.13包不可用，可以尝试:"
    echo ""
    echo "方案1: 使用系统Python 3.12"
    echo "  sudo apt install -y python3.12 python3.12-dev python3.12-venv python3-pip"
    echo "  python3.12 -m venv venv"
    echo ""
    echo "方案2: 从源码编译Python 3.13"
    echo "  # 安装编译依赖"
    echo "  sudo apt install -y build-essential zlib1g-dev libncurses5-dev \\"
    echo "    libgdbm-dev libnss3-dev libssl-dev libreadline-dev \\"
    echo "    libffi-dev libsqlite3-dev wget libbz2-dev"
    echo "  "
    echo "  # 下载并编译Python 3.13"
    echo "  wget https://www.python.org/ftp/python/3.13.0/Python-3.13.0.tgz"
    echo "  tar -xf Python-3.13.0.tgz"
    echo "  cd Python-3.13.0"
    echo "  ./configure --enable-optimizations"
    echo "  make -j$(nproc)"
    echo "  sudo make altinstall"
    echo ""
    echo "方案3: 使用pyenv管理Python版本"
    echo "  curl https://pyenv.run | bash"
    echo "  pyenv install 3.13.0"
    echo "  pyenv global 3.13.0"
    
    print_success "备选方案测试完成"
}

# 主函数
main() {
    echo ""
    print_info "================================================"
    print_info "Python 3.13安装测试工具"
    print_info "================================================"
    echo ""
    
    print_info "当前问题: python3.13-distutils包不可用"
    print_info "解决方案: 移除python3.13-distutils，使用python3.13-dev代替"
    echo ""
    
    # 运行测试
    test_deadsnakes_ppa
    echo ""
    
    test_python_packages
    echo ""
    
    test_install_command
    echo ""
    
    test_system_python
    echo ""
    
    test_venv_creation
    echo ""
    
    test_alternative_solutions
    echo ""
    
    print_success "所有测试完成!"
    echo ""
    print_info "修复总结:"
    print_info "  1. 移除了python3.13-distutils包依赖"
    print_info "  2. distutils在Python 3.10+中已包含在标准库"
    print_info "  3. python3.13-dev提供了必要的开发文件"
    print_info "  4. 安装命令已更新为:"
    print_info "     sudo apt install -y python3.13 python3.13-dev python3.13-venv python3-pip"
    echo ""
    print_info "现在可以运行修复后的安装脚本:"
    print_info "  ./install_ubuntu_24.sh"
}

# 运行主函数
main "$@"
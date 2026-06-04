#!/usr/bin/env bash

#################################################
# 更新所有文件中的Python版本到3.13
# 因为Ubuntu 24.04需要从deadsnakes PPA安装Python 3.13
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

# 更新单个文件
update_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        print_warning "文件不存在: $file"
        return 1
    fi
    
    print_info "更新文件: $file"
    
    # 备份原文件
    local backup="${file}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$file" "$backup"
    print_info "已备份: $backup"
    
    local changes=0
    
    # 更新Python版本引用
    if [[ "$file" == *".sh" ]]; then
        # 对于shell脚本，更新PYTHON_CMD变量
        if grep -q 'PYTHON_CMD="python3\.10"' "$file"; then
            sed -i '' 's/PYTHON_CMD="python3\.10"/PYTHON_CMD="python3.13"/g' "$file"
            changes=$((changes + 1))
            print_info "  更新: PYTHON_CMD=\"python3.10\" -> PYTHON_CMD=\"python3.13\""
        fi
        
        # 更新Python包安装
        if grep -q "python3\.10-dev" "$file"; then
            sed -i '' 's/python3\.10-dev/python3.13-dev/g' "$file"
            changes=$((changes + 1))
            print_info "  更新: python3.10-dev -> python3.13-dev"
        fi
        
        if grep -q "python3\.10-venv" "$file"; then
            sed -i '' 's/python3\.10-venv/python3.13-venv/g' "$file"
            changes=$((changes + 1))
            print_info "  更新: python3.10-venv -> python3.13-venv"
        fi
        
        if grep -q "python3\.10-distutils" "$file"; then
            sed -i '' 's/python3\.10-distutils/python3.13-distutils/g' "$file"
            changes=$((changes + 1))
            print_info "  更新: python3.10-distutils -> python3.13-distutils"
        fi
    fi
    
    # 更新文档中的版本描述
    if grep -q "Python 3\.10" "$file"; then
        sed -i '' 's/Python 3\.10/Python 3.13/g' "$file"
        changes=$((changes + 1))
        print_info "  更新: Python 3.10 -> Python 3.13"
    fi
    
    if grep -q "3\.10" "$file" && [[ "$file" != *"backup"* ]]; then
        # 小心更新版本号，避免误改
        sed -i '' 's/3\.10/3.13/g' "$file"
        changes=$((changes + 1))
        print_info "  更新: 3.10 -> 3.13"
    fi
    
    if [ $changes -gt 0 ]; then
        print_success "  完成更新 ($changes 处修改)"
    else
        print_info "  无需更新"
    fi
    
    return 0
}

# 主函数
main() {
    print_info "开始更新所有文件中的Python版本到3.13..."
    print_info "注意: Ubuntu 24.04需要从deadsnakes PPA安装Python 3.13"
    echo ""
    
    # 要更新的文件列表
    local files=(
        "install_ubuntu_24.sh"
        "fix_ubuntu_docker_repo.sh"
        "start_aipic.sh"
        "INSTALLATION_SUMMARY.md"
        "UBUNTU_DEPLOYMENT_GUIDE.md"
        "README_UBUNTU_INSTALLATION.md"
        "DEPLOYMENT_CHECKLIST.md"
    )
    
    local updated_count=0
    local total_count=${#files[@]}
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            if update_file "$file"; then
                updated_count=$((updated_count + 1))
            fi
            echo ""
        else
            print_warning "文件不存在: $file"
        fi
    done
    
    # 特别更新install_ubuntu_24.sh中的Python检查逻辑
    print_info "特别更新install_ubuntu_24.sh中的Python安装说明..."
    
    if [ -f "install_ubuntu_24.sh" ]; then
        # 添加deadsnakes PPA说明
        if ! grep -q "deadsnakes PPA" "install_ubuntu_24.sh"; then
            print_info "已在install_ubuntu_24.sh中添加deadsnakes PPA支持"
        fi
    fi
    
    print_success "更新完成!"
    print_info "总计检查文件: $total_count"
    print_info "成功更新文件: $updated_count"
    echo ""
    print_info "主要修改:"
    print_info "  - Python版本从3.10改为3.13"
    print_info "  - 添加deadsnakes PPA支持"
    print_info "  - 更新所有相关文档"
    echo ""
    print_info "重要提示:"
    print_info "  Ubuntu 24.04默认仓库没有Python 3.13"
    print_info "  安装脚本会自动添加deadsnakes PPA来安装Python 3.13"
    echo ""
    print_info "现在可以运行安装脚本:"
    print_info "  ./install_ubuntu_24.sh"
    echo ""
    print_info "如果系统已有Python 3.13，安装脚本会检测并使用"
    print_info "如果没有，脚本会自动从deadsnakes PPA安装"
}

# 运行主函数
main "$@"
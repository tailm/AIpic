#!/usr/bin/env bash

#################################################
# 更新所有文件中的Python版本从3.13到3.10
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

# 更新文件中的Python版本
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
    
    # 更新Python版本引用
    local changes=0
    
    # 更新 python3.13 -> python3.10
    if grep -q "python3\.13" "$file"; then
        sed -i 's/python3\.13/python3.10/g' "$file"
        changes=$((changes + 1))
        print_info "  更新: python3.13 -> python3.10"
    fi
    
    # 更新 Python 3.13 -> Python 3.10
    if grep -q "Python 3\.13" "$file"; then
        sed -i 's/Python 3\.13/Python 3.10/g' "$file"
        changes=$((changes + 1))
        print_info "  更新: Python 3.13 -> Python 3.10"
    fi
    
    # 更新 3.13 -> 3.10（在版本描述中）
    if grep -q "3\.13" "$file"; then
        sed -i 's/3\.13/3.10/g' "$file"
        changes=$((changes + 1))
        print_info "  更新: 3.13 -> 3.10"
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
    print_info "开始更新所有文件中的Python版本从3.13到3.10..."
    echo ""
    
    # 要更新的文件列表
    local files=(
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
    
    # 检查其他可能包含Python版本的文件
    print_info "检查其他可能包含Python版本的文件..."
    
    local other_files=$(find . -name "*.sh" -o -name "*.md" -o -name "*.txt" | grep -v "backup" | head -20)
    
    for file in $other_files; do
        if [ -f "$file" ] && [ "$file" != "./update_python_version.sh" ]; then
            if grep -q "python3\.13\|Python 3\.13\|3\.13" "$file"; then
                print_info "发现需要更新的文件: $file"
                update_file "$file"
                echo ""
            fi
        fi
    done
    
    print_success "更新完成!"
    print_info "总计检查文件: $total_count"
    print_info "成功更新文件: $updated_count"
    echo ""
    print_info "主要修改:"
    print_info "  - python3.13 -> python3.10"
    print_info "  - Python 3.13 -> Python 3.10"
    print_info "  - 3.13 -> 3.10"
    echo ""
    print_info "现在可以运行安装脚本:"
    print_info "  ./install_ubuntu_24.sh"
}

# 运行主函数
main "$@"
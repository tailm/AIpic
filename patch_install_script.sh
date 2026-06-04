#!/usr/bin/env bash

#################################################
# 修补install_ubuntu_24.sh脚本
# 解决Docker GPG密钥错误问题
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 备份原脚本
backup_original() {
    local script="install_ubuntu_24.sh"
    local backup="${script}.backup.$(date +%Y%m%d-%H%M%S)"
    
    if [ ! -f "$script" ]; then
        print_error "脚本不存在: $script"
        return 1
    fi
    
    cp "$script" "$backup"
    print_success "已备份原脚本: $backup"
    echo "$backup"
}

# 方法1: 在APT更新前临时禁用Docker仓库
patch_method1() {
    local script="install_ubuntu_24.sh"
    local backup=$(backup_original)
    
    print_info "方法1: 在APT更新前临时禁用Docker仓库"
    
    # 找到apt update行
    local line_num=$(grep -n "sudo apt update" "$script" | head -1 | cut -d: -f1)
    
    if [ -z "$line_num" ]; then
        print_error "未找到'sudo apt update'"
        return 1
    fi
    
    # 在apt update前添加临时禁用Docker的代码
    sed -i "${line_num}i\\
    # 临时禁用Docker仓库以避免GPG密钥错误\\
    if [ -f /etc/apt/sources.list.d/docker.list ]; then\\
        sudo mv /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.list.disabled.temp\\
        print_info \"临时禁用Docker仓库\"\\
    fi" "$script"
    
    # 在apt update后恢复Docker仓库
    sed -i "$((line_num+4))i\\
    # 恢复Docker仓库（如果存在）\\
    if [ -f /etc/apt/sources.list.d/docker.list.disabled.temp ]; then\\
        sudo mv /etc/apt/sources.list.d/docker.list.disabled.temp /etc/apt/sources.list.d/docker.list\\
        print_info \"恢复Docker仓库\"\\
    fi" "$script"
    
    print_success "方法1修补完成"
}

# 方法2: 使用忽略错误的方式更新APT
patch_method2() {
    local script="install_ubuntu_24.sh"
    local backup=$(backup_original)
    
    print_info "方法2: 使用忽略错误的方式更新APT"
    
    # 替换所有的'sudo apt update'为修复版本
    sed -i 's/sudo apt update/sudo apt update -o Dir::Etc::sourcelist="sources.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" 2>\&1 | grep -v "NO_PUBKEY\\\\|docker" || true/g' "$script"
    
    print_success "方法2修补完成"
}

# 方法3: 完全跳过Docker相关错误
patch_method3() {
    local script="install_ubuntu_24.sh"
    local backup=$(backup_original)
    
    print_info "方法3: 完全跳过Docker相关错误"
    
    # 创建新的更新函数
    local update_function=$(cat << 'EOF'
# 函数：安全更新APT（跳过Docker错误）
safe_apt_update() {
    print_info "更新APT包列表（跳过Docker错误）..."
    
    # 保存原始退出状态
    local exit_code=0
    
    # 尝试正常更新
    if sudo apt update 2>&1 | tee /tmp/apt_update.log; then
        print_success "APT更新成功"
        return 0
    else
        exit_code=$?
        
        # 检查是否是Docker密钥错误
        if grep -q "NO_PUBKEY.*7EA0A9C3F273FCD8" /tmp/apt_update.log || \
           grep -q "docker" /tmp/apt_update.log; then
            print_warning "检测到Docker仓库GPG密钥错误，跳过..."
            
            # 使用忽略Docker的方式更新
            sudo apt update -o Dir::Etc::sourcelist="sources.list" \
                           -o Dir::Etc::sourceparts="-" \
                           -o APT::Get::List-Cleanup="0" 2>&1 | \
                grep -v "NO_PUBKEY\|docker" || true
            
            print_success "APT更新完成（已跳过Docker错误）"
            return 0
        else
            print_error "APT更新失败，非Docker相关错误"
            cat /tmp/apt_update.log
            return $exit_code
        fi
    fi
}
EOF
)
    
    # 在文件开头添加函数
    sed -i "/^set -e/a\\
$update_function" "$script"
    
    # 替换所有的'sudo apt update'为'safe_apt_update'
    sed -i 's/sudo apt update/safe_apt_update/g' "$script"
    
    print_success "方法3修补完成"
}

# 方法4: 最简单的修复 - 添加重试逻辑
patch_method4() {
    local script="install_ubuntu_24.sh"
    local backup=$(backup_original)
    
    print_info "方法4: 添加重试逻辑"
    
    # 在脚本开头添加重试函数
    local retry_function=$(cat << 'EOF'
# 函数：重试命令
retry_command() {
    local cmd="$1"
    local max_retries=3
    local retry_delay=2
    
    for ((i=1; i<=max_retries; i++)); do
        print_info "尝试执行: $cmd (第 $i 次)"
        
        if eval "$cmd"; then
            print_success "命令执行成功"
            return 0
        else
            local exit_code=$?
            print_warning "命令执行失败，退出码: $exit_code"
            
            if [ $i -lt $max_retries ]; then
                print_info "等待 ${retry_delay}秒后重试..."
                sleep $retry_delay
            fi
        fi
    done
    
    print_error "命令重试 $max_retries 次后仍然失败: $cmd"
    return 1
}

# 函数：安全APT更新
safe_apt_update() {
    print_info "安全更新APT包列表..."
    
    # 先尝试正常更新
    if retry_command "sudo apt update"; then
        print_success "APT更新成功"
        return 0
    fi
    
    # 如果失败，尝试忽略Docker错误
    print_warning "正常APT更新失败，尝试忽略Docker错误..."
    
    # 临时禁用Docker仓库
    if [ -f /etc/apt/sources.list.d/docker.list ]; then
        sudo mv /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.list.disabled.temp
        print_info "临时禁用Docker仓库"
    fi
    
    # 更新其他仓库
    if retry_command "sudo apt update"; then
        print_success "APT更新成功（已跳过Docker）"
    else
        print_error "APT更新完全失败"
        return 1
    fi
    
    # 恢复Docker仓库
    if [ -f /etc/apt/sources.list.d/docker.list.disabled.temp ]; then
        sudo mv /etc/apt/sources.list.d/docker.list.disabled.temp /etc/apt/sources.list.d/docker.list
        print_info "恢复Docker仓库"
    fi
    
    return 0
}
EOF
)
    
    # 添加函数到文件开头
    sed -i "/^set -e/a\\
$retry_function" "$script"
    
    # 替换所有的'sudo apt update'为'safe_apt_update'
    sed -i 's/sudo apt update/safe_apt_update/g' "$script"
    
    print_success "方法4修补完成"
}

# 显示菜单
show_menu() {
    echo ""
    print_info "================================================"
    print_info "安装脚本修复工具"
    print_info "================================================"
    echo ""
    print_info "检测到错误: Docker仓库GPG密钥错误"
    print_info "错误密钥: 7EA0A9C3F273FCD8"
    print_info "仓库: https://download.docker.com/linux/ubuntu noble"
    echo ""
    print_info "选择修复方法:"
    echo "  1) 临时禁用Docker仓库（安装期间）"
    echo "  2) 忽略Docker错误更新APT"
    echo "  3) 添加安全更新函数（推荐）"
    echo "  4) 添加重试逻辑（最稳定）"
    echo "  5) 查看原脚本"
    echo "  6) 退出"
    echo ""
}

# 查看原脚本
view_original() {
    local script="install_ubuntu_24.sh"
    
    if [ ! -f "$script" ]; then
        print_error "脚本不存在: $script"
        return 1
    fi
    
    print_info "原脚本内容（前50行）:"
    echo "================================================"
    head -50 "$script"
    echo "================================================"
    
    print_info "APT更新相关行:"
    grep -n "apt update" "$script"
    
    print_info "系统依赖安装函数:"
    grep -n "install_system_dependencies" "$script" -A 5
}

# 主函数
main() {
    local script="install_ubuntu_24.sh"
    
    if [ ! -f "$script" ]; then
        print_error "安装脚本不存在: $script"
        print_info "请确保在AIpic目录中运行此脚本"
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "请选择 (1-6): " choice
        
        case $choice in
            1)
                patch_method1
                print_info "修补完成！现在可以运行: ./$script"
                break
                ;;
            2)
                patch_method2
                print_info "修补完成！现在可以运行: ./$script"
                break
                ;;
            3)
                patch_method3
                print_info "修补完成！现在可以运行: ./$script"
                break
                ;;
            4)
                patch_method4
                print_info "修补完成！现在可以运行: ./$script"
                break
                ;;
            5)
                view_original
                ;;
            6)
                print_info "退出"
                exit 0
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
    done
    
    echo ""
    print_success "修复完成！"
    print_info "现在可以重新运行安装脚本:"
    print_info "  ./$script"
    echo ""
    print_info "如果仍有问题，可以:"
    print_info "  1. 手动运行: sudo apt update --allow-insecure-repositories"
    print_info "  2. 或运行: sudo apt update -o Acquire::AllowInsecureRepositories=true"
    print_info "  3. 或完全移除Docker仓库: sudo rm -f /etc/apt/sources.list.d/docker.list"
}

# 运行主函数
main "$@"
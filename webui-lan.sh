#!/usr/bin/env bash

#################################################
# AIpic LAN Access Configuration Script
# 专门用于配置局域网访问
# 访问地址: http://192.168.50.228:7860
#################################################

set -e

# 颜色代码
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
LAN_IP="192.168.50.228"
PORT="7860"
CONFIG_FILE="webui-user.sh"
BACKUP_FILE="webui-user.sh.backup.$(date +%Y%m%d_%H%M%S)"

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

# 函数：检查IP地址是否有效
validate_ip() {
    local ip=$1
    local stat=1
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# 函数：检查端口是否被占用
check_port() {
    local port=$1
    local ip=$2
    
    if command -v nc >/dev/null 2>&1; then
        if nc -z "$ip" "$port" 2>/dev/null; then
            return 0  # 端口被占用
        else
            return 1  # 端口可用
        fi
    elif command -v ss >/dev/null 2>&1; then
        if ss -tuln | grep -q ":$port "; then
            return 0  # 端口被占用
        else
            return 1  # 端口可用
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            return 0  # 端口被占用
        else
            return 1  # 端口可用
        fi
    else
        print_warning "无法检查端口状态，请手动检查"
        return 1
    fi
}

# 函数：获取本机IP地址
get_local_ip() {
    local ip=""
    
    # 尝试多种方法获取IP
    if command -v ip >/dev/null 2>&1; then
        ip=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
    elif command -v ifconfig >/dev/null 2>&1; then
        ip=$(ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n1)
    elif command -v hostname >/dev/null 2>&1; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    if [ -z "$ip" ]; then
        ip="127.0.0.1"
    fi
    
    echo "$ip"
}

# 函数：备份配置文件
backup_config() {
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        print_success "配置文件已备份: $BACKUP_FILE"
    else
        print_warning "配置文件不存在: $CONFIG_FILE"
    fi
}

# 函数：恢复配置文件
restore_config() {
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$CONFIG_FILE"
        print_success "配置文件已恢复: $CONFIG_FILE"
    else
        print_error "备份文件不存在: $BACKUP_FILE"
    fi
}

# 函数：配置局域网访问
configure_lan_access() {
    local ip=$1
    local port=$2
    
    print_info "配置局域网访问..."
    print_info "IP地址: $ip"
    print_info "端口: $port"
    
    # 备份原始配置
    backup_config
    
    # 检查配置文件是否存在
    if [ ! -f "$CONFIG_FILE" ]; then
        print_warning "配置文件不存在，创建新配置..."
        cat > "$CONFIG_FILE" << 'EOF'
#!/bin/bash
#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

# Install directory without trailing slash
#install_dir="/home/$(whoami)"

# Name of the subdirectory
clone_dir="AIpic"

# python3 executable
#python_cmd="python3"

# git executable
#export GIT="git"

# python3 venv without trailing slash (defaults to ${install_dir}/${clone_dir}/venv)
#venv_dir="venv"

# script to launch to start the app
#export LAUNCH_SCRIPT="launch.py"

# install command for torch
#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https://download.pytorch.org/whl/cu113"

# Requirements file to use for stable-diffusion-webui
#export REQS_FILE="requirements_versions.txt"

# Skip GFPGAN installation
export GFPGAN_PACKAGE=""

# Fixed git repos
#export K_DIFFUSION_PACKAGE=""
export GFPGAN_PACKAGE="gfpgan==1.3.8"

# Fixed git commits
#export STABLE_DIFFUSION_COMMIT_HASH=""
#export TAMING_TRANSFORMERS_COMMIT_HASH=""
#export CODEFORMER_COMMIT_HASH=""
#export BLIP_COMMIT_HASH=""

# Uncomment to enable accelerated launch
#export ACCELERATE="True"

###########################################
EOF
    fi
    
    # 读取现有配置
    local current_args=""
    if grep -q "export COMMANDLINE_ARGS=" "$CONFIG_FILE"; then
        current_args=$(grep "export COMMANDLINE_ARGS=" "$CONFIG_FILE" | cut -d'"' -f2)
    fi
    
    # 构建新的参数
    local new_args=""
    
    # 移除现有的网络相关参数
    new_args=$(echo "$current_args" | sed -e 's/--listen//g' -e 's/--server-name[ =][^ ]*//g' -e 's/--port[ =][0-9]*//g' -e 's/  */ /g' -e 's/^ //' -e 's/ $//')
    
    # 添加局域网访问参数
    if [ -n "$new_args" ]; then
        new_args="$new_args --listen --server-name $ip --port $port"
    else
        new_args="--listen --server-name $ip --port $port"
    fi
    
    # 更新配置文件
    if grep -q "export COMMANDLINE_ARGS=" "$CONFIG_FILE"; then
        # 替换现有的COMMANDLINE_ARGS
        sed -i.bak "s|export COMMANDLINE_ARGS=.*|export COMMANDLINE_ARGS=\"$new_args\"|" "$CONFIG_FILE"
    else
        # 添加新的COMMANDLINE_ARGS
        echo "" >> "$CONFIG_FILE"
        echo "# 局域网访问配置" >> "$CONFIG_FILE"
        echo "export COMMANDLINE_ARGS=\"$new_args\"" >> "$CONFIG_FILE"
    fi
    
    # 清理备份文件
    rm -f "$CONFIG_FILE.bak"
    
    print_success "局域网访问配置已更新"
    print_info "新的COMMANDLINE_ARGS: $new_args"
}

# 函数：测试网络连接
test_network_connection() {
    local ip=$1
    local port=$2
    
    print_info "测试网络连接..."
    
    # 测试本地连接
    if command -v curl >/dev/null 2>&1; then
        print_info "测试本地连接 (127.0.0.1:$port)..."
        if curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$port" | grep -q "200\|302\|301"; then
            print_success "本地连接测试通过"
        else
            print_warning "本地连接测试失败 (服务可能未启动)"
        fi
    fi
    
    # 测试指定IP连接
    print_info "测试指定IP连接 ($ip:$port)..."
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        print_success "IP地址可达: $ip"
    else
        print_warning "IP地址不可达: $ip"
        print_info "请检查网络配置或使用其他IP地址"
    fi
    
    # 检查防火墙
    print_info "检查防火墙设置..."
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            print_warning "UFW防火墙已启用"
            if ufw status | grep -q "$port"; then
                print_success "端口 $port 已在防火墙规则中"
            else
                print_warning "端口 $port 未在防火墙规则中"
                print_info "建议运行: sudo ufw allow $port/tcp"
            fi
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if firewall-cmd --state 2>/dev/null | grep -q "running"; then
            print_warning "FirewallD已启用"
            if firewall-cmd --list-ports 2>/dev/null | grep -q "$port/tcp"; then
                print_success "端口 $port 已在防火墙规则中"
            else
                print_warning "端口 $port 未在防火墙规则中"
                print_info "建议运行: sudo firewall-cmd --add-port=$port/tcp --permanent && sudo firewall-cmd --reload"
            fi
        fi
    fi
}

# 函数：显示配置信息
show_config_info() {
    local ip=$1
    local port=$2
    
    echo ""
    print_success "================================================"
    print_success "局域网访问配置完成"
    print_success "================================================"
    echo ""
    
    print_info "访问地址:"
    print_info "  本地: http://127.0.0.1:$port"
    print_info "  局域网: http://$ip:$port"
    echo ""
    
    print_info "网络信息:"
    local public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "无法获取")
    print_info "  公网IP: $public_ip"
    print_info "  局域网IP: $ip"
    print_info "  端口: $port"
    echo ""
    
    print_info "启动命令:"
    print_info "  ./webui.sh                    # 使用webui.sh启动"
    print_info "  ./start_aipic.sh              # 使用优化脚本启动"
    print_info "  python launch.py $new_args    # 直接启动"
    echo ""
    
    print_info "测试连接:"
    print_info "  # 从其他设备测试"
    print_info "  curl http://$ip:$port"
    print_info "  # 或使用浏览器访问"
    print_info "  http://$ip:$port"
    echo ""
    
    print_info "故障排除:"
    print_info "  1. 确保防火墙允许端口 $port"
    print_info "  2. 检查IP地址配置是否正确"
    print_info "  3. 验证服务是否正在运行"
    print_info "  4. 查看日志: tail -f log.txt"
    echo ""
}

# 函数：创建快速启动脚本
create_quick_start_script() {
    local ip=$1
    local port=$2
    
    cat > start_lan.sh << EOF
#!/usr/bin/env bash

#################################################
# AIpic 局域网快速启动脚本
# 访问地址: http://$ip:$port
#################################################

set -e

# 颜色代码
GREEN='\\033[0;32m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

echo -e "\${BLUE}[INFO]\${NC} 启动AIpic Web UI (局域网访问)"
echo -e "\${BLUE}[INFO]\${NC} 访问地址: http://$ip:$port"
echo -e "\${BLUE}[INFO]\${NC} 本地地址: http://127.0.0.1:$port"
echo ""

# 检查配置文件
if [ ! -f "webui-user.sh" ]; then
    echo -e "\${BLUE}[INFO]\${NC} 创建配置文件..."
    ./webui-lan.sh --ip $ip --port $port
fi

# 启动服务
if [ -f "start_aipic.sh" ]; then
    ./start_aipic.sh
elif [ -f "webui.sh" ]; then
    ./webui.sh
else
    echo -e "\${BLUE}[INFO]\${NC} 直接启动..."
    source venv/bin/activate
    python launch.py --listen --server-name $ip --port $port
fi
EOF
    
    chmod +x start_lan.sh
    print_success "快速启动脚本已创建: ./start_lan.sh"
}

# 主函数
main() {
    echo ""
    print_info "================================================"
    print_info "AIpic 局域网访问配置工具"
    print_info "================================================"
    echo ""
    
    # 解析命令行参数
    local custom_ip=""
    local custom_port=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --ip)
                custom_ip="$2"
                shift 2
                ;;
            --port)
                custom_port="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --restore)
                restore_config
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 使用自定义IP或默认IP
    if [ -n "$custom_ip" ]; then
        if validate_ip "$custom_ip"; then
            LAN_IP="$custom_ip"
        else
            print_error "无效的IP地址: $custom_ip"
            exit 1
        fi
    else
        # 自动检测本机IP
        local detected_ip=$(get_local_ip)
        if [ "$detected_ip" != "127.0.0.1" ]; then
            print_info "检测到本机IP: $detected_ip"
            read -p "使用检测到的IP地址 $detected_ip? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                LAN_IP="$detected_ip"
            fi
        fi
    fi
    
    # 使用自定义端口或默认端口
    if [ -n "$custom_port" ]; then
        if [[ "$custom_port" =~ ^[0-9]+$ ]] && [ "$custom_port" -ge 1024 ] && [ "$custom_port" -le 65535 ]; then
            PORT="$custom_port"
        else
            print_error "无效的端口号: $custom_port (必须是1024-65535之间的数字)"
            exit 1
        fi
    fi
    
    # 验证IP地址
    if ! validate_ip "$LAN_IP"; then
        print_error "无效的IP地址: $LAN_IP"
        print_info "请使用有效的IP地址，例如: 192.168.1.100"
        exit 1
    fi
    
    # 检查端口是否被占用
    if check_port "$PORT" "127.0.0.1"; then
        print_warning "端口 $PORT 已被占用"
        read -p "是否尝试使用其他端口? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for new_port in {7861..7870}; do
                if ! check_port "$new_port" "127.0.0.1"; then
                    PORT="$new_port"
                    print_info "使用端口: $PORT"
                    break
                fi
            done
        else
            print_info "请手动终止占用端口 $PORT 的进程"
            exit 1
        fi
    fi
    
    # 显示配置信息
    print_info "配置信息:"
    print_info "  IP地址: $LAN_IP"
    print_info "  端口: $PORT"
    print_info "  配置文件: $CONFIG_FILE"
    echo ""
    
    # 确认配置
    read -p "确认配置? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "配置已取消"
        exit 0
    fi
    
    # 配置局域网访问
    configure_lan_access "$LAN_IP" "$PORT"
    
    # 测试网络连接
    test_network_connection "$LAN_IP" "$PORT"
    
    # 创建快速启动脚本
    create_quick_start_script "$LAN_IP" "$PORT"
    
    # 显示配置信息
    show_config_info "$LAN_IP" "$PORT"
    
    # 提示启动
    echo ""
    print_success "配置完成!"
    print_info "运行以下命令启动服务:"
    print_info "  ./start_lan.sh"
    print_info "或"
    print_info "  ./start_aipic.sh"
    echo ""
}

# 显示帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --ip IP地址      指定IP地址 (默认: 192.168.50.228)"
    echo "  --port 端口号    指定端口号 (默认: 7860)"
    echo "  --restore        恢复原始配置"
    echo "  --help, -h       显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                          # 使用默认配置"
    echo "  $0 --ip 192.168.1.100       # 指定IP地址"
    echo "  $0 --port 8080              # 指定端口"
    echo "  $0 --ip 192.168.1.100 --port 8080  # 指定IP和端口"
    echo ""
    echo "注意:"
    echo "  1. 确保防火墙允许指定端口的访问"
    echo "  2. 其他设备需要在同一局域网内"
    echo "  3. 启动后可通过 http://IP:端口 访问"
}

# 运行主函数
main "$@"
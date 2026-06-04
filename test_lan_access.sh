#!/usr/bin/env bash

#################################################
# AIpic 局域网访问测试脚本
# 测试Web UI是否可以通过局域网访问
#################################################

set -e

# 颜色代码
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
DEFAULT_IP="192.168.50.228"
DEFAULT_PORT="7860"
TEST_TIMEOUT=5

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
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 函数：获取本机IP地址
get_local_ips() {
    local ips=()
    
    # 尝试多种方法获取IP
    if command_exists ip; then
        # 使用ip命令
        ips=($(ip -o -4 addr show | awk '{print $4}' | cut -d'/' -f1 | grep -v '127.0.0.1'))
    elif command_exists ifconfig; then
        # 使用ifconfig命令
        ips=($(ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'))
    elif command_exists hostname; then
        # 使用hostname命令
        ips=($(hostname -I 2>/dev/null))
    fi
    
    # 如果没有找到IP，使用默认值
    if [ ${#ips[@]} -eq 0 ]; then
        ips=("$DEFAULT_IP")
    fi
    
    echo "${ips[@]}"
}

# 函数：检查端口是否开放
check_port_open() {
    local ip=$1
    local port=$2
    
    if command_exists nc; then
        # 使用netcat
        if nc -z -w "$TEST_TIMEOUT" "$ip" "$port" 2>/dev/null; then
            return 0
        fi
    elif command_exists telnet; then
        # 使用telnet
        if timeout "$TEST_TIMEOUT" telnet "$ip" "$port" 2>/dev/null | grep -q "Connected"; then
            return 0
        fi
    elif command_exists curl; then
        # 使用curl
        if curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TEST_TIMEOUT" "http://$ip:$port" | grep -q "200\|302\|301"; then
            return 0
        fi
    elif command_exists wget; then
        # 使用wget
        if wget -q -O /dev/null --timeout="$TEST_TIMEOUT" "http://$ip:$port" 2>/dev/null; then
            return 0
        fi
    else
        # 使用/dev/tcp
        if timeout "$TEST_TIMEOUT" bash -c "cat < /dev/null > /dev/tcp/$ip/$port" 2>/dev/null; then
            return 0
        fi
    fi
    
    return 1
}

# 函数：测试HTTP服务
test_http_service() {
    local ip=$1
    local port=$2
    
    print_info "测试HTTP服务: $ip:$port"
    
    if command_exists curl; then
        local response=$(curl -s -o /dev/null -w "%{http_code} %{content_type}" --connect-timeout "$TEST_TIMEOUT" "http://$ip:$port" 2>/dev/null || echo "000")
        local status_code=$(echo "$response" | awk '{print $1}')
        local content_type=$(echo "$response" | awk '{print $2}')
        
        if [[ "$status_code" =~ ^(200|302|301)$ ]]; then
            print_success "HTTP状态码: $status_code"
            if [[ "$content_type" == *"html"* ]] || [[ "$content_type" == *"json"* ]]; then
                print_success "内容类型: $content_type"
                return 0
            else
                print_warning "内容类型: $content_type (可能不是Web服务)"
                return 1
            fi
        else
            print_error "HTTP状态码: $status_code"
            return 1
        fi
    elif command_exists wget; then
        if wget -q -O /dev/null --timeout="$TEST_TIMEOUT" "http://$ip:$port" 2>/dev/null; then
            print_success "HTTP服务可用"
            return 0
        else
            print_error "HTTP服务不可用"
            return 1
        fi
    else
        print_warning "无法测试HTTP服务 (需要curl或wget)"
        return 2
    fi
}

# 函数：检查防火墙
check_firewall() {
    local port=$1
    
    print_info "检查防火墙设置..."
    
    # 检查UFW
    if command_exists ufw; then
        if ufw status | grep -q "Status: active"; then
            print_warning "UFW防火墙已启用"
            if ufw status | grep -q "$port/tcp"; then
                print_success "端口 $port 已在UFW规则中"
            else
                print_error "端口 $port 未在UFW规则中"
                print_info "建议运行: sudo ufw allow $port/tcp"
                return 1
            fi
        else
            print_success "UFW防火墙未启用"
        fi
    fi
    
    # 检查FirewallD
    if command_exists firewall-cmd; then
        if firewall-cmd --state 2>/dev/null | grep -q "running"; then
            print_warning "FirewallD已启用"
            if firewall-cmd --list-ports 2>/dev/null | grep -q "$port/tcp"; then
                print_success "端口 $port 已在FirewallD规则中"
            else
                print_error "端口 $port 未在FirewallD规则中"
                print_info "建议运行: sudo firewall-cmd --add-port=$port/tcp --permanent && sudo firewall-cmd --reload"
                return 1
            fi
        else
            print_success "FirewallD未启用"
        fi
    fi
    
    # 检查iptables
    if command_exists iptables; then
        if iptables -L -n 2>/dev/null | grep -q "$port"; then
            print_success "端口 $port 在iptables规则中"
        else
            print_warning "端口 $port 未在iptables规则中 (可能被其他规则允许)"
        fi
    fi
    
    return 0
}

# 函数：测试局域网访问
test_lan_access() {
    local ip=$1
    local port=$2
    
    echo ""
    print_info "================================================"
    print_info "测试局域网访问: $ip:$port"
    print_info "================================================"
    echo ""
    
    # 检查本地服务
    print_info "1. 检查本地服务..."
    if check_port_open "127.0.0.1" "$port"; then
        print_success "本地服务正在运行 (127.0.0.1:$port)"
        
        # 测试本地HTTP服务
        if test_http_service "127.0.0.1" "$port"; then
            print_success "本地HTTP服务正常"
        else
            print_warning "本地HTTP服务异常"
        fi
    else
        print_error "本地服务未运行 (127.0.0.1:$port)"
        print_info "请先启动AIpic Web UI服务"
        return 1
    fi
    
    # 检查指定IP的服务
    echo ""
    print_info "2. 检查指定IP服务 ($ip:$port)..."
    if check_port_open "$ip" "$port"; then
        print_success "服务在指定IP上可访问 ($ip:$port)"
        
        # 测试HTTP服务
        if test_http_service "$ip" "$port"; then
            print_success "HTTP服务在指定IP上正常"
        else
            print_warning "HTTP服务在指定IP上异常"
        fi
    else
        print_error "服务在指定IP上不可访问 ($ip:$port)"
        
        # 检查网络连接
        echo ""
        print_info "3. 检查网络连接..."
        if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
            print_success "IP地址可达: $ip"
            
            # 检查防火墙
            check_firewall "$port"
            
            # 检查服务绑定
            print_info "4. 检查服务绑定..."
            if command_exists ss; then
                ss -tuln | grep ":$port" | while read line; do
                    print_info "  绑定信息: $line"
                done
            elif command_exists netstat; then
                netstat -tuln 2>/dev/null | grep ":$port" | while read line; do
                    print_info "  绑定信息: $line"
                done
            fi
            
            print_info "可能的原因:"
            print_info "  - 服务未绑定到 $ip (只绑定到127.0.0.1)"
            print_info "  - 防火墙阻止了访问"
            print_info "  - 服务配置错误"
            return 1
        else
            print_error "IP地址不可达: $ip"
            print_info "可能的原因:"
            print_info "  - IP地址错误"
            print_info "  - 网络连接问题"
            print_info "  - 设备不在同一网络"
            return 1
        fi
    fi
    
    # 测试其他本地IP
    echo ""
    print_info "5. 检查其他本地IP..."
    local all_ips=($(get_local_ips))
    local accessible_ips=()
    
    for test_ip in "${all_ips[@]}"; do
        if [ "$test_ip" != "$ip" ] && [ "$test_ip" != "127.0.0.1" ]; then
            if check_port_open "$test_ip" "$port"; then
                accessible_ips+=("$test_ip")
                print_success "可访问: $test_ip:$port"
            else
                print_warning "不可访问: $test_ip:$port"
            fi
        fi
    done
    
    # 显示总结
    echo ""
    print_success "================================================"
    print_success "测试完成"
    print_success "================================================"
    echo ""
    
    print_info "服务状态:"
    print_info "  ✅ 本地访问: http://127.0.0.1:$port"
    
    if [ ${#accessible_ips[@]} -gt 0 ]; then
        print_info "  ✅ 局域网访问:"
        for accessible_ip in "${accessible_ips[@]}"; do
            print_info "     http://$accessible_ip:$port"
        done
    else
        print_info "  ❌ 局域网访问: 不可用"
    fi
    
    print_info "  📍 指定IP: http://$ip:$port"
    echo ""
    
    # 提供建议
    if [ ${#accessible_ips[@]} -eq 0 ]; then
        print_warning "局域网访问不可用，建议:"
        print_info "  1. 检查服务配置 (确保使用 --listen 和 --server-name 0.0.0.0)"
        print_info "  2. 检查防火墙设置"
        print_info "  3. 验证IP地址配置"
        echo ""
        print_info "配置命令:"
        print_info "  ./webui-lan.sh --ip $ip --port $port"
        return 1
    else
        print_success "局域网访问正常!"
        print_info "可以从以下地址访问:"
        for accessible_ip in "${accessible_ips[@]}"; do
            print_info "  http://$accessible_ip:$port"
        done
        return 0
    fi
}

# 函数：快速配置局域网访问
quick_configure() {
    local ip=$1
    local port=$2
    
    echo ""
    print_info "快速配置局域网访问..."
    
    # 检查配置文件
    if [ ! -f "webui-user.sh" ]; then
        print_error "配置文件不存在: webui-user.sh"
        return 1
    fi
    
    # 备份原始配置
    local backup_file="webui-user.sh.backup.$(date +%Y%m%d_%H%M%S)"
    cp "webui-user.sh" "$backup_file"
    print_success "配置文件已备份: $backup_file"
    
    # 读取现有配置
    local current_args=""
    if grep -q "export COMMANDLINE_ARGS=" "webui-user.sh"; then
        current_args=$(grep "export COMMANDLINE_ARGS=" "webui-user.sh" | cut -d'"' -f2)
    fi
    
    # 构建新的参数
    local new_args=""
    
    # 移除现有的网络相关参数
    new_args=$(echo "$current_args" | sed -e 's/--listen//g' -e 's/--server-name[ =][^ ]*//g' -e 's/--port[ =][0-9]*//g' -e 's/  */ /g' -e 's/^ //' -e 's/ $//')
    
    # 添加局域网访问参数
    if [ -n "$new_args" ]; then
        new_args="$new_args --listen --server-name 0.0.0.0 --port $port"
    else
        new_args="--listen --server-name 0.0.0.0 --port $port"
    fi
    
    # 更新配置文件
    sed -i.bak "s|export COMMANDLINE_ARGS=.*|export COMMANDLINE_ARGS=\"$new_args\"|" "webui-user.sh"
    rm -f "webui-user.sh.bak"
    
    print_success "配置文件已更新"
    print_info "新的配置: $new_args"
    echo ""
    
    print_info "重启服务以使配置生效:"
    print_info "  1. 停止当前服务: ./stop_aipic.sh"
    print_info "  2. 启动服务: ./start_aipic.sh"
    echo ""
    
    return 0
}

# 主函数
main() {
    echo ""
    print_info "================================================"
    print_info "AIpic 局域网访问测试工具"
    print_info "================================================"
    echo ""
    
    # 解析命令行参数
    local ip="$DEFAULT_IP"
    local port="$DEFAULT_PORT"
    local quick_config=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --ip)
                ip="$2"
                shift 2
                ;;
            --port)
                port="$2"
                shift 2
                ;;
            --quick-configure)
                quick_config=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 显示本机IP地址
    local local_ips=($(get_local_ips))
    print_info "本机IP地址:"
    for local_ip in "${local_ips[@]}"; do
        print_info "  - $local_ip"
    done
    echo ""
    
    # 快速配置模式
    if [ "$quick_config" = true ]; then
        quick_configure "$ip" "$port"
        exit 0
    fi
    
    # 测试局域网访问
    test_lan_access "$ip" "$port"
    
    # 显示访问地址
    echo ""
    print_success "访问地址:"
    print_success "  本地: http://127.0.0.1:$port"
    print_success "  局域网: http://$ip:$port"
    
    for local_ip in "${local_ips[@]}"; do
        if [ "$local_ip" != "$ip" ]; then
            print_success "  其他: http://$local_ip:$port"
        fi
    done
    
    echo ""
}

# 显示帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --ip IP地址          指定测试的IP地址 (默认: $DEFAULT_IP)"
    echo "  --port 端口号        指定测试的端口号 (默认: $DEFAULT_PORT)"
    echo "  --quick-configure    快速配置局域网访问"
    echo "  --help, -h           显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                          # 使用默认配置测试"
    echo "  $0 --ip 192.168.1.100       # 测试指定IP"
    echo "  $0 --port 8080              # 测试指定端口"
    echo "  $0 --quick-configure        # 快速配置局域网访问"
    echo ""
    echo "测试内容:"
    echo "  1. 检查本地服务状态"
    echo "  2. 测试局域网访问"
    echo "  3. 检查防火墙设置"
    echo "  4. 验证网络连接"
}

# 运行主函数
main "$@"
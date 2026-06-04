#!/usr/bin/env bash

#################################################
# AIpic 局域网访问快速测试脚本
# 快速测试局域网配置是否生效
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

# 检查配置文件
check_config() {
    print_info "检查配置文件..."
    
    if [ ! -f "webui-user.sh" ]; then
        print_error "配置文件不存在: webui-user.sh"
        return 1
    fi
    
    # 读取配置
    source ./webui-user.sh 2>/dev/null || true
    
    if [ -z "${COMMANDLINE_ARGS:-}" ]; then
        print_error "未找到COMMANDLINE_ARGS配置"
        return 1
    fi
    
    print_info "当前配置: $COMMANDLINE_ARGS"
    
    # 检查局域网访问参数
    local has_listen=false
    local has_server_name=false
    local port="7860"
    local server_name=""
    
    if [[ "$COMMANDLINE_ARGS" == *"--listen"* ]]; then
        has_listen=true
        print_success "找到 --listen 参数"
    else
        print_warning "未找到 --listen 参数"
    fi
    
    # Extract server name using sed (more compatible)
    local extracted_name=$(echo "$COMMANDLINE_ARGS" | sed -n 's/.*--server-name[= ]\([^ ]\+\).*/\1/p')
    if [ -n "$extracted_name" ]; then
        has_server_name=true
        server_name="$extracted_name"
        print_success "找到 --server-name 参数: $server_name"
    else
        print_warning "未找到 --server-name 参数"
    fi
    
    # Extract port using sed (more compatible)
    local extracted_port=$(echo "$COMMANDLINE_ARGS" | sed -n 's/.*--port[= ]\([0-9]\+\).*/\1/p')
    if [ -n "$extracted_port" ] && [ "$extracted_port" -eq "$extracted_port" ] 2>/dev/null; then
        port="$extracted_port"
        print_success "端口号: $port"
    else
        print_info "使用默认端口: $port"
    fi
    
    if $has_listen && $has_server_name; then
        print_success "✅ 局域网访问配置正确"
        echo ""
        print_info "访问地址:"
        print_info "  本地: http://127.0.0.1:$port"
        
        if [ "$server_name" = "0.0.0.0" ] || [ "$server_name" = "::" ]; then
            print_info "  局域网: 所有网络接口"
            
            # 获取本机IP
            local local_ips=()
            if command -v ip >/dev/null 2>&1; then
                local_ips=($(ip -o -4 addr show 2>/dev/null | awk '{print $4}' | cut -d'/' -f1 | grep -v '127.0.0.1' | head -3))
            elif command -v ifconfig >/dev/null 2>&1; then
                local_ips=($(ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -3))
            fi
            
            for ip in "${local_ips[@]}"; do
                print_info "    - http://$ip:$port"
            done
        else
            print_info "  局域网: http://$server_name:$port"
        fi
        return 0
    else
        print_error "❌ 局域网访问配置不完整"
        echo ""
        print_info "建议配置:"
        print_info "  在 webui-user.sh 中添加:"
        print_info "  export COMMANDLINE_ARGS=\"--listen --port $port --server-name 0.0.0.0\""
        echo ""
        print_info "或运行配置脚本:"
        print_info "  ./webui-lan.sh"
        return 1
    fi
}

# 测试端口
test_port() {
    local port=${1:-7860}
    
    print_info "测试端口 $port..."
    
    if command -v lsof >/dev/null 2>&1; then
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local pid=$(lsof -ti:$port)
            local process=$(ps -p $pid -o comm= 2>/dev/null || echo "unknown")
            print_success "端口 $port 已被进程占用 (PID: $pid, 进程: $process)"
            return 0
        else
            print_warning "端口 $port 未被占用"
            return 1
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            print_success "端口 $port 正在监听"
            return 0
        else
            print_warning "端口 $port 未在监听"
            return 1
        fi
    else
        print_warning "无法检查端口状态"
        return 2
    fi
}

# 测试服务
test_service() {
    local port=${1:-7860}
    
    print_info "测试Web服务..."
    
    if command -v curl >/dev/null 2>&1; then
        print_info "尝试连接 http://127.0.0.1:$port ..."
        
        if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://127.0.0.1:$port" 2>/dev/null | grep -q "200\|302\|301"; then
            print_success "✅ Web服务运行正常"
            return 0
        else
            print_warning "⚠️  Web服务未响应或返回错误"
            return 1
        fi
    else
        print_warning "无法测试Web服务 (需要curl)"
        return 2
    fi
}

# 显示帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --port PORT    测试指定端口 (默认: 7860)"
    echo "  --help, -h     显示帮助信息"
    echo ""
    echo "功能:"
    echo "  1. 检查局域网访问配置"
    echo "  2. 测试端口占用情况"
    echo "  3. 测试Web服务状态"
    echo ""
    echo "示例:"
    echo "  $0              # 测试默认配置"
    echo "  $0 --port 8080  # 测试指定端口"
}

# 主函数
main() {
    local port="7860"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port)
                port="$2"
                shift 2
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
    
    echo ""
    print_info "================================================"
    print_info "AIpic 局域网访问快速测试"
    print_info "================================================"
    echo ""
    
    # 检查配置
    if ! check_config; then
        echo ""
        print_error "配置检查失败"
        exit 1
    fi
    
    echo ""
    
    # 测试端口
    if test_port "$port"; then
        # 测试服务
        if test_service "$port"; then
            echo ""
            print_success "✅ 所有测试通过!"
            print_info "Web服务正在运行，可以通过局域网访问"
        else
            echo ""
            print_warning "⚠️  Web服务测试失败"
            print_info "请确保服务已启动: ./start_aipic.sh"
        fi
    else
        echo ""
        print_warning "⚠️  端口未在监听"
        print_info "请启动服务: ./start_aipic.sh"
    fi
    
    echo ""
    print_info "下一步:"
    print_info "  1. 启动服务: ./start_aipic.sh"
    print_info "  2. 从其他设备访问上述URL"
    print_info "  3. 如有问题，运行详细测试: ./test_lan_access.sh"
    echo ""
}

# 运行主函数
main "$@"
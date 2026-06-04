#!/usr/bin/env bash

#################################################
# AIpic 缓存清理脚本
# 清理临时文件、缓存和日志，释放磁盘空间
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

# 函数：计算目录大小
get_dir_size() {
    du -sh "$1" 2>/dev/null | cut -f1 || echo "0"
}

# 函数：显示清理前的大小
show_current_usage() {
    print_info "当前磁盘使用情况："
    
    # 项目目录大小
    PROJECT_SIZE=$(get_dir_size ".")
    print_info "项目目录: $PROJECT_SIZE"
    
    # 虚拟环境大小
    if [ -d "venv" ]; then
        VENV_SIZE=$(get_dir_size "venv")
        print_info "虚拟环境: $VENV_SIZE"
    fi
    
    # 模型目录大小
    if [ -d "models" ]; then
        MODELS_SIZE=$(get_dir_size "models")
        print_info "模型文件: $MODELS_SIZE"
    fi
    
    # 输出目录大小
    if [ -d "outputs" ]; then
        OUTPUTS_SIZE=$(get_dir_size "outputs")
        print_info "输出文件: $OUTPUTS_SIZE"
    fi
    
    # 缓存目录大小
    CACHE_SIZE=$(get_dir_size "~/.cache")
    print_info "系统缓存: $CACHE_SIZE"
    
    echo ""
}

# 函数：清理Python缓存
clean_python_cache() {
    print_info "清理Python缓存..."
    
    # 清理__pycache__目录
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # 清理.pyc文件
    find . -name "*.pyc" -delete 2>/dev/null || true
    
    # 清理.pyo文件
    find . -name "*.pyo" -delete 2>/dev/null || true
    
    # 清理.pyd文件
    find . -name "*.pyd" -delete 2>/dev/null || true
    
    # 清理Python编译缓存
    find . -name "*.py,cover" -delete 2>/dev/null || true
    
    print_success "Python缓存清理完成"
}

# 函数：清理日志文件
clean_logs() {
    print_info "清理日志文件..."
    
    # 清理项目日志
    if [ -f "log.txt" ]; then
        LOG_SIZE=$(du -h "log.txt" | cut -f1)
        rm -f log.txt
        print_info "删除日志文件: $LOG_SIZE"
    fi
    
    # 清理调试日志
    find . -name "*.log" -type f -delete 2>/dev/null || true
    find . -name "debug*.txt" -type f -delete 2>/dev/null || true
    find . -name "error*.txt" -type f -delete 2>/dev/null || true
    
    # 清理系统日志（保留最近7天）
    find /var/log -name "*.log" -type f -mtime +7 -delete 2>/dev/null || true
    
    print_success "日志文件清理完成"
}

# 函数：清理临时文件
clean_temp_files() {
    print_info "清理临时文件..."
    
    # 清理系统临时文件
    sudo rm -rf /tmp/* 2>/dev/null || true
    rm -rf /tmp/* 2>/dev/null || true
    
    # 清理用户临时文件
    rm -rf ~/.tmp/* 2>/dev/null || true
    rm -rf ~/tmp/* 2>/dev/null || true
    
    # 清理浏览器缓存
    rm -rf ~/.cache/mozilla/* 2>/dev/null || true
    rm -rf ~/.cache/chromium/* 2>/dev/null || true
    rm -rf ~/.cache/google-chrome/* 2>/dev/null || true
    
    print_success "临时文件清理完成"
}

# 函数：清理下载缓存
clean_download_cache() {
    print_info "清理下载缓存..."
    
    # 清理pip缓存
    if [ -d ~/.cache/pip ]; then
        PIP_CACHE_SIZE=$(get_dir_size ~/.cache/pip)
        rm -rf ~/.cache/pip/*
        print_info "清理pip缓存: $PIP_CACHE_SIZE"
    fi
    
    # 清理torch缓存
    if [ -d ~/.cache/torch ]; then
        TORCH_CACHE_SIZE=$(get_dir_size ~/.cache/torch)
        rm -rf ~/.cache/torch/*
        print_info "清理torch缓存: $TORCH_CACHE_SIZE"
    fi
    
    # 清理huggingface缓存
    if [ -d ~/.cache/huggingface ]; then
        HF_CACHE_SIZE=$(get_dir_size ~/.cache/huggingface)
        # 只清理非模型文件
        find ~/.cache/huggingface -type f -name "*.tmp" -delete 2>/dev/null || true
        find ~/.cache/huggingface -type f -name "*.lock" -delete 2>/dev/null || true
        print_info "清理huggingface缓存: $HF_CACHE_SIZE"
    fi
    
    # 清理apt缓存
    sudo apt clean 2>/dev/null || true
    sudo apt autoclean 2>/dev/null || true
    
    print_success "下载缓存清理完成"
}

# 函数：清理Docker缓存（如果使用）
clean_docker_cache() {
    if command -v docker &> /dev/null; then
        print_info "清理Docker缓存..."
        
        # 停止所有容器
        docker stop $(docker ps -aq) 2>/dev/null || true
        
        # 删除所有停止的容器
        docker rm $(docker ps -aq) 2>/dev/null || true
        
        # 删除所有未使用的镜像
        docker image prune -a -f 2>/dev/null || true
        
        # 删除所有未使用的卷
        docker volume prune -f 2>/dev/null || true
        
        # 删除构建缓存
        docker builder prune -f 2>/dev/null || true
        
        print_success "Docker缓存清理完成"
    fi
}

# 函数：清理旧的内核和包
clean_old_kernels() {
    print_info "清理旧的内核和包..."
    
    # 清理旧的内核
    sudo apt autoremove --purge -y 2>/dev/null || true
    
    # 清理旧的配置文件
    sudo dpkg -l | grep '^rc' | awk '{print $2}' | xargs sudo dpkg --purge 2>/dev/null || true
    
    print_success "旧的内核和包清理完成"
}

# 函数：清理缩略图缓存
clean_thumbnail_cache() {
    print_info "清理缩略图缓存..."
    
    # 清理用户缩略图缓存
    rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
    
    # 清理系统缩略图缓存
    sudo rm -rf /root/.cache/thumbnails/* 2>/dev/null || true
    
    print_success "缩略图缓存清理完成"
}

# 函数：清理浏览器数据
clean_browser_data() {
    print_info "清理浏览器数据..."
    
    # Firefox
    if [ -d ~/.mozilla/firefox ]; then
        for profile in ~/.mozilla/firefox/*.default*; do
            if [ -d "$profile" ]; then
                rm -rf "$profile"/cache2/* 2>/dev/null || true
                rm -rf "$profile"/thumbnails/* 2>/dev/null || true
                rm -rf "$profile"/storage/* 2>/dev/null || true
            fi
        done
    fi
    
    # Chromium/Chrome
    if [ -d ~/.config/chromium ]; then
        rm -rf ~/.config/chromium/Default/Cache/* 2>/dev/null || true
        rm -rf ~/.config/chromium/Default/Code\ Cache/* 2>/dev/null || true
    fi
    
    if [ -d ~/.config/google-chrome ]; then
        rm -rf ~/.config/google-chrome/Default/Cache/* 2>/dev/null || true
        rm -rf ~/.config/google-chrome/Default/Code\ Cache/* 2>/dev/null || true
    fi
    
    print_success "浏览器数据清理完成"
}

# 函数：清理系统日志
clean_system_logs() {
    print_info "清理系统日志..."
    
    # 清理旧的系统日志（保留最近7天）
    sudo find /var/log -type f -name "*.log" -mtime +7 -delete 2>/dev/null || true
    sudo find /var/log -type f -name "*.gz" -delete 2>/dev/null || true
    sudo find /var/log -type f -name "*.1" -delete 2>/dev/null || true
    
    # 清理journal日志（保留最近100MB）
    sudo journalctl --vacuum-size=100M 2>/dev/null || true
    
    # 清理apt日志
    sudo rm -f /var/log/apt/*.log 2>/dev/null || true
    sudo rm -f /var/log/apt/*.log.* 2>/dev/null || true
    
    print_success "系统日志清理完成"
}

# 函数：清理孤儿包
clean_orphan_packages() {
    print_info "清理孤儿包..."
    
    # 使用deborphan查找孤儿包
    if command -v deborphan &> /dev/null; then
        ORPHAN_PACKAGES=$(deborphan)
        if [ -n "$ORPHAN_PACKAGES" ]; then
            print_info "找到孤儿包: $ORPHAN_PACKAGES"
            sudo apt remove --purge -y $ORPHAN_PACKAGES 2>/dev/null || true
        fi
    fi
    
    print_success "孤儿包清理完成"
}

# 函数：显示清理结果
show_cleanup_results() {
    print_info "清理完成！"
    echo ""
    
    # 显示清理后的磁盘使用情况
    print_info "清理后的磁盘使用情况："
    
    # 项目目录大小
    PROJECT_SIZE=$(get_dir_size ".")
    print_info "项目目录: $PROJECT_SIZE"
    
    # 虚拟环境大小
    if [ -d "venv" ]; then
        VENV_SIZE=$(get_dir_size "venv")
        print_info "虚拟环境: $VENV_SIZE"
    fi
    
    # 可用磁盘空间
    FREE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
    print_info "可用空间: $FREE_SPACE"
    
    echo ""
    print_success "建议定期运行此脚本以保持系统清洁"
}

# 函数：安全清理（不删除重要文件）
safe_cleanup() {
    print_info "开始安全清理..."
    echo ""
    
    show_current_usage
    echo ""
    
    # 询问确认
    read -p "是否继续清理？(y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "清理已取消"
        exit 0
    fi
    
    # 执行清理步骤
    clean_python_cache
    clean_logs
    clean_temp_files
    clean_download_cache
    clean_thumbnail_cache
    
    echo ""
    show_cleanup_results
}

# 函数：深度清理（删除更多文件）
deep_cleanup() {
    print_warning "深度清理将删除更多文件，包括浏览器数据和系统日志"
    print_warning "请确保已保存所有重要数据！"
    echo ""
    
    show_current_usage
    echo ""
    
    # 询问确认
    read -p "是否继续深度清理？(y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "清理已取消"
        exit 0
    fi
    
    # 执行深度清理步骤
    clean_python_cache
    clean_logs
    clean_temp_files
    clean_download_cache
    clean_docker_cache
    clean_old_kernels
    clean_thumbnail_cache
    clean_browser_data
    clean_system_logs
    clean_orphan_packages
    
    echo ""
    show_cleanup_results
}

# 函数：清理输出目录
clean_outputs() {
    print_warning "这将删除所有生成的图像文件！"
    echo ""
    
    if [ -d "outputs" ]; then
        OUTPUTS_SIZE=$(get_dir_size "outputs")
        print_info "输出目录大小: $OUTPUTS_SIZE"
        
        read -p "是否删除输出目录中的所有文件？(y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf outputs/*
            print_success "输出目录已清空"
        else
            print_info "保留输出文件"
        fi
    else
        print_info "输出目录不存在"
    fi
}

# 函数：清理模型缓存（保留模型文件）
clean_model_cache() {
    print_info "清理模型缓存..."
    
    if [ -d "models" ]; then
        # 只清理缓存文件，不删除模型
        find models -name "*.cache" -type f -delete 2>/dev/null || true
        find models -name "*.tmp" -type f -delete 2>/dev/null || true
        find models -name "*.lock" -type f -delete 2>/dev/null || true
        
        # 清理临时下载文件
        find models -name "*.part" -type f -delete 2>/dev/null || true
        find models -name "*.temp" -type f -delete 2>/dev/null || true
        
        print_success "模型缓存清理完成"
    else
        print_info "模型目录不存在"
    fi
}

# 函数：显示帮助
show_help() {
    echo "AIpic 缓存清理脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  safe          安全清理（默认）"
    echo "  deep          深度清理（包括浏览器数据和系统日志）"
    echo "  outputs       清理输出目录"
    echo "  models        清理模型缓存"
    echo "  logs          只清理日志文件"
    echo "  cache         只清理下载缓存"
    echo "  help          显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 safe        # 安全清理（推荐）"
    echo "  $0 deep        # 深度清理"
    echo "  $0 outputs     # 清理输出目录"
    echo "  $0 models      # 清理模型缓存"
    echo ""
    echo "安全清理包括:"
    echo "  - Python缓存"
    echo "  - 日志文件"
    echo "  - 临时文件"
    echo "  - 下载缓存"
    echo "  - 缩略图缓存"
    echo ""
    echo "深度清理额外包括:"
    echo "  - Docker缓存"
    echo "  - 旧的内核和包"
    echo "  - 浏览器数据"
    echo "  - 系统日志"
    echo "  - 孤儿包"
}

# 主函数
main() {
    echo ""
    print_success "================================================"
    print_success "AIpic 缓存清理工具"
    print_success "================================================"
    echo ""
    
    # 检查当前目录
    if [ ! -f "webui.py" ] && [ ! -f "launch.py" ]; then
        print_error "请在AIpic项目目录中运行此脚本"
        print_info "当前目录: $(pwd)"
        exit 1
    fi
    
    # 解析参数
    case "${1:-safe}" in
        safe)
            safe_cleanup
            ;;
        deep)
            deep_cleanup
            ;;
        outputs)
            clean_outputs
            ;;
        models)
            clean_model_cache
            ;;
        logs)
            clean_logs
            ;;
        cache)
            clean_download_cache
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
    print_success "清理完成！"
}

# 运行主函数
main "$@"
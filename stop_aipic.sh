#!/usr/bin/env bash

#################################################
# AIpic Stop Script
# Safely stop the AIpic Web UI
#################################################

set -e

# Configuration
PORT=7860

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function: print colored output
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

# Function: check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function: get process ID on port
get_pid_on_port() {
    local port=$1
    local pid=""
    
    # Try lsof first
    if command_exists lsof; then
        pid=$(lsof -ti:$port 2>/dev/null || echo "")
    # Try netstat
    elif command_exists netstat; then
        pid=$(netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -n1)
    # Try ss
    elif command_exists ss; then
        pid=$(ss -tulpn 2>/dev/null | grep ":$port " | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 | head -n1)
    fi
    
    echo "$pid"
}

# Function: get process info
get_process_info() {
    local pid=$1
    
    if [ -z "$pid" ] || [ "$pid" = "-" ]; then
        echo "Unknown"
        return
    fi
    
    # Try to get process name
    if [ -f "/proc/$pid/comm" ]; then
        cat "/proc/$pid/comm"
    elif command_exists ps; then
        ps -p "$pid" -o comm= 2>/dev/null || echo "Unknown"
    else
        echo "Unknown"
    fi
}

# Function: kill process
kill_process() {
    local pid=$1
    local force=$2
    
    if [ -z "$pid" ]; then
        return 1
    fi
    
    # Check if process exists
    if ! ps -p "$pid" >/dev/null 2>&1; then
        print_warning "Process $pid does not exist"
        return 1
    fi
    
    # Get process info
    local process_name=$(get_process_info "$pid")
    
    if [ "$force" = "true" ]; then
        print_info "Force killing process $pid ($process_name)..."
        kill -9 "$pid" 2>/dev/null
    else
        print_info "Stopping process $pid ($process_name)..."
        kill "$pid" 2>/dev/null
    fi
    
    # Wait for process to terminate
    local timeout=10
    local count=0
    
    while ps -p "$pid" >/dev/null 2>&1 && [ $count -lt $timeout ]; do
        sleep 1
        count=$((count + 1))
    done
    
    if ps -p "$pid" >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Function: stop systemd service
stop_systemd_service() {
    if systemctl is-active --quiet aipic 2>/dev/null; then
        print_info "Stopping systemd service: aipic"
        sudo systemctl stop aipic
        
        # Wait for service to stop
        local timeout=10
        local count=0
        
        while systemctl is-active --quiet aipic 2>/dev/null && [ $count -lt $timeout ]; do
            sleep 1
            count=$((count + 1))
        done
        
        if systemctl is-active --quiet aipic 2>/dev/null; then
            print_warning "Systemd service still running, forcing stop..."
            sudo systemctl kill aipic
            sleep 2
        fi
        
        if ! systemctl is-active --quiet aipic 2>/dev/null; then
            print_success "Systemd service stopped"
            return 0
        else
            print_error "Failed to stop systemd service"
            return 1
        fi
    fi
    
    return 0
}

# Function: check for multiple instances
check_multiple_instances() {
    local port=$1
    local pids=()
    
    # Get all PIDs on port
    if command_exists lsof; then
        pids=($(lsof -ti:$port 2>/dev/null))
    elif command_exists netstat; then
        pids=($(netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1))
    elif command_exists ss; then
        pids=($(ss -tulpn 2>/dev/null | grep ":$port " | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2))
    fi
    
    if [ ${#pids[@]} -gt 1 ]; then
        print_warning "Multiple processes found on port $PORT:"
        for pid in "${pids[@]}"; do
            if [ -n "$pid" ] && [ "$pid" != "-" ]; then
                local process_name=$(get_process_info "$pid")
                print_warning "  PID $pid: $process_name"
            fi
        done
        return 0
    fi
    
    return 1
}

# Function: clean up temporary files
cleanup_temp_files() {
    print_info "Cleaning up temporary files..."
    
    # Remove lock files
    find . -name "*.lock" -type f -delete 2>/dev/null || true
    
    # Remove Python cache
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    
    # Remove empty directories
    find . -type d -empty -delete 2>/dev/null || true
    
    print_success "Temporary files cleaned up"
}

# Function: display process tree
display_process_tree() {
    local pid=$1
    
    if [ -z "$pid" ]; then
        return
    fi
    
    if command_exists pstree; then
        print_info "Process tree for PID $pid:"
        pstree -p "$pid" 2>/dev/null || true
    elif command_exists ps; then
        print_info "Child processes for PID $pid:"
        ps -ef | awk -v pid="$pid" '$3 == pid {print $2 " " $8}' | while read child_pid cmd; do
            print_info "  PID $child_pid: $cmd"
        done
    fi
}

# Main function
main() {
    echo ""
    print_info "================================================"
    print_info "Stopping AIpic Web UI"
    print_info "================================================"
    echo ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root. This is not recommended."
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Exiting..."
            exit 0
        fi
    fi
    
    # Check for custom port in webui-user.sh
    if [ -f "webui-user.sh" ]; then
        source ./webui-user.sh
        # Extract port using parameter expansion (more compatible than regex)
        if [[ "$COMMANDLINE_ARGS" == *"--port"* ]]; then
            # Try to extract port number
            PORT_TEMP=$(echo "$COMMANDLINE_ARGS" | grep -o -- "--port[= ][0-9]*" | grep -o "[0-9]*" | head -1)
            if [ -n "$PORT_TEMP" ] && [ "$PORT_TEMP" -ge 1024 ] && [ "$PORT_TEMP" -le 65535 ]; then
                PORT="$PORT_TEMP"
                print_info "Using custom port from webui-user.sh: $PORT"
            fi
        fi
    fi
    
    # Check for multiple instances
    if check_multiple_instances "$PORT"; then
        echo ""
        print_warning "Multiple AIpic instances detected!"
        read -p "Stop all instances? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Exiting..."
            exit 0
        fi
    fi
    
    # Try to stop systemd service first
    stop_systemd_service
    
    # Get process ID
    local pid=$(get_pid_on_port "$PORT")
    
    if [ -z "$pid" ]; then
        print_info "No AIpic process found on port $PORT"
        
        # Check if running on different port
        local all_pids=$(ps aux | grep -E "python.*launch\.py|python.*webui\.py" | grep -v grep | awk '{print $2}')
        if [ -n "$all_pids" ]; then
            print_info "Found potential AIpic processes:"
            for p in $all_pids; do
                local cmd=$(ps -p "$p" -o command= 2>/dev/null || echo "Unknown")
                print_info "  PID $p: $cmd"
            done
            
            read -p "Stop all AIpic processes? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                for p in $all_pids; do
                    kill_process "$p" "false"
                done
                print_success "All AIpic processes stopped"
            else
                print_info "Exiting..."
                exit 0
            fi
        else
            print_success "No AIpic processes found"
        fi
    else
        # Display process info
        local process_name=$(get_process_info "$pid")
        print_info "Found AIpic process on port $PORT:"
        print_info "  PID: $pid"
        print_info "  Process: $process_name"
        
        # Display process tree
        display_process_tree "$pid"
        echo ""
        
        # Ask for confirmation
        read -p "Stop process $pid? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Exiting..."
            exit 0
        fi
        
        # Try graceful shutdown first
        print_info "Attempting graceful shutdown..."
        if kill_process "$pid" "false"; then
            print_success "Process $pid stopped gracefully"
        else
            print_warning "Graceful shutdown failed, forcing termination..."
            if kill_process "$pid" "true"; then
                print_success "Process $pid force stopped"
            else
                print_error "Failed to stop process $pid"
                print_info "You may need to stop it manually: sudo kill -9 $pid"
                exit 1
            fi
        fi
        
        # Verify process is stopped
        sleep 2
        if ps -p "$pid" >/dev/null 2>&1; then
            print_error "Process $pid is still running!"
            print_info "Trying one more time..."
            kill -9 "$pid" 2>/dev/null
            sleep 1
            if ps -p "$pid" >/dev/null 2>&1; then
                print_error "Failed to stop process $pid"
                print_info "Please stop it manually: sudo kill -9 $pid"
                exit 1
            fi
        fi
        
        print_success "AIpic Web UI stopped successfully"
    fi
    
    # Clean up temporary files
    cleanup_temp_files
    
    # Check if port is now free
    sleep 1
    if get_pid_on_port "$PORT" >/dev/null; then
        print_warning "Port $PORT is still in use by another process"
        local new_pid=$(get_pid_on_port "$PORT")
        local new_process=$(get_process_info "$new_pid")
        print_info "  PID: $new_pid"
        print_info "  Process: $new_process"
    else
        print_success "Port $PORT is now free"
    fi
    
    echo ""
    print_info "================================================"
    print_success "Stop process completed"
    print_info "================================================"
    echo ""
    
    # Show restart instructions
    print_info "To restart AIpic Web UI:"
    print_info "  ./start_aipic.sh"
    echo ""
    
    # Show systemd instructions
    if systemctl list-unit-files | grep -q aipic.service; then
        print_info "To restart systemd service:"
        print_info "  sudo systemctl start aipic"
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h      Show this help message"
        echo "  --port PORT     Stop process on specific port (default: 7860)"
        echo "  --force         Force stop without confirmation"
        echo "  --all           Stop all AIpic processes"
        echo "  --clean         Clean up temporary files after stopping"
        echo ""
        echo "Examples:"
        echo "  $0              # Stop AIpic on default port 7860"
        echo "  $0 --port 7861  # Stop AIpic on port 7861"
        echo "  $0 --force      # Force stop without confirmation"
        echo "  $0 --all        # Stop all AIpic processes"
        exit 0
        ;;
    --port)
        if [ -n "$2" ]; then
            PORT="$2"
            shift 2
        else
            print_error "Port number required for --port option"
            exit 1
        fi
        ;;
    --force)
        FORCE_MODE=true
        shift
        ;;
    --all)
        STOP_ALL=true
        shift
        ;;
    --clean)
        CLEANUP=true
        shift
        ;;
esac

# Run main function
main "$@"
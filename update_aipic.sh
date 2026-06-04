#!/usr/bin/env bash

#################################################
# AIpic Update Script
# Update AIpic Web UI and dependencies
#################################################

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
BACKUP_DIR="$SCRIPT_DIR/backups"
LOG_FILE="$SCRIPT_DIR/update.log"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function: print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$LOG_FILE"
}

# Function: check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function: check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root"
        exit 1
    fi
}

# Function: check virtual environment
check_virtualenv() {
    if [ ! -d "$VENV_DIR" ]; then
        print_error "Virtual environment not found at $VENV_DIR"
        print_info "Please run the installation script first: ./install_ubuntu_24.sh"
        exit 1
    fi
    
    if [ ! -f "$VENV_DIR/bin/activate" ]; then
        print_error "Virtual environment activation script not found"
        exit 1
    fi
    
    return 0
}

# Function: create backup
create_backup() {
    local backup_type=$1
    
    print_info "Creating backup..."
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Generate backup filename with timestamp
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/aipic_backup_${backup_type}_${timestamp}.tar.gz"
    
    # Create backup based on type
    case "$backup_type" in
        "full")
            tar -czf "$backup_file" \
                --exclude="venv" \
                --exclude="__pycache__" \
                --exclude="*.pyc" \
                --exclude="*.log" \
                --exclude="backups" \
                . 2>/dev/null || true
            ;;
        "config")
            tar -czf "$backup_file" \
                config.json \
                webui-user.sh \
                configs/ \
                embeddings/ \
                styles.csv 2>/dev/null || true
            ;;
        "models")
            tar -czf "$backup_file" \
                models/ \
                embeddings/ 2>/dev/null || true
            ;;
        *)
            print_error "Unknown backup type: $backup_type"
            return 1
            ;;
    esac
    
    if [ -f "$backup_file" ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        print_success "Backup created: $backup_file ($size)"
        return 0
    else
        print_error "Failed to create backup"
        return 1
    fi
}

# Function: check for updates
check_updates() {
    print_info "Checking for updates..."
    
    # Check git status
    if [ ! -d ".git" ]; then
        print_warning "Not a git repository, skipping update check"
        return 1
    fi
    
    # Fetch latest changes
    git fetch origin 2>> "$LOG_FILE"
    
    # Check if behind remote
    LOCAL_COMMIT=$(git rev-parse HEAD)
    REMOTE_COMMIT=$(git rev-parse origin/HEAD)
    
    if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
        print_info "Updates available:"
        print_info "  Local:  $(git log -1 --format='%h - %s' HEAD)"
        print_info "  Remote: $(git log -1 --format='%h - %s' origin/HEAD)"
        return 0
    else
        print_success "Already up to date"
        return 1
    fi
}

# Function: update repository
update_repository() {
    print_info "Updating repository..."
    
    # Check if there are local changes
    if git status --porcelain | grep -q "^ M"; then
        print_warning "Local modifications detected"
        read -p "Stash local changes? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git stash 2>> "$LOG_FILE"
            print_info "Local changes stashed"
        else
            print_info "Keeping local changes"
        fi
    fi
    
    # Pull latest changes
    if git pull --rebase 2>> "$LOG_FILE"; then
        print_success "Repository updated successfully"
        return 0
    else
        print_error "Failed to update repository"
        
        # Try alternative method
        print_info "Trying alternative update method..."
        git fetch origin 2>> "$LOG_FILE"
        git reset --hard origin/HEAD 2>> "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            print_success "Repository updated with reset"
            return 0
        else
            print_error "Failed to update repository"
            return 1
        fi
    fi
}

# Function: update Python dependencies
update_dependencies() {
    print_info "Updating Python dependencies..."
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Backup current dependencies
    pip freeze > "$BACKUP_DIR/requirements_backup_$(date '+%Y%m%d_%H%M%S').txt" 2>> "$LOG_FILE"
    
    # Update pip
    print_info "Updating pip..."
    pip install --upgrade pip 2>> "$LOG_FILE"
    
    # Update requirements
    if [ -f "requirements.txt" ]; then
        print_info "Updating requirements from requirements.txt..."
        pip install --upgrade -r requirements.txt 2>> "$LOG_FILE"
    fi
    
    # Update PyTorch if CUDA is available
    if python -c "import torch; print(torch.cuda.is_available())" 2>/dev/null | grep -q "True"; then
        print_info "Updating PyTorch with CUDA support..."
        pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 2>> "$LOG_FILE"
    else
        print_info "Updating PyTorch (CPU only)..."
        pip install --upgrade torch torchvision torchaudio 2>> "$LOG_FILE"
    fi
    
    # Update xformers if installed
    if pip list | grep -q xformers; then
        print_info "Updating xformers..."
        pip install --upgrade xformers 2>> "$LOG_FILE"
    fi
    
    # Clean up old packages
    print_info "Cleaning up old packages..."
    pip cache purge 2>> "$LOG_FILE" || true
    
    deactivate
    
    print_success "Dependencies updated successfully"
    return 0
}

# Function: update extensions
update_extensions() {
    print_info "Updating extensions..."
    
    if [ ! -d "extensions" ]; then
        print_info "No extensions directory found"
        return 0
    fi
    
    local updated=0
    local failed=0
    
    for ext_dir in extensions/*/; do
        if [ -d "$ext_dir/.git" ]; then
            local ext_name=$(basename "$ext_dir")
            print_info "Updating extension: $ext_name"
            
            cd "$ext_dir"
            if git pull 2>> "$LOG_FILE"; then
                print_success "  $ext_name: Updated"
                updated=$((updated + 1))
            else
                print_warning "  $ext_name: Update failed"
                failed=$((failed + 1))
            fi
            cd - > /dev/null
        fi
    done
    
    print_info "Extensions update summary:"
    print_info "  Updated: $updated"
    if [ $failed -gt 0 ]; then
        print_warning "  Failed: $failed"
    fi
    
    return 0
}

# Function: update models (optional)
update_models() {
    print_info "Checking for model updates..."
    
    # This is a placeholder for model update logic
    # In practice, models are usually updated manually
    
    print_info "Model updates are typically done manually."
    print_info "Check the following for updates:"
    print_info "  - models/Stable-diffusion/"
    print_info "  - models/VAE/"
    print_info "  - models/Lora/"
    print_info "  - embeddings/"
    
    return 0
}

# Function: verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    local errors=0
    
    # Check Python version
    PYTHON_VERSION=$(python --version 2>&1)
    print_info "Python: $PYTHON_VERSION"
    
    # Check PyTorch
    if python -c "import torch" 2>> "$LOG_FILE"; then
        TORCH_VERSION=$(python -c "import torch; print(torch.__version__)" 2>> "$LOG_FILE")
        print_success "PyTorch: $TORCH_VERSION"
        
        # Check CUDA
        if python -c "import torch; print(torch.cuda.is_available())" 2>> "$LOG_FILE" | grep -q "True"; then
            CUDA_VERSION=$(python -c "import torch; print(torch.version.cuda)" 2>> "$LOG_FILE")
            print_success "CUDA: $CUDA_VERSION"
        else
            print_warning "CUDA: Not available (running in CPU mode)"
        fi
    else
        print_error "PyTorch: Not installed"
        errors=$((errors + 1))
    fi
    
    # Check other critical dependencies
    for package in "gradio" "numpy" "PIL" "cv2" "transformers"; do
        if python -c "import $package" 2>> "$LOG_FILE"; then
            print_success "$package: OK"
        else
            print_error "$package: Missing"
            errors=$((errors + 1))
        fi
    done
    
    deactivate
    
    if [ $errors -eq 0 ]; then
        print_success "Installation verification passed"
        return 0
    else
        print_error "Installation verification failed with $errors error(s)"
        return 1
    fi
}

# Function: show update summary
show_summary() {
    echo ""
    print_success "================================================"
    print_success "Update Summary"
    print_success "================================================"
    echo ""
    
    # Show git status
    if [ -d ".git" ]; then
        print_info "Repository:"
        print_info "  Branch: $(git branch --show-current)"
        print_info "  Commit: $(git log -1 --format='%h - %s' HEAD)"
        print_info "  Date: $(git log -1 --format='%cd' HEAD)"
    fi
    
    # Show Python info
    source "$VENV_DIR/bin/activate"
    print_info "Python Environment:"
    print_info "  Python: $(python --version 2>&1)"
    print_info "  PyTorch: $(python -c "import torch; print(torch.__version__)" 2>> "$LOG_FILE")"
    deactivate
    
    # Show backup info
    if [ -d "$BACKUP_DIR" ]; then
        local latest_backup=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -n1)
        if [ -n "$latest_backup" ]; then
            local backup_size=$(du -h "$latest_backup" | cut -f1)
            print_info "Latest Backup: $(basename "$latest_backup") ($backup_size)"
        fi
    fi
    
    # Show log file location
    print_info "Log File: $LOG_FILE"
    
    echo ""
    print_info "Next Steps:"
    print_info "1. Restart the Web UI: ./start_aipic.sh"
    print_info "2. Check for any configuration changes"
    print_info "3. Test the updated installation"
    
    echo ""
    print_success "Update completed successfully!"
}

# Function: rollback update
rollback_update() {
    print_error "Update failed, attempting rollback..."
    
    # Find latest backup
    local latest_backup=$(ls -t "$BACKUP_DIR"/aipic_backup_full_*.tar.gz 2>/dev/null | head -n1)
    
    if [ -n "$latest_backup" ]; then
        print_info "Restoring from backup: $latest_backup"
        
        # Extract backup
        tar -xzf "$latest_backup" -C / 2>> "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            print_success "Rollback successful"
            return 0
        else
            print_error "Rollback failed"
            return 1
        fi
    else
        print_error "No backup found for rollback"
        return 1
    fi
}

# Main function
main() {
    echo ""
    print_info "================================================"
    print_info "AIpic Update Tool"
    print_info "================================================"
    echo ""
    
    # Initialize log file
    echo "=== AIpic Update Log ===" > "$LOG_FILE"
    echo "Start time: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "=========================" >> "$LOG_FILE"
    
    # Check prerequisites
    check_root
    check_virtualenv
    
    # Ask for confirmation
    print_warning "This will update AIpic Web UI and all dependencies."
    print_warning "The Web UI will need to be restarted after update."
    echo ""
    
    read -p "Create backup before updating? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_backup "full"
    fi
    
    echo ""
    read -p "Continue with update? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Update cancelled"
        exit 0
    fi
    
    # Start update process
    local update_success=true
    
    # Check for updates
    if ! check_updates; then
        read -p "No updates found. Force update? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Update cancelled"
            exit 0
        fi
    fi
    
    # Update repository
    if ! update_repository; then
        update_success=false
    fi
    
    # Update dependencies
    if $update_success; then
        if ! update_dependencies; then
            update_success=false
        fi
    fi
    
    # Update extensions
    if $update_success; then
        update_extensions
    fi
    
    # Update models (optional)
    if $update_success; then
        read -p "Check for model updates? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_models
        fi
    fi
    
    # Verify installation
    if $update_success; then
        if ! verify_installation; then
            print_warning "Installation verification failed"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                update_success=false
            fi
        fi
    fi
    
    # Handle update result
    if $update_success; then
        show_summary
    else
        print_error "Update failed"
        
        read -p "Attempt rollback? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if rollback_update; then
                print_success "Rollback completed"
            else
                print_error "Rollback failed. Manual intervention required."
            fi
        fi
        
        print_info "See log file for details: $LOG_FILE"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h          Show this help message"
        echo "  --backup TYPE       Create backup before update (full/config/models)"
        echo "  --no-backup         Skip backup"
        echo "  --force             Force update even if no updates available"
        echo "  --skip-verify       Skip installation verification"
        echo "  --skip-extensions   Skip extension updates"
        echo "  --dry-run           Check for updates without applying"
        echo ""
        echo "Examples:"
        echo "  $0                  # Normal update with backup prompt"
        echo "  $0 --backup full    # Create full backup before update"
        echo "  $0 --no-backup      # Update without backup"
        echo "  $0 --force          # Force update even if no updates"
        echo "  $0 --dry-run        # Check for updates only"
        exit 0
        ;;
    --backup)
        if [ -n "$2" ]; then
            BACKUP_TYPE="$2"
            shift 2
        else
            print_error "Backup type required for --backup option"
            exit 1
        fi
        ;;
    --no-backup)
        NO_BACKUP=true
        shift
        ;;
    --force)
        FORCE_UPDATE=true
        shift
        ;;
    --skip-verify)
        SKIP_VERIFY=true
        shift
        ;;
    --skip-extensions)
        SKIP_EXTENSIONS=true
        shift
        ;;
    --dry-run)
        DRY_RUN=true
        shift
        ;;
esac

# Run main function
main "$@"
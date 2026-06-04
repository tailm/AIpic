#!/usr/bin/env bash

#################################################
# AIpic - Stable Diffusion Web UI
# Ubuntu 24.04 Installation Script
# Optimized for Python 3.13 and NVIDIA RTX 4070 16GB
#################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME"
CLONE_DIR="AIpic"
PYTHON_CMD="python3.13"
VENV_DIR="venv"
PORT=7860

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system requirements
check_system_requirements() {
    print_info "Checking system requirements..."
    
    # Check OS
    if ! grep -q "Ubuntu 24.04" /etc/os-release 2>/dev/null; then
        print_warning "This script is optimized for Ubuntu 24.04. Other versions may work but are not tested."
    fi
    
    # Check Python version
    if command_exists "$PYTHON_CMD"; then
        PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
        print_info "Found Python $PYTHON_VERSION"
        
        # Check if Python 3.13 or higher
        if [[ "$PYTHON_VERSION" < "3.13" ]]; then
            print_error "Python 3.13 or higher is required. Found $PYTHON_VERSION"
            print_info "To install Python 3.13:"
            print_info "  sudo add-apt-repository ppa:deadsnakes/ppa"
            print_info "  sudo apt update"
            print_info "  sudo apt install python3.13 python3.13-venv python3.13-dev"
            exit 1
        fi
    else
        print_error "Python 3.13 not found. Please install it first:"
        print_info "  sudo add-apt-repository ppa:deadsnakes/ppa"
        print_info "  sudo apt update"
        print_info "  sudo apt install python3.13 python3.13-venv python3.13-dev"
        exit 1
    fi
    
    # Check GPU
    if command_exists nvidia-smi; then
        print_info "Checking NVIDIA GPU..."
        GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits)
        if [[ -n "$GPU_INFO" ]]; then
            GPU_NAME=$(echo "$GPU_INFO" | cut -d',' -f1)
            GPU_MEMORY=$(echo "$GPU_INFO" | cut -d',' -f2)
            print_info "Found GPU: $GPU_NAME with ${GPU_MEMORY}MB VRAM"
            
            # Check if it's RTX 4070
            if echo "$GPU_NAME" | grep -qi "RTX 4070"; then
                print_success "NVIDIA RTX 4070 detected (${GPU_MEMORY}MB VRAM)"
            else
                print_warning "GPU detected: $GPU_NAME (${GPU_MEMORY}MB VRAM)"
                print_warning "This script is optimized for RTX 4070 but should work with other NVIDIA GPUs"
            fi
        else
            print_warning "No NVIDIA GPU detected or nvidia-smi not working properly"
        fi
    else
        print_warning "nvidia-smi not found. Running in CPU mode."
        print_warning "For GPU acceleration, install NVIDIA drivers:"
        print_info "  sudo ubuntu-drivers autoinstall"
        print_info "  sudo apt install nvidia-driver-550"
    fi
    
    # Check disk space
    DISK_SPACE=$(df -h "$INSTALL_DIR" | awk 'NR==2 {print $4}')
    print_info "Available disk space in $INSTALL_DIR: $DISK_SPACE"
    
    if [[ $(df -k "$INSTALL_DIR" | awk 'NR==2 {print $4}') -lt 20971520 ]]; then
        print_warning "Low disk space (less than 20GB). Installation may fail."
    fi
    
    # Check RAM
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    print_info "Total RAM: ${TOTAL_RAM}GB"
    
    if [[ $TOTAL_RAM -lt 16 ]]; then
        print_warning "Recommended minimum RAM is 16GB. You have ${TOTAL_RAM}GB."
    fi
}

# Function to install system dependencies
install_system_dependencies() {
    print_info "Installing system dependencies..."
    
    # Update package list
    sudo apt update
    
    # Install essential build tools
    sudo apt install -y \
        build-essential \
        git \
        wget \
        curl \
        cmake \
        pkg-config \
        libssl-dev \
        libffi-dev \
        libreadline-dev \
        libsqlite3-dev \
        libbz2-dev \
        libncurses5-dev \
        libgdbm-dev \
        libnss3-dev \
        libssl-dev \
        libreadline-dev \
        libffi-dev \
        liblzma-dev \
        tk-dev \
        uuid-dev
    
    # Install Python development packages
    sudo apt install -y \
        python3.13-dev \
        python3.13-venv \
        python3.13-distutils \
        python3-pip
    
    # Install multimedia libraries
    sudo apt install -y \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        libopenblas-dev \
        liblapack-dev \
        libatlas-base-dev \
        gfortran
    
    # Install image processing libraries
    sudo apt install -y \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libwebp-dev \
        libopenexr-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev
    
    # Install font packages
    sudo apt install -y \
        fonts-dejavu \
        fonts-liberation \
        fonts-noto \
        fonts-roboto \
        fonts-ubuntu \
        ttf-mscorefonts-installer
    
    print_success "System dependencies installed"
}

# Function to install NVIDIA drivers and CUDA
install_nvidia_drivers() {
    print_info "Installing NVIDIA drivers and CUDA..."
    
    # Check if NVIDIA drivers are already installed
    if command_exists nvidia-smi; then
        NVIDIA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1)
        print_info "NVIDIA driver version: $NVIDIA_VERSION"
        
        # Check if driver version is compatible
        if [[ "$NVIDIA_VERSION" < "550" ]]; then
            print_warning "NVIDIA driver version $NVIDIA_VERSION may be outdated for RTX 4070"
            print_info "Recommended driver version: 550 or higher"
        fi
    else
        print_info "Installing NVIDIA drivers..."
        
        # Add NVIDIA repository
        sudo add-apt-repository -y ppa:graphics-drivers/ppa
        sudo apt update
        
        # Install NVIDIA driver
        sudo apt install -y nvidia-driver-550
        
        print_info "NVIDIA driver installed. Please reboot your system."
        print_info "After reboot, run this script again to continue installation."
        exit 0
    fi
    
    # Install CUDA Toolkit (if not already installed)
    if ! command_exists nvcc; then
        print_info "Installing CUDA Toolkit..."
        
        # Download and install CUDA
        wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
        sudo dpkg -i cuda-keyring_1.1-1_all.deb
        sudo apt update
        sudo apt install -y cuda-toolkit-12-4
        
        # Add CUDA to PATH
        echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
        source ~/.bashrc
        
        print_success "CUDA Toolkit installed"
    else
        CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $6}')
        print_info "CUDA version: $CUDA_VERSION"
    fi
    
    # Install cuDNN
    print_info "Checking cuDNN installation..."
    if [ ! -f /usr/include/cudnn_version.h ]; then
        print_warning "cuDNN not found. Please install cuDNN for optimal performance:"
        print_info "1. Visit: https://developer.nvidia.com/cudnn"
        print_info "2. Download cuDNN for CUDA 12.x"
        print_info "3. Follow installation instructions"
    else
        print_info "cuDNN is installed"
    fi
}

# Function to clone repository
clone_repository() {
    print_info "Cloning AIpic repository..."
    
    cd "$INSTALL_DIR"
    
    if [ -d "$CLONE_DIR" ]; then
        print_warning "Directory $CLONE_DIR already exists"
        read -p "Do you want to update existing installation? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$CLONE_DIR"
            git pull
            print_success "Repository updated"
        else
            print_info "Using existing installation"
        fi
    else
        git clone https://github.com/tailm/AIpic.git "$CLONE_DIR"
        print_success "Repository cloned"
    fi
    
    cd "$CLONE_DIR"
}

# Function to create Python virtual environment
setup_python_environment() {
    print_info "Setting up Python virtual environment..."
    
    cd "$INSTALL_DIR/$CLONE_DIR"
    
    # Remove existing venv if exists
    if [ -d "$VENV_DIR" ]; then
        print_warning "Virtual environment already exists"
        read -p "Do you want to recreate it? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$VENV_DIR"
            print_info "Old virtual environment removed"
        fi
    fi
    
    # Create new virtual environment
    if [ ! -d "$VENV_DIR" ]; then
        "$PYTHON_CMD" -m venv "$VENV_DIR"
        print_success "Virtual environment created"
    fi
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Upgrade pip
    pip install --upgrade pip setuptools wheel
    
    print_success "Python environment setup complete"
}

# Function to install Python dependencies
install_python_dependencies() {
    print_info "Installing Python dependencies..."
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Install PyTorch with CUDA 12.1 support for RTX 4070
    print_info "Installing PyTorch with CUDA 12.1 support..."
    pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121
    
    # Install other dependencies from requirements.txt
    print_info "Installing requirements from requirements.txt..."
    pip install -r requirements.txt
    
    # Install additional dependencies for RTX 4070
    print_info "Installing additional dependencies for RTX 4070..."
    pip install \
        xformers \
        triton \
        nvidia-cudnn-cu12 \
        nvidia-cublas-cu12 \
        nvidia-cusparse-cu12 \
        nvidia-cusolver-cu12 \
        nvidia-cufft-cu12 \
        nvidia-curand-cu12 \
        nvidia-cusparse-cu12 \
        nvidia-nvtx-cu12 \
        nvidia-nvjitlink-cu12
    
    # Install performance optimizations
    pip install \
        flash-attn \
        ninja \
        packaging
    
    print_success "Python dependencies installed"
}

# Function to download models
download_models() {
    print_info "Setting up model directories..."
    
    # Create model directories
    mkdir -p models/Stable-diffusion
    mkdir -p models/Lora
    mkdir -p models/VAE
    mkdir -p models/ESRGAN
    mkdir -p models/GFPGAN
    mkdir -p models/Codeformer
    mkdir -p embeddings
    mkdir -p hypernetworks
    
    print_info "Model directories created"
    
    # Check if models already exist
    MODEL_COUNT=$(find models/Stable-diffusion -name "*.safetensors" -o -name "*.ckpt" 2>/dev/null | wc -l)
    
    if [ "$MODEL_COUNT" -eq 0 ]; then
        print_warning "No Stable Diffusion models found"
        print_info "Would you like to download a model? (Recommended for first-time installation)"
        read -p "Download Stable Diffusion 1.5 model? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Downloading Stable Diffusion 1.5 model..."
            
            # Download SD 1.5 model
            wget -O models/Stable-diffusion/v1-5-pruned-emaonly.safetensors \
                https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors
            
            print_success "Model downloaded to models/Stable-diffusion/"
        fi
    else
        print_info "Found $MODEL_COUNT model(s) in models/Stable-diffusion/"
    fi
    
    # Download VAE if not exists
    if [ ! -f "models/VAE/vae-ft-mse-840000-ema-pruned.safetensors" ]; then
        print_info "Downloading VAE model..."
        wget -O models/VAE/vae-ft-mse-840000-ema-pruned.safetensors \
            https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors
    fi
}

# Function to configure system
configure_system() {
    print_info "Configuring system for optimal performance..."
    
    # Create configuration file if not exists
    if [ ! -f "config.json" ]; then
        cat > config.json << EOF
{
    "samples_save": true,
    "samples_format": "png",
    "grid_save": true,
    "grid_format": "png",
    "grid_extended_filename": false,
    "grid_only_if_multiple": true,
    "grid_prevent_empty_spots": false,
    "n_rows": -1,
    "enable_pnginfo": true,
    "save_txt": false,
    "save_images_before_face_restoration": false,
    "save_images_before_highres_fix": false,
    "save_images_before_color_correction": false,
    "jpeg_quality": 80,
    "export_for_4chan": true,
    "img_downscale_threshold": 4.0,
    "target_side_length": 4000,
    "use_original_name_batch": true,
    "use_upscaler_name_as_suffix": false,
    "save_selected_only": true,
    "do_not_add_watermark": false,
    "temp_dir": "",
    "clean_temp_dir_at_start": false,
    "outdir_samples": "outputs",
    "outdir_txt2img_samples": "outputs/txt2img-images",
    "outdir_img2img_samples": "outputs/img2img-images",
    "outdir_extras_samples": "outputs/extras-images",
    "outdir_grids": "outputs/grids",
    "outdir_txt2img_grids": "outputs/txt2img-grids",
    "outdir_img2img_grids": "outputs/img2img-grids",
    "outdir_save": "log/images",
    "outdir_init_images": "outputs/init-images",
    "save_to_dirs": true,
    "grid_save_to_dirs": true,
    "use_save_to_dirs_for_ui": false,
    "directories_filename_pattern": "[seed]",
    "directories_max_prompt_words": 8,
    "ESRGAN_tile": 192,
    "ESRGAN_tile_overlap": 8,
    "realesrgan_enabled_models": ["RealESRGAN_x4plus", "RealESRGAN_x4plus_anime_6B"],
    "upscaler_for_img2img": null,
    "face_restoration": false,
    "face_restoration_model": "CodeFormer",
    "code_former_weight": 0.5,
    "face_restoration_unload": false,
    "show_warnings": false,
    "memmon_poll_rate": 8,
    "samples_log_stdout": false,
    "multiple_tqdm": true,
    "print_hypernet_extra": false,
    "unload_models_when_training": false,
    "pin_memory": false,
    "save_optimizer_state": false,
    "save_training_settings_to_txt": true,
    "dataset_filename_word_regex": "",
    "dataset_filename_join_string": " ",
    "training_image_repeats_per_epoch": 1,
    "training_write_csv_every": 500,
    "training_xattention_optimizations": false,
    "training_enable_tensorboard": false,
    "training_tensorboard_save_images": false,
    "training_tensorboard_flush_every": 120,
    "sd_model_checkpoint": "v1-5-pruned-emaonly.safetensors",
    "sd_checkpoint_cache": 0,
    "sd_vae": "vae-ft-mse-840000-ema-pruned.safetensors",
    "sd_vae_as_default": true,
    "inpainting_mask_weight": 1.0,
    "initial_noise_multiplier": 1.0,
    "img2img_extra_noise": 0.0,
    "img2img_color_correction": false,
    "img2img_fix_steps": false,
    "img2img_background_color": "#ffffff",
    "img2img_editor_height": 720,
    "img2img_sketch_default_brush_color": "#ff0000",
    "img2img_inpaint_mask_brush_color": "#ffffff",
    "img2img_inpaint_sketch_default_brush_color": "#ff0000",
    "return_grid": true,
    "do_not_show_images": false,
    "send_seed": true,
    "send_size": true,
    "font": "DejaVuSans.ttf",
    "js_modal_lightbox": true,
    "js_modal_lightbox_initially_zoomed": true,
    "js_modal_lightbox_gamepad": false,
    "js_modal_lightbox_gamepad_repeat_delay": 250,
    "js_modal_lightbox_gamepad_repeat_rate": 25,
    "show_progress_in_title": true,
    "samplers_in_dropdown": true,
    "dimensions_and_batch_together": true,
    "keyedit_precision_attention": 0.1,
    "keyedit_precision_extra": 0.05,
    "quicksettings": "sd_model_checkpoint",
    "ui_tab_order": [],
    "hidden_tabs": [],
    "ui_reorder": "",
    "sd_hypernetwork": "None",
    "localization": "None",
    "gradio_theme": "Default",
    "gallery_height": "",
    "return_mask": false,
    "return_mask_composite": false,
    "cross_attention_optimization": "Automatic",
    "s_min_uncond": 0.0,
    "token_merging_ratio": 0.0,
    "token_merging_ratio_img2img": 0.0,
    "token_merging_ratio_hr": 0.0,
    "pad_cond_uncond": false,
    "CLIP_stop_at_last_layers": 1,
    "extra_networks_show_hidden_directories": true,
    "extra_networks_hidden_models": "LoRA",
    "extra_networks_default_view": "cards",
    "extra_networks_default_multiplier": 1.0,
    "extra_networks_card_width": 0,
    "extra_networks_card_height": 0,
    "extra_networks_add_text_separator": " ",
    "ui_extra_networks_tab_reorder": "",
    "textual_inversion_print_at_load": false,
    "textual_inversion_add_hashes_to_infotext": true,
    "sd_hypernetwork_strength": 1.0,
    "lora_plus_lr_ratio": 0.01,
    "save_metadata_to_images": true,
    "metadata_scheme": "kohya-ss",
    "read_metadata_from_images": true,
    "add_model_hash_to_info": true,
    "add_model_name_to_info": true,
    "add_version_to_infotext": true,
    "add_vae_hash_to_info": true,
    "add_vae_name_to_info": true,
    "add_user_name_to_info": false,
    "add_datetime_to_info": true,
    "add_size_to_info": true,
    "add_parameters_to_info": true,
    "add_seed_to_info": true,
    "add_prompt_to_info": true,
    "add_negative_prompt_to_info": true,
    "add_sampler_to_info": true,
    "add_scheduler_to_info": true,
    "add_steps_to_info": true,
    "add_cfg_scale_to_info": true,
    "add_dimensions_to_info": true,
    "add_hr_parameters_to_info": true,
    "add_loras_to_info": true,
    "add_hypernetwork_to_info": true,
    "add_embedding_to_info": true,
    "add_script_to_info": true,
    "disable_weights_auto_swap": true,
    "send_seed": true,
    "send_size": true,
    "enable_pnginfo": true,
    "save_txt": false,
    "save_images_before_face_restoration": false,
    "save_images_before_highres_fix": false,
    "save_images_before_color_correction": false,
    "font": "DejaVuSans.ttf",
    "js_modal_lightbox": true,
    "show_progress_in_title": true,
    "samplers_in_dropdown": true,
    "interrogate_keep_models_in_memory": false,
    "interrogate_return_ranks": false,
    "interrogate_clip_num_beams": 1,
    "interrogate_clip_min_length": 24,
    "interrogate_clip_max_length": 48,
    "interrogate_clip_dict_limit": 1500,
    "interrogate_clip_skip_categories": [],
    "interrogate_deepbooru_score_threshold": 0.5,
    "deepbooru_sort_alpha": true,
    "deepbooru_use_spaces": true,
    "deepbooru_escape": true,
    "deepbooru_filter_tags": "",
    "extra_networks_card_width": 0,
    "extra_networks_card_height": 0,
    "extra_networks_add_text_separator": " ",
    "ui_extra_networks_tab_reorder": "",
    "textual_inversion_print_at_load": false,
    "textual_inversion_add_hashes_to_infotext": true,
    "sd_hypernetwork_strength": 1.0,
    "lora_plus_lr_ratio": 0.01,
    "save_metadata_to_images": true,
    "read_metadata_from_images": true,
    "enable_console_prompts": false,
    "comma_padding_backtrack": 20,
    "CLIP_stop_at_last_layers": 1,
    "upcast_attn": false,
    "randn_source": "GPU",
    "tiling": false,
    "filter_nsfw": false,
    "webui_theme": "dark",
    "gradio_debug": false,
    "opt_channelslast": false,
    "styles_editor_confirm_on_enter": false,
    "show_progressbar": true,
    "live_previews_enable": true,
    "live_previews_image_format": "png",
    "show_progress_grid": false,
    "notification_audio": false,
    "live_preview_refresh_period": 1000,
    "hide_samplers": [],
    "eta_ddim": 0.0,
    "eta_ancestral": 1.0,
    "ddim_discretize": "uniform",
    "s_churn": 0.0,
    "s_tmin": 0.0,
    "s_tmax": 1.0,
    "s_noise": 1.0,
    "eta_noise_seed_delta": 0,
    "always_discard_next_to_last_sigma": false,
    "uni_pc_variant": "bh1",
    "uni_pc_skip_type": "time_uniform",
    "uni_pc_order": 3,
    "uni_pc_lower_order_final": true
}
EOF
        print_success "Configuration file created"
    fi
    
    # Create webui-user.sh for custom configuration
    if [ ! -f "webui-user.sh" ]; then
        cat > webui-user.sh << 'EOF'
#!/usr/bin/env bash

################################################
# User configuration for AIpic Web UI
# Modify these variables to customize your setup
################################################

# Installation directory (no trailing slash)
# install_dir="/home/$(whoami)"

# Name of the subdirectory
# clone_dir="AIpic"

# Python command
# python_cmd="python3.13"

# Python venv location (no trailing slash)
# venv_dir="venv"

# GPU-specific settings for RTX 4070
export COMMANDLINE_ARGS="--medvram --opt-sdp-attention --xformers"
# --medvram: Optimize VRAM usage for 16GB GPU
# --opt-sdp-attention: Use optimized attention implementation
# --xformers: Use xformers for memory efficient attention

# Additional performance optimizations
# export TORCH_CUDA_ARCH_LIST="8.9"  # Compute capability for RTX 4070
# export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"

# Web UI settings
# export GRADIO_SERVER_NAME="0.0.0.0"  # Listen on all interfaces
# export GRADIO_SERVER_PORT=7860

# Model download settings
# export HF_HOME="$HOME/.cache/huggingface"
# export HF_HUB_DISABLE_TELEMETRY=1

# Performance tuning
# export CUDA_VISIBLE_DEVICES=0  # Use only first GPU
# export OMP_NUM_THREADS=4  # Limit OpenMP threads

# Uncomment to enable API
# export API=True

# Uncomment to enable auto-launch browser
# export LAUNCH_BROWSER=True

# Uncomment to disable safe mode
# export SAFE_MODE=False

# Uncomment to enable developer mode
# export DEVELOPER_MODE=True
EOF
        chmod +x webui-user.sh
        print_success "User configuration file created"
    fi
    
    # Create systemd service file
    if [ ! -f "/etc/systemd/system/aipic.service" ]; then
        print_info "Creating systemd service file..."
        
        sudo tee /etc/systemd/system/aipic.service > /dev/null << EOF
[Unit]
Description=AIpic Stable Diffusion Web UI
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR/$CLONE_DIR
Environment="PATH=$INSTALL_DIR/$CLONE_DIR/$VENV_DIR/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$INSTALL_DIR/$CLONE_DIR/$VENV_DIR/bin/python launch.py --listen --port $PORT
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$INSTALL_DIR/$CLONE_DIR
ReadWritePaths=/tmp

# Resource limits (adjust based on your system)
# MemoryLimit=16G
# CPUQuota=200%

[Install]
WantedBy=multi-user.target
EOF
        
        print_success "Systemd service file created"
        
        # Reload systemd and enable service
        sudo systemctl daemon-reload
        print_info "To enable auto-start on boot: sudo systemctl enable aipic"
        print_info "To start service now: sudo systemctl start aipic"
        print_info "To check status: sudo systemctl status aipic"
    fi
}

# Function to optimize system for AI workloads
optimize_system() {
    print_info "Optimizing system for AI workloads..."
    
    # Increase swap space if needed
    SWAP_SIZE=$(free -g | awk '/^Swap:/{print $2}')
    if [ "$SWAP_SIZE" -lt 16 ]; then
        print_warning "Swap space is less than 16GB ($SWAP_SIZE GB)"
        print_info "Consider increasing swap space for better performance:"
        print_info "  sudo fallocate -l 16G /swapfile"
        print_info "  sudo chmod 600 /swapfile"
        print_info "  sudo mkswap /swapfile"
        print_info "  sudo swapon /swapfile"
        print_info "  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab"
    fi
    
    # Configure swappiness for AI workloads
    SWAPPINESS=$(cat /proc/sys/vm/swappiness)
    if [ "$SWAPPINESS" -gt 10 ]; then
        print_info "Current swappiness: $SWAPPINESS"
        print_info "Setting swappiness to 10 for better performance..."
        sudo sysctl vm.swappiness=10
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    fi
    
    # Increase file descriptors limit
    FILE_MAX=$(cat /proc/sys/fs/file-max)
    if [ "$FILE_MAX" -lt 65535 ]; then
        print_info "Increasing file descriptors limit..."
        echo "fs.file-max = 65535" | sudo tee -a /etc/sysctl.conf
        echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
        echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
    fi
    
    # Enable GPU persistence mode
    if command_exists nvidia-smi; then
        print_info "Enabling NVIDIA GPU persistence mode..."
        sudo nvidia-smi -pm 1
    fi
    
    # Create performance tuning script
    cat > optimize_performance.sh << 'EOF'
#!/bin/bash

# Performance optimization script for AIpic
# Run this script before starting the Web UI for best performance

echo "Applying performance optimizations..."

# Clear GPU memory
if command -v nvidia-smi &> /dev/null; then
    echo "Clearing GPU memory cache..."
    sudo nvidia-smi --gpu-reset
fi

# Clear system cache
echo "Clearing system cache..."
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# Set CPU performance governor
echo "Setting CPU to performance mode..."
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "performance" | sudo tee $cpu > /dev/null 2>&1
done

# Increase TCP buffer sizes
echo "Optimizing network settings..."
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 134217728"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 134217728"

echo "Performance optimizations applied!"
EOF
    
    chmod +x optimize_performance.sh
    print_success "Performance optimization script created"
}

# Function to test installation
test_installation() {
    print_info "Testing installation..."
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Test Python imports
    print_info "Testing Python imports..."
    if python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}')"; then
        print_success "PyTorch installation successful"
    else
        print_error "PyTorch test failed"
        return 1
    fi
    
    # Test GPU
    if command_exists nvidia-smi; then
        print_info "Testing GPU..."
        if python -c "import torch; print(f'GPU: {torch.cuda.get_device_name(0)}'); print(f'GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.2f} GB')"; then
            print_success "GPU test successful"
        else
            print_warning "GPU test failed or running in CPU mode"
        fi
    fi
    
    # Test basic functionality
    print_info "Testing basic functionality..."
    if python -c "import gradio; import numpy; import PIL; print('All imports successful')"; then
        print_success "Basic functionality test passed"
    else
        print_error "Basic functionality test failed"
        return 1
    fi
    
    return 0
}

# Function to create startup script
create_startup_script() {
    print_info "Creating startup script..."
    
    cat > start_aipic.sh << 'EOF'
#!/usr/bin/env bash

#################################################
# AIpic Startup Script
# Optimized for Ubuntu 24.04 + Python 3.13 + RTX 4070
#################################################

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
PORT=7860

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting AIpic Web UI...${NC}"

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${RED}Error: Virtual environment not found at $VENV_DIR${NC}"
    echo "Please run the installation script first: ./install_ubuntu_24.sh"
    exit 1
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Check port availability
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}Warning: Port $PORT is already in use${NC}"
    echo "Would you like to:"
    echo "1) Use a different port"
    echo "2) Kill the process using port $PORT"
    echo "3) Exit"
    read -p "Enter choice [1-3]: " choice
    
    case $choice in
        1)
            read -p "Enter new port number: " NEW_PORT
            PORT=$NEW_PORT
            ;;
        2)
            echo "Killing process on port $PORT..."
            fuser -k $PORT/tcp
            sleep 2
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice, exiting..."
            exit 1
            ;;
    esac
fi

# Apply performance optimizations
if [ -f "optimize_performance.sh" ]; then
    echo "Applying performance optimizations..."
    ./optimize_performance.sh
fi

# Set environment variables for RTX 4070 optimization
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
export CUDA_LAUNCH_BLOCKING=0
export TF_CPP_MIN_LOG_LEVEL=2

# Check for custom configuration
if [ -f "webui-user.sh" ]; then
    source ./webui-user.sh
fi

# Determine command line arguments
ARGS="--listen --port $PORT --medvram --opt-sdp-attention --xformers"

# Add API flag if configured
if [ "${API:-}" = "True" ]; then
    ARGS="$ARGS --api"
fi

# Add auto-launch browser flag
if [ "${LAUNCH_BROWSER:-}" = "True" ]; then
    ARGS="$ARGS --autolaunch"
fi

# Add developer mode flag
if [ "${DEVELOPER_MODE:-}" = "True" ]; then
    ARGS="$ARGS --enable-console-prompts"
fi

echo -e "${GREEN}Starting with arguments: $ARGS${NC}"
echo -e "${GREEN}Web UI will be available at: http://localhost:$PORT${NC}"
echo -e "${GREEN}Press Ctrl+C to stop${NC}"

# Start the Web UI
exec python launch.py $ARGS
EOF
    
    chmod +x start_aipic.sh
    print_success "Startup script created"
    
    # Create stop script
    cat > stop_aipic.sh << 'EOF'
#!/usr/bin/env bash

# Stop AIpic Web UI

PORT=7860
PID=$(lsof -ti:$PORT)

if [ -n "$PID" ]; then
    echo "Stopping AIpic Web UI (PID: $PID)..."
    kill $PID
    sleep 2
    
    # Check if process is still running
    if ps -p $PID > /dev/null 2>&1; then
        echo "Process still running, forcing kill..."
        kill -9 $PID
    fi
    
    echo "AIpic Web UI stopped"
else
    echo "No AIpic process found on port $PORT"
fi
EOF
    
    chmod +x stop_aipic.sh
    print_success "Stop script created"
    
    # Create update script
    cat > update_aipic.sh << 'EOF'
#!/usr/bin/env bash

# Update AIpic Web UI

set -e

echo "Updating AIpic Web UI..."

# Update repository
git pull

# Update Python dependencies
source venv/bin/activate
pip install --upgrade -r requirements.txt

# Update PyTorch if needed
pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

echo "Update complete!"
echo "Please restart the Web UI to apply changes."
EOF
    
    chmod +x update_aipic.sh
    print_success "Update script created"
}

# Function to display installation summary
show_summary() {
    print_success "================================================"
    print_success "AIpic Installation Complete!"
    print_success "================================================"
    echo ""
    print_info "Installation Directory: $INSTALL_DIR/$CLONE_DIR"
    print_info "Python Virtual Environment: $VENV_DIR"
    print_info "Web UI Port: $PORT"
    echo ""
    print_info "Available Commands:"
    print_info "  ./start_aipic.sh    - Start the Web UI"
    print_info "  ./stop_aipic.sh     - Stop the Web UI"
    print_info "  ./update_aipic.sh   - Update AIpic"
    print_info "  ./optimize_performance.sh - Optimize system performance"
    echo ""
    print_info "Web UI Access:"
    print_info "  Local: http://localhost:$PORT"
    print_info "  Network: http://$(hostname -I | awk '{print $1}'):$PORT"
    echo ""
    print_info "Next Steps:"
    print_info "1. Download models to models/Stable-diffusion/"
    print_info "2. Configure settings in webui-user.sh"
    print_info "3. Start the Web UI: ./start_aipic.sh"
    echo ""
    print_info "Systemd Service:"
    print_info "  Enable auto-start: sudo systemctl enable aipic"
    print_info "  Start service: sudo systemctl start aipic"
    print_info "  Check status: sudo systemctl status aipic"
    print_success "================================================"
}

# Main installation function
main() {
    echo ""
    print_success "================================================"
    print_success "AIpic Installation for Ubuntu 24.04"
    print_success "Optimized for Python 3.13 + NVIDIA RTX 4070 16GB"
    print_success "================================================"
    echo ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root"
        print_info "Run as normal user: ./install_ubuntu_24.sh"
        exit 1
    fi
    
    # Check system requirements
    check_system_requirements
    
    # Ask for confirmation
    echo ""
    print_warning "This script will:"
    print_warning "1. Install system dependencies"
    print_warning "2. Install NVIDIA drivers and CUDA (if needed)"
    print_warning "3. Clone AIpic repository"
    print_warning "4. Set up Python virtual environment"
    print_warning "5. Install Python dependencies"
    print_warning "6. Download basic models"
    print_warning "7. Configure system for optimal performance"
    echo ""
    read -p "Continue with installation? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    # Installation steps
    install_system_dependencies
    install_nvidia_drivers
    clone_repository
    setup_python_environment
    install_python_dependencies
    download_models
    configure_system
    optimize_system
    create_startup_script
    
    # Test installation
    if test_installation; then
        print_success "Installation test passed!"
    else
        print_error "Installation test failed. Please check the errors above."
        exit 1
    fi
    
    # Show summary
    show_summary
}

# Run main function
main "$@"
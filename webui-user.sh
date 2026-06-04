#!/bin/bash
#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

# Install directory without trailing slash
#install_dir="/home/$(whoami)"

# Name of the subdirectory
clone_dir="AIpic"

# ======================================================
# 局域网访问配置
# ======================================================
# 启用监听所有网络接口（允许局域网访问）
export COMMANDLINE_ARGS="--listen --port 7860 --server-name 0.0.0.0"

# ======================================================
# GPU优化配置（RTX 4070 16GB）
# ======================================================
# RTX 4070 16GB 推荐配置：平衡模式（速度与内存的平衡）
export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --medvram --opt-sdp-attention --xformers --opt-channelslast"

# 可选配置（根据需求取消注释）：
# 性能模式（最大化速度）：
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --xformers --opt-sdp-attention --opt-channelslast"

# 质量模式（最佳输出质量）：
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --no-half --no-half-vae --precision full"

# 低内存模式（处理超大图像）：
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --lowvram --xformers"

# ======================================================
# CPU模式配置（如果没有GPU）
# ======================================================
# 取消下面行的注释以使用CPU模式
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --skip-torch-cuda-test --use-cpu all --no-half --precision full"

# ======================================================
# 性能优化配置
# ======================================================
# 内存优化
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --opt-channelslast"

# 禁用安全检查（提高性能）
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --disable-safe-unpickle --no-hashing"

# ======================================================
# 功能配置
# ======================================================
# 启用API
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --api"

# 自动打开浏览器
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --autolaunch"

# 启用控制台提示
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --enable-console-prompts"

# ======================================================
# 高级配置
# ======================================================
# 使用特定主题
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --theme dark"

# 启用Gradio队列
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --gradio-queue"

# 跳过版本检查
# export COMMANDLINE_ARGS="$COMMANDLINE_ARGS --skip-version-check"

# ======================================================
# 系统配置
# ======================================================
# python3 executable
python_cmd="/Users/zwj/AIpic/venv/bin/python"

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

# ======================================================
# 环境变量配置
# ======================================================
# PyTorch性能优化
# export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
# export CUDA_LAUNCH_BLOCKING=0
# export TF_CPP_MIN_LOG_LEVEL=2

# 设置计算能力（RTX 4070为8.9）
# export TORCH_CUDA_ARCH_LIST="8.9"

# 禁用telemetry
# export HF_HUB_DISABLE_TELEMETRY=1

###########################################

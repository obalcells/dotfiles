#!/bin/bash

# RunPod Complete Setup Script
# This script sets up a complete development environment on RunPod instances

echo "=========================================="
echo "   RunPod Environment Setup"
echo "=========================================="
echo ""

# 1) Setup linux dependencies
echo "Installing system dependencies..."
su -c 'apt-get update && apt-get install -y sudo'
sudo apt-get install -y git

# 2) Setup dotfiles and ZSH
echo ""
echo "Setting up dotfiles..."
mkdir -p ~/git && cd ~/git
git clone https://github.com/obalcells/dotfiles.git
cd dotfiles
chmod +x setup.sh
./setup.sh --zsh --tmux --vim --cc --vscode

# 3) Setup virtual environment
echo ""
echo "Setting up Python virtual environment..."
cd ~
source $HOME/.local/bin/env
uv python install 3.11
uv venv
source .venv/bin/activate
uv pip install ipykernel simple-gpu-scheduler # very useful on runpod with multi-GPUs
python -m ipykernel install --user --name=venv # shows up in jupyter notebooks within vscode

# 4) Setup github (optional - uncomment and edit with your details)
# echo ""
echo "Setting up GitHub..."
./setup_github.sh "your.email@example.com" "Your Name"

echo ""
echo "=========================================="
echo "   RunPod Setup Complete!"
echo "=========================================="
echo ""
echo "Please restart your terminal or run: exec zsh"
echo ""

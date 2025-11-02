#!/bin/bash
set -euo pipefail
USAGE=$(cat <<-END
    Usage: ./setup.sh [OPTIONS]
    Complete dotfiles setup - installs dependencies and deploys configuration

    OPTIONS:
        --zsh               install zsh
        --tmux              install tmux
        --vim               deploy simple vimrc config
        --extras            install extra dependencies (ripgrep, dust, etc)
        --cc                install Claude Code CLI
        --vscode            install VSCode/Cursor extensions
        --aliases=<list>    specify additional alias scripts (comma-separated)
        --force             force reinstall oh-my-zsh and plugins
        -h, --help          show this help message

    Example:
        ./setup.sh --zsh --tmux --cc --vscode
END
)

# Default values
zsh=false
tmux=false
vim=false
extras=false
cc=false
vscode=false
force=false
ALIASES=()

# Parse arguments
while (( "$#" )); do
    case "$1" in
        -h|--help)
            echo "$USAGE" && exit 0 ;;
        --zsh)
            zsh=true && shift ;;
        --tmux)
            tmux=true && shift ;;
        --vim)
            vim=true && shift ;;
        --extras)
            extras=true && shift ;;
        --cc)
            cc=true && shift ;;
        --vscode)
            vscode=true && shift ;;
        --force)
            force=true && shift ;;
        --aliases=*)
            IFS=',' read -r -a ALIASES <<< "${1#*=}" && shift ;;
        --) # end argument parsing
            shift && break ;;
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2 && exit 1 ;;
        *)
            echo "Error: Unsupported argument $1" >&2 && exit 1 ;;
    esac
done

# Detect operating system
operating_system="$(uname -s)"
case "${operating_system}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    *)          machine="UNKNOWN:${operating_system}"
                echo "Error: Unsupported operating system ${operating_system}" && exit 1
esac

export DOT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "=========================================="
echo "   Dotfiles Setup"
echo "=========================================="
echo "Operating System: $machine"
echo "Dotfiles Directory: $DOT_DIR"
echo ""

# ==========================================
# INSTALLATION PHASE
# ==========================================

echo "=========================================="
echo "   Installing Dependencies"
echo "=========================================="

# Installing on Linux with apt
if [ $machine == "Linux" ]; then
    sudo apt-get update -y
    [ $zsh == true ] && sudo apt-get install -y zsh
    [ $tmux == true ] && sudo apt-get install -y tmux
    sudo apt-get install -y less nano htop ncdu nvtop lsof rsync jq
    curl -LsSf https://astral.sh/uv/install.sh | sh

    if [ $extras == true ]; then
        sudo apt-get install -y ripgrep

        yes | curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash
        yes | brew install dust jless

        yes | curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        . "$HOME/.cargo/env"
        yes | cargo install code2prompt
        yes | brew install peco

        sudo apt-get install -y npm
        yes | npm i -g shell-ask
    fi

# Installing on Mac with homebrew
elif [ $machine == "Mac" ]; then
    yes | brew install coreutils ncdu htop rsync btop jq
    curl -LsSf https://astral.sh/uv/install.sh | sh

    if [ $extras == true ]; then
        yes | brew install ripgrep dust jless

        yes | curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        . "$HOME/.cargo/env"
        yes | cargo install code2prompt
        yes | brew install peco
    fi

    [ $zsh == true ] && yes | brew install zsh
    [ $tmux == true ] && yes | brew install tmux
    defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
    defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)
    defaults write -g com.apple.mouse.scaling 5.0
    defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
fi

# Setting up oh my zsh and oh my zsh plugins
ZSH=~/.oh-my-zsh
ZSH_CUSTOM=$ZSH/custom
if [ -d $ZSH ] && [ "$force" = "false" ]; then
    echo "Skipping download of oh-my-zsh and related plugins, pass --force to force reinstall"
else
    echo ""
    echo "Installing oh-my-zsh and plugins..."
    rm -rf $ZSH
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    git clone https://github.com/zsh-users/zsh-completions \
        ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions

    git clone https://github.com/zsh-users/zsh-history-substring-search \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search

    git clone https://github.com/jimeh/tmux-themepack.git ~/.tmux-themepack
fi

# Install Claude Code CLI
if [ $cc == true ]; then
    if ! command -v claude &> /dev/null; then
        echo ""
        echo "Installing Claude Code..."
        curl -LsSf https://claude.ai/install.sh | bash
    else
        echo "Claude Code already installed, skipping..."
    fi
fi

# Setup VSCode/Cursor extensions
if [ $vscode == true ]; then
    echo ""
    echo "Setting up VSCode/Cursor extensions..."

    vscode_path=""
    cursor_path=""

    if ls ~/.vscode-server/cli/servers/*/server/bin/remote-cli/code 2>/dev/null 1>&2; then
        vscode_path=$(ls -td ~/.vscode-server/cli/servers/*/server/bin/remote-cli/code 2>/dev/null | head -1 || true)
    fi

    if ls ~/.cursor-server/cli/servers/*/server/bin/remote-cli/cursor 2>/dev/null 1>&2; then
        cursor_path=$(ls -td ~/.cursor-server/cli/servers/*/server/bin/remote-cli/cursor 2>/dev/null | head -1 || true)
    fi

    # Determine which editor to use
    if [ -n "$cursor_path" ]; then
        echo "Found Cursor installation, using Cursor..."
        editor="$cursor_path"
        editor_name="cursor"
    elif [ -n "$vscode_path" ]; then
        echo "Found VSCode installation, using VSCode..."
        editor="$vscode_path"
        editor_name="code"
    else
        echo "Neither VSCode nor Cursor found, skipping extension installation"
        editor=""
    fi

    if [ -n "$editor" ]; then
        # Add alias to .bashrc
        echo "alias $editor_name=\"$editor\"" >> ~/.bashrc
        echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc

        # Update the system and install jq if not already installed
        if ! command -v jq &> /dev/null; then
            if [ $machine == "Linux" ]; then
                apt-get update
                apt-get install -y jq
            elif [ $machine == "Mac" ]; then
                brew install jq
            fi
        fi

        # Install recommended extensions
        if [ -f "$DOT_DIR/config/vscode_extensions.json" ]; then
            jq -r '.recommendations[]' "$DOT_DIR/config/vscode_extensions.json" | while read extension; do
                echo "Installing extension: $extension"
                "$editor" --install-extension "$extension" || echo "Failed to install $extension, continuing..."
            done
            echo "Extensions installed successfully!"
        else
            echo "Warning: vscode_extensions.json not found at $DOT_DIR/config/vscode_extensions.json"
        fi
    fi
fi

# Install extras
if [ $extras == true ]; then
    echo ""
    echo "Installing extras..."
    if command -v cargo &> /dev/null; then
        NO_ASK_OPENAI_API_KEY=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/hmirin/ask.sh/main/install.sh)"
    fi
fi

# ==========================================
# DEPLOYMENT PHASE
# ==========================================

echo ""
echo "=========================================="
echo "   Deploying Configuration"
echo "=========================================="

# Tmux setup
echo "Deploying tmux configuration..."
echo "source $DOT_DIR/config/tmux.conf" > $HOME/.tmux.conf

# Vimrc
if [[ $vim == true ]]; then
    echo "Deploying .vimrc..."
    echo "source $DOT_DIR/config/vimrc" > $HOME/.vimrc
fi

# zshrc setup
echo "Deploying zsh configuration..."
echo "source $DOT_DIR/config/zshrc.sh" > $HOME/.zshrc

# Append additional alias scripts if specified
if [ ${#ALIASES[@]} -gt 0 ]; then
    for alias in "${ALIASES[@]}"; do
        echo "source $DOT_DIR/config/aliases_${alias}.sh" >> $HOME/.zshrc
    done
fi

# Set zsh as default shell if installed
if [ $zsh == true ]; then
    echo ""
    echo "Setting zsh as default shell..."
    chsh -s $(which zsh)
fi

echo ""
echo "=========================================="
echo "   Setup Complete!"
echo "=========================================="
echo ""
echo "Configuration files deployed:"
echo "  - ~/.zshrc"
echo "  - ~/.tmux.conf"
[ $vim == true ] && echo "  - ~/.vimrc"
echo ""
echo "Please restart your terminal or run: exec zsh"
echo ""

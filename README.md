# Dotfiles

Based on [jplhughes/dotfiles](https://github.com/jplhughes/dotfiles/tree/master).

## Quick Setup

Complete setup with all features:
```bash
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles
chmod +x setup.sh
./setup.sh --zsh --tmux --vim --cc --vscode
```

After setup completes, restart your terminal or run:
```bash
exec zsh
```

## Setup Options

The `setup.sh` script combines installation and deployment into one command:

```bash
./setup.sh [OPTIONS]
```

Available options:
- `--zsh` - Install zsh
- `--tmux` - Install tmux
- `--vim` - Deploy simple vimrc config
- `--extras` - Install extra dependencies (ripgrep, dust, jless, etc)
- `--cc` - Install Claude Code CLI
- `--vscode` - Install VSCode/Cursor extensions
- `--aliases=<list>` - Additional alias scripts (comma-separated)
- `--force` - Force reinstall oh-my-zsh and plugins

### Examples

Minimal setup:
```bash
./setup.sh --zsh --tmux
```

Full setup with all features:
```bash
./setup.sh --zsh --tmux --vim --extras --cc --vscode
```

Setup with custom aliases:
```bash
./setup.sh --zsh --tmux --aliases=speechmatics,custom
```

## What's Included

- **Zsh configuration** with oh-my-zsh and plugins (autosuggestions, syntax highlighting, completions)
- **Tmux configuration** with custom theme
- **Vim configuration** (optional)
- **Claude Code CLI** (optional)
- **VSCode/Cursor extensions** (optional)
- **Custom aliases and functions**

## Manual Installation

If you prefer to use the original separate scripts:
- `./install.sh` - Installs dependencies
- `./deploy.sh` - Deploys configuration files

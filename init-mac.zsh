#!/usr/bin/env zsh

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions for better output
function print_section() {
  echo "\n${BLUE}=== $1 ===${NC}"
}

function print_info() {
  echo "${BLUE}ℹ $1${NC}"
}

function print_success() {
  echo "${GREEN}✓ $1${NC}"
}

function print_warning() {
  echo "${YELLOW}⚠ $1${NC}"
}

function print_error() {
  echo "${RED}✗ $1${NC}"
}

# Check macOS
print_section "Environment Check"
if [ $(uname) != "Darwin" ] ; then
  print_error "Not macOS!"
  exit 1
fi

print_success "This is macOS! Execute init-mac.zsh"

SCRIPT_DIR=$(cd $(dirname $0); pwd)

# Nix check and install
if command -v nix &>/dev/null; then
  print_success "Nix already installed"
else
  print_section "Installing Nix"
  curl -L https://nixos.org/nix/install | sh -s -- --daemon
  print_success "Nix installed. Please restart terminal and re-run this script"
  exit 0
fi

# Nixの環境読み込み
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# Nix設定: 実験的機能を有効化
print_section "Configuring Nix and Homebrew"
mkdir -p ~/.config/nix
if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  print_success "Nix experimental features enabled"
else
  print_success "Nix experimental features already enabled"
fi

# Homebrew check and install (一部パッケージで使用)
if command -v brew &>/dev/null; then
  print_success "Homebrew already installed"
else
  print_section "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Set Homebrew path based on architecture
  if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# zsh configuration
print_section "ZSH Configuration"
# Dependencies:
# - fzf command
# - curl
# - mise (multi-language version manager)
# - go
# - sdkman
ln -nfs $SCRIPT_DIR/zsh/.zshrc $HOME/
source $HOME/.zshrc
print_success ".zshrc file created"

# Xcode Command Line Tools check and install
if xcode-select -p &>/dev/null; then
  print_success "Xcode Command Line Tools already installed"
else
  print_section "Installing Xcode Command Line Tools"
  xcode-select --install
  print_warning "Please wait for the installation to complete..."
fi

# Enhanced install command function
# @param name Display name (ex. 'Git')
# @param command Command name (ex. 'git')
# @param checkCommand Command to check if installed (ex. 'git --version')
# @param installCommand Command to install (ex. 'brew install git')
function install_command() {
  local name=$1
  local command=$2
  local checkCommand=$3
  local installCommand=$4
  
  print_info "Checking ${name}... "
  
  if eval "$checkCommand" &>/dev/null; then
    print_success "Already installed"
    return 0
  else
    print_info "Installing... "
    if eval "$installCommand"; then
      print_success "Installed successfully!"
      return 0
    else
      print_error "Installation failed"
      return 1
    fi
  fi
}

print_section "Installing Development Tools"


# Git install
install_command 'Git' 'git' 'which git' 'nix profile add nixpkgs#git'

# ghq install
install_command 'ghq' 'ghq' 'ghq --version' 'nix profile add nixpkgs#ghq'

# GitHub CLI install
install_command 'GitHub CLI' 'gh' 'gh --version' 'nix profile add nixpkgs#gh'

# curl install
install_command 'curl' 'curl' 'which curl' 'nix profile add nixpkgs#curl'

# fzf install
install_command 'fzf' 'fzf' 'fzf --version' 'nix profile add nixpkgs#fzf'

# mise install (multi-language version manager)
install_command 'mise' 'mise' 'mise --version' 'nix profile add nixpkgs#mise'

# Go install
install_command 'Go' 'go' 'go version' 'nix profile add nixpkgs#go'

# SDKMAN install
install_command 'SDKMAN' 'sdk' 'sdk version' 'curl -s "https://get.sdkman.io" | bash; source "$HOME/.sdkman/bin/sdkman-init.sh"'

print_section "Installing mise-managed tools"

# Python install via mise
install_command 'Python (latest)' 'python' 'mise which python' 'mise use -g python@latest'

# Node.js install via mise
install_command 'Node.js (latest LTS)' 'node' 'mise which node' 'mise use -g node@lts'

# pnpm install via mise
install_command 'pnpm' 'pnpm' 'mise which pnpm' 'mise use -g pnpm@latest'

# Bun install via mise
# @see https://bun.sh/docs/installation
install_command 'Bun' 'bun' 'mise which bun' 'mise use -g bun@latest'

# Claude Code CLI install
install_command 'Claude Code' 'claude' 'claude -v' 'curl -fsSL https://claude.ai/install.sh | bash'

# Codex CLI install
install_command 'Codex CLI' 'codex' 'codex --version' 'brew install codex'

# AWS CLI install
install_command 'AWS CLI' 'aws' 'aws --version' 'nix profile add nixpkgs#awscli2'

# AWS SAM CLI install
install_command 'AWS SAM CLI' 'sam' 'sam --version' 'nix profile add nixpkgs#aws-sam-cli'

# Font Fira Code install
# Bug: Font installation path issue, manually move and remove from brew
install_command 'Font Fira Code' 'FiraCode' 'ls $HOME/Library/Fonts/FiraCode-Regular.ttf' 'brew install font-fira-code && mv $HOME/\$\{HOME\}/Library/Fonts/* $HOME/Library/Fonts/ && rm -rf $HOME/\$\{HOME\} && brew uninstall font-fira-code'

# ngrok install
# @see https://ngrok.com/docs/getting-started/
install_command 'ngrok' 'ngrok' 'ngrok version' 'brew install ngrok'

# Stripe CLI install
# @see https://docs.stripe.com/stripe-cli
install_command 'Stripe CLI' 'stripe' 'stripe version' 'nix profile add nixpkgs#stripe-cli'

# VHS install
# @see https://github.com/charmbracelet/vhs
install_command 'VHS' 'vhs' 'vhs --version' 'nix profile add nixpkgs#vhs'

print_section "Installing Java"
# After setting sdk command path in .zshrc, install Java
install_command 'Java 11' 'java11' 'sdk home java 11.0.29-amzn' 'sdk install java 11.0.29-amzn'
install_command 'Java 17' 'java17' 'sdk home java 17.0.17-amzn' 'sdk install java 17.0.17-amzn'
install_command 'Java 18' 'java18' 'sdk home java 18.0.2-amzn' 'sdk install java 18.0.2-amzn'

print_section "Setting Up Configuration Files"

# Git configuration
ln -nfs $SCRIPT_DIR/git/.gitconfig $HOME/
ln -nfs $SCRIPT_DIR/git/.gitignore_global $HOME/
if [ ! -f $HOME/.gitconfig.user.local ]; then
  cp $SCRIPT_DIR/git/.gitconfig.user.local $HOME/
fi
print_success "Git configuration files created"

# Cursor user settings
# Requires Cursor application
# Currently commented out as Cursor is not in use
ln -nfs $SCRIPT_DIR/cursor/settings.json $HOME/Library/Application\ Support/Cursor/User/settings.json
ln -nfs $SCRIPT_DIR/cursor/keybindings.json $HOME/Library/Application\ Support/Cursor/User/keybindings.json
print_success "Cursor configuration files created"

# VSCode user settings
# Requires VSCode application
ln -nfs $SCRIPT_DIR/vscode/settings.json $HOME/Library/Application\ Support/Code/User/settings.json
ln -nfs $SCRIPT_DIR/vscode/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json
print_success "VSCode configuration files created"

# VSCode Insiders user settings
# Requires VSCode Insiders application
ln -nfs $SCRIPT_DIR/vscode-insiders/settings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
ln -nfs $SCRIPT_DIR/vscode-insiders/keybindings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/keybindings.json
print_success "VSCode Insiders configuration files created"

# Claude Code user-level configuration
print_section "Claude Code User Configuration"
mkdir -p $HOME/.claude
ln -nfs $SCRIPT_DIR/claude-code/CLAUDE.md $HOME/.claude/CLAUDE.md
print_success "Claude Code user-level CLAUDE.md created"

# Cline MCP settings
print_section "VSCode Cline extension Configuration"
CLINE_EXTENSION_DIR="$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev"
CLINE_SETTINGS_FILE="$CLINE_EXTENSION_DIR/settings/cline_mcp_settings.json"

if [ -d "$CLINE_EXTENSION_DIR" ]; then
  print_success "VSCode Cline extension detected"
  mkdir -p "$CLINE_EXTENSION_DIR/settings"
  
  if [ ! -f "$CLINE_SETTINGS_FILE" ]; then
    cp "$SCRIPT_DIR/vscode/cline_mcp_settings.json" "$CLINE_SETTINGS_FILE"
    print_success "VSCode Cline MCP configuration file copied"
  else
    print_success "VSCode Cline MCP configuration file already exists"
  fi
else
  print_warning "VSCode Cline extension not found. Please install the Cline extension in VSCode first."
  print_warning "Extension ID: saoudrizwan.claude-dev"
fi

# iTerm2 shell integration install
curl -sL https://iterm2.com/shell_integration/zsh -o $HOME/.iterm2_shell_integration.zsh
print_success "iTerm2 shell integration installed"

print_section "System Configuration"

# Keyboard settings
defaults write -g KeyRepeat -int 1 
defaults write -g InitialKeyRepeat -int 10
print_success "Keyboard settings applied"

# DNS settings
networksetup -setdnsservers Wi-Fi 2001:4860:4860::8844 2001:4860:4860::8888 8.8.4.4 8.8.8.8
print_success "DNS settings applied"

# Finder and system settings
# Do not create .DS_Store on USB or Network drives
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder WarnOnEmptyTrash -bool false
defaults write com.apple.finder _FXShowPosixPathInTitle -boolean true && killall Finder
print_success "Finder settings applied"

print_section "Setup Complete"
print_success "macOS environment setup completed successfully!"

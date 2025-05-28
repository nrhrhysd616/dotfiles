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

# Homebrew check and install
if command -v brew &>/dev/null; then
  print_success "Homebrew already installed"
  # Update Homebrew
  brew update
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
# - Python3.9
# - volta
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
  
  echo -n "Checking ${name}... "
  
  if eval "$checkCommand" &>/dev/null; then
    print_success "Already installed"
    return 0
  else
    echo -n "Installing... "
    if eval "$installCommand"; then
      print_success "Installed successfully"
      return 0
    else
      print_error "Installation failed"
      return 1
    fi
  fi
}

print_section "Installing Development Tools"

# SQLite3 install
install_command 'SQLite3' 'sqlite3' 'brew list sqlite3' 'brew install sqlite'

# Git install
install_command 'Git' 'git' 'brew list git' 'brew install git'

# curl install
install_command 'curl' 'curl' 'curl --version' 'brew install curl'

# fzf install
install_command 'fzf' 'fzf' 'fzf --version' 'brew install fzf'

# Python 3.9 install
install_command 'Python 3.9' 'python3.9' 'python3.9 --version' 'brew install python@3.9'

# volta install
install_command 'Volta' 'volta' 'volta --version' 'curl https://get.volta.sh | bash'

# Go install
install_command 'Go' 'go' 'go version' 'brew install go'

# SDKMAN install
install_command 'SDKMAN' 'sdk' 'sdk version' 'curl -s "https://get.sdkman.io" | bash; source "$HOME/.sdkman/bin/sdkman-init.sh"'

# Bun install
# @see https://bun.sh/docs/installation
install_command 'Bun' 'bun' 'bun --version' 'volta install node;volta install bun'

# Claude Code CLI install (requires Bun)
install_command 'Claude Code' 'claude' 'claude -v' 'bun install -g @anthropic-ai/claude-code'

# AWS CLI install
install_command 'AWS CLI' 'aws' 'aws --version' 'brew install awscli'

# AWS SAM CLI install
install_command 'AWS SAM CLI' 'sam' 'sam --version' 'brew install aws-sam-cli'

# Font Fira Code install
# Bug: Font installation path issue, manually move and remove from brew
install_command 'Font Fira Code' 'FiraCode' 'ls $HOME/Library/Fonts/FiraCode-Regular.ttf' 'brew install font-fira-code && mv $HOME/\$\{HOME\}/Library/Fonts/* $HOME/Library/Fonts/ && rm -rf $HOME/\$\{HOME\} && brew uninstall font-fira-code'

# ngrok install
# @see https://ngrok.com/docs/getting-started/
install_command 'ngrok' 'ngrok' 'ngrok -v' 'brew install ngrok/ngrok/ngrok'

# Stripe CLI install
# @see https://docs.stripe.com/stripe-cli
install_command 'Stripe CLI' 'stripe' 'stripe -v' 'brew install stripe/stripe-cli/stripe'

# VHS install
# @see https://github.com/charmbracelet/vhs
install_command 'VHS' 'vhs' 'vhs -v' 'brew install vhs'

print_section "Installing Java"
# After setting sdk command path in .zshrc, install Java
install_command 'Java 11' 'java11' 'sdk home java 11.0.26-amzn' 'sdk install java 11.0.26-amzn'
install_command 'Java 17' 'java17' 'sdk home java 17.0.14-amzn' 'sdk install java 17.0.14-amzn'
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
    print_warning "Please set your GITHUB_PERSONAL_ACCESS_TOKEN environment variable"
    print_warning "or edit the configuration file to add your GitHub access token:"
    print_warning "$CLINE_SETTINGS_FILE"
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

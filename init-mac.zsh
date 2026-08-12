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

# Create a symlink with validation
# Skips when the destination's parent directory does not exist (ex. app not installed)
# and reports failure instead of always printing success
# @param src Source path in this repository (absolute path)
# @param dest Destination path (absolute path)
function link_config() {
  local src=$1
  local dest=$2
  local dest_dir=$(dirname "$dest")

  if [ ! -d "$dest_dir" ]; then
    print_warning "Skipped linking $dest ($dest_dir not found)"
    return 1
  fi

  if ln -nfs "$src" "$dest"; then
    print_success "Linked $dest"
  else
    print_error "Failed to link $dest"
    return 1
  fi
}

# Check macOS
print_section "Environment Check"
if [ $(uname) != "Darwin" ] ; then
  print_error "Not macOS!"
  exit 1
fi

print_success "This is macOS! Execute init-mac.zsh"

SCRIPT_DIR=$(cd $(dirname $0); pwd)

# Homebrew check and install (パッケージ管理のメイン)
print_section "Installing Homebrew"
if command -v brew &>/dev/null; then
  print_success "Homebrew already installed"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Set Homebrew path based on architecture
  if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  print_success "Homebrew installed"
fi

# zsh configuration
print_section "ZSH Configuration"
# Dependencies:
# - fzf (historyexec command)
# - mise (multi-language version manager)
# - sdkman (Java version manager)
link_config $SCRIPT_DIR/zsh/.zshrc $HOME/.zshrc
source $HOME/.zshrc

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
# @param checkCommand Command to check if installed (ex. 'brew list --formula git')
# @param installCommand Command to install (ex. 'brew install git')
# @param updateCommand Command to update if already installed (ex. 'brew upgrade git') [optional]
function install_command() {
  local name=$1
  local command=$2
  local checkCommand=$3
  local installCommand=$4
  local updateCommand=${5:-""}

  print_info "Checking ${name}... "

  if eval "$checkCommand" &>/dev/null; then
    if [[ -n "$updateCommand" ]]; then
      print_info "Already installed. Updating... "
      if eval "$updateCommand"; then
        print_success "Updated successfully!"
        return 0
      else
        print_error "Update failed"
        return 1
      fi
    else
      print_success "Already installed, skipping update"
      return 0
    fi
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

# Homebrew管理のツールは checkCommand に brew list を使う
# コマンドの有無で判定すると、Xcode Command Line Toolsのgitのように
# Homebrew管理外のものを「インストール済み」と誤判定し、
# 未インストールのまま brew upgrade が走って失敗するため
# formulaとcaskで判定に使うオプションが異なる点にも注意する
#
# curlはmacOS標準のものを使うためインストールしない
# (Homebrew版はkeg-onlyで、使うにはPATHの追加が必要になるため)

# Git install
install_command 'Git' 'git' 'brew list --formula git' 'brew install git' 'brew upgrade git'

# ghq install
install_command 'ghq' 'ghq' 'brew list --formula ghq' 'brew install ghq' 'brew upgrade ghq'

# GitHub CLI install
install_command 'GitHub CLI' 'gh' 'brew list --formula gh' 'brew install gh' 'brew upgrade gh'

# fzf install
install_command 'fzf' 'fzf' 'brew list --formula fzf' 'brew install fzf' 'brew upgrade fzf'

# mise install (multi-language version manager)
install_command 'mise' 'mise' 'brew list --formula mise' 'brew install mise' 'brew upgrade mise'

# SDKMAN install
install_command 'SDKMAN' 'sdk' 'sdk version' 'curl -s "https://get.sdkman.io" | bash; source "$HOME/.sdkman/bin/sdkman-init.sh"' 'sdk selfupdate force'

print_section "Installing mise-managed tools"

# Python install via mise
install_command 'Python (latest)' 'python' 'mise which python' 'mise use -g python@latest' 'mise use -g python@latest'

# Node.js install via mise
install_command 'Node.js (latest LTS)' 'node' 'mise which node' 'mise use -g node@lts' 'mise use -g node@lts'

# pnpm install via mise
install_command 'pnpm' 'pnpm' 'mise which pnpm' 'mise use -g pnpm@latest' 'mise use -g pnpm@latest'

# Bun install via mise
# @see https://bun.sh/docs/installation
install_command 'Bun' 'bun' 'mise which bun' 'mise use -g bun@latest' 'mise use -g bun@latest'

# Go install via mise
install_command 'Go' 'go' 'mise which go' 'mise use -g go@latest' 'mise use -g go@latest'

# Terraform install via mise
install_command 'Terraform' 'terraform' 'mise which terraform' 'mise use -g terraform@latest' 'mise use -g terraform@latest'

# Claude Code CLI install
install_command 'Claude Code' 'claude' 'claude -v' 'curl -fsSL https://claude.ai/install.sh | bash' 'curl -fsSL https://claude.ai/install.sh | bash'

# Codex CLI install
install_command 'Codex CLI' 'codex' 'brew list --cask codex' 'brew install codex' 'brew upgrade codex'

# AWS CLI install (formula名はawscli、実体はv2)
install_command 'AWS CLI' 'aws' 'brew list --formula awscli' 'brew install awscli' 'brew upgrade awscli'

# AWS SAM CLI install
install_command 'AWS SAM CLI' 'sam' 'brew list --formula aws-sam-cli' 'brew install aws-sam-cli' 'brew upgrade aws-sam-cli'

# Font Fira Code install
# Bug: Font installation path issue, manually move and remove from brew
install_command 'Font Fira Code' 'FiraCode' 'ls $HOME/Library/Fonts/FiraCode-Regular.ttf' 'brew install font-fira-code && mv $HOME/\$\{HOME\}/Library/Fonts/* $HOME/Library/Fonts/ && rm -rf $HOME/\$\{HOME\} && brew uninstall font-fira-code'

# ngrok install
# @see https://ngrok.com/docs/getting-started/
install_command 'ngrok' 'ngrok' 'brew list --cask ngrok' 'brew install ngrok' 'brew upgrade ngrok'

# Stripe CLI install
# サードパーティのtapで配布されているため式名をフルパスで指定する (初回は自動でtapされる)
# @see https://docs.stripe.com/stripe-cli
install_command 'Stripe CLI' 'stripe' 'brew list --formula stripe' 'brew install stripe/stripe-cli/stripe' 'brew upgrade stripe/stripe-cli/stripe'

# VHS install
# @see https://github.com/charmbracelet/vhs
install_command 'VHS' 'vhs' 'brew list --formula vhs' 'brew install vhs' 'brew upgrade vhs'

# Poppler install (PDF utilities: pdftotext, pdftoppm, pdfimages, etc.)
# @see https://poppler.freedesktop.org/
install_command 'Poppler' 'pdftotext' 'brew list --formula poppler' 'brew install poppler' 'brew upgrade poppler'

# ripgrep install (used by the VSCode Todo Tree extension via todo-tree.ripgrep.ripgrep)
# The extension needs an absolute path in settings.json, so it points at
# /opt/homebrew/bin/rg
# @see https://github.com/BurntSushi/ripgrep
install_command 'ripgrep' 'rg' 'brew list --formula ripgrep' 'brew install ripgrep' 'brew upgrade ripgrep'

# code-server install (VS Code in the browser, driven by the csctl command)
# Homebrew instead of mise: the npm package pins Node 22 while mise tracks the
# current LTS. The formula bundles node@22 itself. It is marked deprecated
# upstream (disabled 2027-04-11), so revisit the install method before then.
# @see https://coder.com/docs/code-server
install_command 'code-server' 'code-server' 'brew list --formula code-server' 'brew install code-server' 'brew upgrade code-server'

print_section "Installing Java"

# Resolve the latest available Amazon Corretto version for a major version
# Falls back to a pinned version if SDKMAN resolution fails,
# because pinned patch versions eventually disappear from SDKMAN
# @param major Java major version (ex. '11')
# @param fallback Pinned version identifier (ex. '11.0.29-amzn')
function sdk_latest_java() {
  local major=$1
  local fallback=$2
  local resolved=$(sdk list java 2>/dev/null | grep -oE "\b${major}(\.[0-9]+)+-amzn" | head -1)
  echo ${resolved:-$fallback}
}

# After setting sdk command path in .zshrc, install Java
JAVA11_VERSION=$(sdk_latest_java 11 11.0.29-amzn)
JAVA17_VERSION=$(sdk_latest_java 17 17.0.17-amzn)
JAVA18_VERSION=$(sdk_latest_java 18 18.0.2-amzn)
JAVA21_VERSION=$(sdk_latest_java 21 21.0.11-amzn)
install_command 'Java 11' 'java11' "sdk home java $JAVA11_VERSION" "sdk install java $JAVA11_VERSION"
install_command 'Java 17' 'java17' "sdk home java $JAVA17_VERSION" "sdk install java $JAVA17_VERSION"
install_command 'Java 18' 'java18' "sdk home java $JAVA18_VERSION" "sdk install java $JAVA18_VERSION"
install_command 'Java 21' 'java21' "sdk home java $JAVA21_VERSION" "sdk install java $JAVA21_VERSION"

print_section "Setting Up Configuration Files"

# Git configuration
link_config $SCRIPT_DIR/git/.gitconfig $HOME/.gitconfig
link_config $SCRIPT_DIR/git/.gitignore_global $HOME/.gitignore_global
if [ ! -f $HOME/.gitconfig.user.local ]; then
  cp $SCRIPT_DIR/git/.gitconfig.user.local $HOME/
fi
print_success "Git configuration files created"

# AWS CLI configuration
# Copy instead of symlink: the config holds an account-specific ARN
# and this repository is public
mkdir -p $HOME/.aws
if [ ! -f $HOME/.aws/config ]; then
  cp $SCRIPT_DIR/aws/config $HOME/.aws/config
  print_success "AWS configuration file created"
else
  print_success "AWS configuration file already exists"
fi

# Editor user settings
# settings.json is shared across VSCode / VSCode Insiders / Cursor (vscode/settings.json)
# Requires each application to be installed and launched at least once

# Cursor user settings
link_config $SCRIPT_DIR/vscode/settings.json "$HOME/Library/Application Support/Cursor/User/settings.json"
link_config $SCRIPT_DIR/cursor/keybindings.json "$HOME/Library/Application Support/Cursor/User/keybindings.json"

# VSCode user settings
link_config $SCRIPT_DIR/vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"
link_config $SCRIPT_DIR/vscode/keybindings.json "$HOME/Library/Application Support/Code/User/keybindings.json"

# VSCode Insiders user settings
link_config $SCRIPT_DIR/vscode/settings.json "$HOME/Library/Application Support/Code - Insiders/User/settings.json"
link_config $SCRIPT_DIR/vscode-insiders/keybindings.json "$HOME/Library/Application Support/Code - Insiders/User/keybindings.json"

# Claude Code user-level configuration
print_section "Claude Code User Configuration"
mkdir -p $HOME/.claude
link_config $SCRIPT_DIR/claude-code/CLAUDE.md $HOME/.claude/CLAUDE.md
link_config $SCRIPT_DIR/claude-code/skills $HOME/.claude/skills
link_config $SCRIPT_DIR/claude-code/settings.json $HOME/.claude/settings.json
link_config $SCRIPT_DIR/claude-code/statusline.sh $HOME/.claude/statusline.sh

# Custom commands
# $HOME/.local/bin is already on $PATH via zsh/.zshrc
print_section "Custom Commands"
mkdir -p $HOME/.local/bin
link_config $SCRIPT_DIR/bin/csctl $HOME/.local/bin/csctl

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

# sshd configuration
# /etc/ssh/sshd_config is a system file, so sudo is required
# Copy instead of symlink: a symlink into this repo would allow user-level
# processes to rewrite the root-owned sshd config without sudo
if [[ -L /etc/ssh/sshd_config ]]; then
  sudo rm /etc/ssh/sshd_config
  print_warning "Removed legacy sshd_config symlink"
elif [[ -e /etc/ssh/sshd_config ]] && ! sudo cmp -s $SCRIPT_DIR/sshd/sshd_config /etc/ssh/sshd_config; then
  backup_path="/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"
  sudo cp /etc/ssh/sshd_config $backup_path
  print_warning "Existing sshd_config backed up to $backup_path"
fi
sudo cp $SCRIPT_DIR/sshd/sshd_config /etc/ssh/sshd_config
sudo chown root:wheel /etc/ssh/sshd_config
sudo chmod 644 /etc/ssh/sshd_config
print_success "sshd configuration file copied"
print_info "To apply sshd configuration, restart sshd with the following commands:"
print_info "  sudo launchctl stop com.openssh.sshd"
print_info "  sudo launchctl start com.openssh.sshd"

# SSH authorized_keys configuration
mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh
if [[ -e $HOME/.ssh/authorized_keys && ! -L $HOME/.ssh/authorized_keys ]]; then
  backup_path="$HOME/.ssh/authorized_keys.bak.$(date +%Y%m%d%H%M%S)"
  cp $HOME/.ssh/authorized_keys $backup_path
  print_warning "Existing authorized_keys backed up to $backup_path"
fi
cp $SCRIPT_DIR/ssh/authorized_keys $HOME/.ssh/authorized_keys
chmod 600 $HOME/.ssh/authorized_keys
print_success "SSH authorized_keys configuration file copied"

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

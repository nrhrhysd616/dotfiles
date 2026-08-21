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

# Create an empty knowledge index when one does not exist yet.
# The private and local layers are not tracked by this repository, but
# ~/.claude/CLAUDE.md imports their indexes unconditionally, so the files
# have to exist. Never overwrite: the content is written by hand over time.
function init_knowledge_index() {
  local dest=$1
  local label=$2

  if [ -f "$dest" ]; then
    print_success "Knowledge index already exists ($dest)"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  cat > "$dest" <<EOF
# ナレッジ索引（${label}）

<!--
  1トピック1行。「いつ読むか」のトリガーを必ず書く。
  書き方は ~/.agents/README.md と knowledge スキルを参照。
-->
EOF
  print_success "Knowledge index created ($dest)"
}

# Point the private knowledge layer at an empty directory when the private
# repository is unavailable. ~/.claude/CLAUDE.md imports that layer's index
# unconditionally, so the path has to resolve to something.
# It must stay a symlink, never a real directory: `ln -nfs` only refuses to
# follow a *symlinked* directory, so a real one here would swallow the link
# once the repository does become available on this machine.
function link_private_knowledge_fallback() {
  mkdir -p $HOME/.agents/knowledge-private-unavailable
  link_config $HOME/.agents/knowledge-private-unavailable $HOME/.agents/knowledge/private
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

# Ruby build dependencies
# miseはprecompiledのRubyがあればそれを使うが (この場合ライブラリは静的リンクされる)、
# 無ければruby-buildでのソースビルドにフォールバックする
# precompiledはApple Silicon向けの一部バージョンのみなので、プロジェクトの
# .ruby-versionが古いバージョンを指すとビルドが走る。その保険として先に入れておく
# openssl@3: macOS標準のLibreSSLではopenssl拡張をビルドできない (ruby-buildが自動で検出する)
# libyaml: psych(YAML)がビルドされず、bundlerやCocoaPodsが動かなくなる
install_command 'OpenSSL 3' 'openssl' 'brew list --formula openssl@3' 'brew install openssl@3' 'brew upgrade openssl@3'
install_command 'libyaml' 'yaml' 'brew list --formula libyaml' 'brew install libyaml' 'brew upgrade libyaml'

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

# Ruby install via mise (CocoaPodsなどiOSビルドのツールが必要とする)
# checkCommandに `mise which` を使うのが重要
# コマンドの有無で判定すると、macOS標準の /usr/bin/ruby を拾って
# 「インストール済み」と誤判定する (Homebrewの判定に brew list を使うのと同じ理由)
install_command 'Ruby (latest)' 'ruby' 'mise which ruby' 'mise use -g ruby@latest' 'mise use -g ruby@latest'

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

# Agent shared configuration (Claude Code / Codex)
# Rules, knowledge and skills live under ~/.agents so both agents share them.
# ~/.claude entries point straight at the repository instead of going through
# ~/.agents: two-level symlinks are not documented as resolvable.
print_section "Agent Shared Configuration"
mkdir -p $HOME/.agents/rules $HOME/.agents/knowledge $HOME/.agents/knowledge-local
mkdir -p $HOME/.claude/rules $HOME/.codex

link_config $SCRIPT_DIR/agents/AGENTS.md $HOME/.agents/AGENTS.md
link_config $SCRIPT_DIR/agents/AGENTS.md $HOME/.codex/AGENTS.md
link_config $SCRIPT_DIR/agents/skills $HOME/.agents/skills
link_config $SCRIPT_DIR/agents/skills $HOME/.claude/skills
link_config $SCRIPT_DIR/agents/rules $HOME/.agents/rules/shared
link_config $SCRIPT_DIR/agents/rules $HOME/.claude/rules/shared
link_config $SCRIPT_DIR/agents/knowledge $HOME/.agents/knowledge/shared

# Private knowledge repository
# Holds work/personal knowledge that must not land in this public repository.
# A machine without access to it still has to finish setup, so failures here
# are warnings and the layer is simply left empty.
PRIVATE_KNOWLEDGE_REPO='github.com/nrhrhysd616/agent-knowledge-private'
if command -v ghq &>/dev/null; then
  PRIVATE_KNOWLEDGE_DIR="$(ghq root)/$PRIVATE_KNOWLEDGE_REPO"
  if [ ! -d "$PRIVATE_KNOWLEDGE_DIR" ]; then
    # Check access with gh first. `ghq get` on a repository that is missing or
    # unreachable blocks waiting for credentials and stalls the whole setup,
    # so it must never be the thing that discovers the repository is absent.
    if gh repo view "${PRIVATE_KNOWLEDGE_REPO#github.com/}" &>/dev/null; then
      GIT_TERMINAL_PROMPT=0 ghq get "$PRIVATE_KNOWLEDGE_REPO" ||
        print_warning "Skipped private knowledge (clone failed)"
    else
      print_warning "Skipped private knowledge (no access to $PRIVATE_KNOWLEDGE_REPO)"
    fi
  fi
  if [ -d "$PRIVATE_KNOWLEDGE_DIR" ]; then
    link_config "$PRIVATE_KNOWLEDGE_DIR/rules" $HOME/.agents/rules/private
    link_config "$PRIVATE_KNOWLEDGE_DIR/rules" $HOME/.claude/rules/private
    link_config "$PRIVATE_KNOWLEDGE_DIR/knowledge" $HOME/.agents/knowledge/private
  else
    link_private_knowledge_fallback
  fi
else
  print_warning "Skipped private knowledge (ghq not found)"
  link_private_knowledge_fallback
fi

# Indexes for the layers no repository tracks (created only when missing)
init_knowledge_index $HOME/.agents/knowledge/private/INDEX.md 'private・非公開'
init_knowledge_index $HOME/.agents/knowledge-local/INDEX.md 'local・この端末限定'

# Claude Code specific configuration
print_section "Claude Code User Configuration"
link_config $SCRIPT_DIR/claude-code/CLAUDE.md $HOME/.claude/CLAUDE.md
link_config $SCRIPT_DIR/claude-code/settings.json $HOME/.claude/settings.json
link_config $SCRIPT_DIR/claude-code/statusline.sh $HOME/.claude/statusline.sh

# Custom commands
# $HOME/.local/bin is already on $PATH via zsh/.zshrc
print_section "Custom Commands"
mkdir -p $HOME/.local/bin
link_config $SCRIPT_DIR/bin/csctl $HOME/.local/bin/csctl
# mac-ssh-keygen is referenced by gpg.ssh.program with an absolute path,
# so it has to be linked before gen-mac-git-signkey runs below
link_config $SCRIPT_DIR/bin/mac-ssh-keygen $HOME/.local/bin/mac-ssh-keygen
link_config $SCRIPT_DIR/bin/gen-mac-git-signkey $HOME/.local/bin/gen-mac-git-signkey

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

# SSH client configuration
# GitHubへの認証にSecure Enclave上の鍵を使う設定。1PasswordのSSH agentを
# 指していた既存の設定へ戻せるよう、symlinkでなければバックアップを取る
if [[ -e $HOME/.ssh/config && ! -L $HOME/.ssh/config ]]; then
  backup_path="$HOME/.ssh/config.bak.$(date +%Y%m%d%H%M%S)"
  cp $HOME/.ssh/config $backup_path
  print_warning "Existing ssh config backed up to $backup_path"
fi
link_config $SCRIPT_DIR/ssh/config $HOME/.ssh/config

# Allowed signers for commit signature verification
# git log --show-signature が参照する署名者リスト。署名鍵は端末ごとに別になるため
# 全端末の公開鍵をリポジトリ側(git/allowed_signers)に集約している
if [[ -e $HOME/.ssh/allowed_signers && ! -L $HOME/.ssh/allowed_signers ]]; then
  backup_path="$HOME/.ssh/allowed_signers.bak.$(date +%Y%m%d%H%M%S)"
  cp $HOME/.ssh/allowed_signers $backup_path
  print_warning "Existing allowed_signers backed up to $backup_path"
fi
link_config $SCRIPT_DIR/git/allowed_signers $HOME/.ssh/allowed_signers

# Git commit signing key (Secure Enclave)
# Secure Enclaveの秘密鍵は取り出せないため、鍵は端末ごとに生成する。
# gen-mac-git-signkeyは冪等なので、既に鍵があれば作り直さない。
# user.name / user.email が未設定の初回はallowed_signersへの追記だけが
# スキップされるので、~/.gitconfig.user.localを編集したあとに再実行する
print_section "Git Signing Key (Secure Enclave)"
if ! $HOME/.local/bin/gen-mac-git-signkey; then
  print_warning "Could not finish setting up the git signing key"
  print_info "Edit ~/.gitconfig.user.local, then run: gen-mac-git-signkey"
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

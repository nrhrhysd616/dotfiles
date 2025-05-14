#!/usr/bin/env zsh

# Check macOS
if [ $(uname) != "Darwin" ] ; then
  echo "Not macOS!"
  exit 1
fi

echo "This is macOS! Execute init-mac.zsh"

SCRIPT_DIR=$(cd $(dirname $0); pwd)

# Homebrew install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# zsh
# require fzf command
# require curl
# require Python3.8 Python3.9
# require volta
# require go
# require sdkman
ln -nfs $SCRIPT_DIR/zsh/.zshrc ~/
source ~/.zshrc
echo ".zshrc file created."

# Xcode Command Line Tools install
xcode-select --install

# install command function
# @param command command name (ex. 'git')
# @param checkCommand Command to check if installed (ex. 'brew list git')
# @param installCommand Command to install (ex. 'brew install git')
function __installCommand() {
  command=$1
  checkCommand=$2
  installCommand=$3
  eval $checkCommand > /dev/null 2>&1
  if [ $? -ne 0 ] ; then # $1 not found
    echo "$command not installed. install $command."
    eval $installCommand
    echo "$command installed."
  else
    echo "$command already installed."
  fi
}

# sqlite3 install
__installCommand 'sqlite3' 'brew list sqlite3' 'brew install sqlite'
# git brew install
__installCommand 'git' 'brew list git' 'brew install git'
# curl install
__installCommand 'curl' 'curl --version' 'brew install curl'
# fzf install
__installCommand 'fzf' 'fzf --version' 'brew install fzf'
# python3.8 install
# __installCommand 'python3.8' 'python3.8 --version' 'brew install python@3.8'
# python3.9 install
__installCommand 'python3.9' 'python3.9 --version' 'brew install python@3.9'
# volta install
__installCommand 'volta' 'volta --version' 'curl https://get.volta.sh | bash'
# go install
__installCommand 'go' 'go version' 'brew install go'
# sdkman install
__installCommand 'sdkman' 'sdk version' 'curl -s "https://get.sdkman.io" | bash; source "$HOME/.sdkman/bin/sdkman-init.sh"'
# bun install
# @see https://bun.sh/docs/installation
__installCommand 'bun' 'bun --version' 'volta install node;volta install bun'
# aws cli install
__installCommand 'aws' 'aws --version' 'brew install awscli'
# aws sam cli install
__installCommand 'sam' 'sam --version' 'brew install aws-sam-cli'
# install Font Fira Code
# Bug: フォントのインストール場所がおかしいため、手動で移動してbrewから削除
__installCommand 'Font Fira Code' 'ls ~/Library/Fonts/FiraCode-Regular.ttf' 'brew install font-fira-code && mv ~/\$\{HOME\}/Library/Fonts/* ~/Library/Fonts/ && rm -rf ~/\$\{HOME\} && brew uninstall font-fira-code'
# install ngrok
# @see https://ngrok.com/docs/getting-started/
__installCommand 'ngrok' 'ngrok -v' 'brew install ngrok/ngrok/ngrok'
# install stripe cli
# @see https://docs.stripe.com/stripe-cli?locale=ja-JP
__installCommand 'stripe' 'stripe -v' 'brew install stripe/stripe-cli/stripe'
# install vhs
# @see https://github.com/charmbracelet/vhs
__installCommand 'vhs' 'vhs -v' 'brew install vhs'

# Java install
# After set sdk command path in .zshrc, install Java
__installCommand 'Java11' 'sdk home java 11.0.26-amzn' 'sdk install java 11.0.26-amzn'
__installCommand 'Java17' 'sdk home java 17.0.14-amzn' 'sdk install java 17.0.14-amzn'
__installCommand 'Java18' 'sdk home java 18.0.2-amzn' 'sdk install java 18.0.2-amzn'

# git setting
ln -nfs $SCRIPT_DIR/git/.gitconfig ~/
ln -nfs $SCRIPT_DIR/git/.gitignore_global ~/
if [ ! -f ~/.gitconfig.user.local ]; then
  cp $SCRIPT_DIR/git/.gitconfig.user.local ~/
fi
echo "git configuration files created."

# Cursor user settings
# Require Cursor application
# Cursor未使用なためコメントアウト
ln -nfs $SCRIPT_DIR/cursor/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
ln -nfs $SCRIPT_DIR/cursor/keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json

# VSCode user settings
# Require VSCode application
ln -nfs $SCRIPT_DIR/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -nfs $SCRIPT_DIR/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

# VSCode - Insiders user settings
# Require VSCode application
ln -nfs $SCRIPT_DIR/vscode-insiders/settings.json ~/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
ln -nfs $SCRIPT_DIR/vscode-insiders/keybindings.json ~/Library/Application\ Support/Code\ -\ Insiders/User/keybindings.json

# iTerm2 shell integration install
curl -sL https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
echo "iTerm2 shell integration installed."

# System Configuration
# Do not create .DS_Store on USB or Network drives
defaults write -g KeyRepeat -int 1 
defaults write -g InitialKeyRepeat -int 10
networksetup -setdnsservers Wi-Fi 2001:4860:4860::8844 2001:4860:4860::8888 8.8.4.4 8.8.8.8
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder WarnOnEmptyTrash -bool false
defaults write com.apple.finder _FXShowPosixPathInTitle -boolean true && killall Finder

echo "macOS System Configuration done."

echo "Complete!"
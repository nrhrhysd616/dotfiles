#!/usr/bin/env zsh

# Check macOS
if [ $(uname) != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
else
	echo "This is macOS! Execute mac-init.zsh"
fi

SCRIPT_DIR=$(cd $(dirname $0); pwd)

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

# brew install
__installCommand 'brew' 'brew --version' '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
# git brew install
__installCommand 'git' 'brew list git' 'brew install git'
# curl install
__installCommand 'curl' 'curl --version' 'brew install curl'
# fzf install
__installCommand 'fzf' 'fzf --version' 'brew install fzf'
# python3.8 install
__installCommand 'python3.8' 'python3.8 --version' 'brew install python@3.8'
# python3.9 install
__installCommand 'python3.9' 'python3.9 --version' 'brew install python@3.9'
# volta install
__installCommand 'volta' 'volta --version' 'curl https://get.volta.sh | bash'
# go install
__installCommand 'go' 'go version' 'brew install go'
# sdkman install
__installCommand 'sdkman' 'curl -s "https://get.sdkman.io"' 'curl -s "https://get.sdkman.io" | bash; source "$HOME/.sdkman/bin/sdkman-init.sh"'
# bun install
# @see https://bun.sh/docs/installation
__installCommand 'bun' 'bun --version' 'brew tap oven-sh/bun; brew install bun'

# zsh
# require curl
# require fzf command
# require Python3.8 Python3.9
# require nodebrew
# require go
# require sdkman
# require bun
ln -nfs $SCRIPT_DIR/zsh/.zshrc ~/
echo ".zshrc file created."

# git setting
ln -nfs $SCRIPT_DIR/git/.gitconfig ~/
ln -nfs $SCRIPT_DIR/git/.gitignore_global ~/
if [ ! -f ~/.gitconfig.user.local ]; then
	cp $SCRIPT_DIR/git/.gitconfig.user.local ~/
fi
echo "git configuration files created."

# Cursor user settings
# Require Cursor application
ln -nfs $SCRIPT_DIR/cursor/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
ln -nfs $SCRIPT_DIR/cursor/keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json

# iTerm2 shell integration install
curl -sL https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
echo "iTerm2 shell integration installed."

# System Configuration
# Do not create .DS_Store on USB or Network drives
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
echo "macOS System Configuration done."

echo "Complete!"
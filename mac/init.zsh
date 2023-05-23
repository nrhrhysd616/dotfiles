#!/usr/bin/env zsh

# Check macOS
if [ $(uname) != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
fi

SCRIPT_DIR=$(cd $(dirname $0); pwd)

# brew install
#type brew > /dev/null 2>&1
#if [ $? -ne 0 ] ; then # brew command not found
#	echo "brew not installed. install brew."
#	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#	brew install fzf
#fi

# zsh
# require fzf command
# require php7.3
# require Python3.7 Python3.8
# require nodebrew
# require curl
ln -nfs $SCRIPT_DIR/zsh/.zshrc ~/

# git
ln -nfs $SCRIPT_DIR/git/.gitconfig ~/
ln -nfs $SCRIPT_DIR/git/.gitignore_global ~/
if [ ! -f ~/.gitconfig.user.local ]; then
	cp $SCRIPT_DIR/git/.gitconfig.user.local ~/
fi

# System Configuration
# Do not create .DS_Store on USB or Network drives
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

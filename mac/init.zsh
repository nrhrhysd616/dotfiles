#!/usr/bin/env zsh

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
ln -nfs $SCRIPT_DIR/zsh/.zshrc ~/

# git
ln -nfs $SCRIPT_DIR/git/.gitconfig ~/
ln -nfs $SCRIPT_DIR/git/.gitignore_global ~/
if [ ! -f ~/.gitconfig.user.local ]; then
	cp $SCRIPT_DIR/git/.gitconfig.user.local ~/
fi



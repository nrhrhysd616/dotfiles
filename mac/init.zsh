#!/usr/bin/env zsh

SCRIPT_DIR=$(cd $(dirname $0); pwd)

# zsh
ln -nfs $SCRIPT_DIR/zsh/.zshrc ~/

# git
ln -nfs $SCRIPT_DIR/git/.gitconfig ~/
ln -nfs $SCRIPT_DIR/git/.gitignore_global ~/
if [ ! -f ~/.gitconfig.user.local ]; then
	cp $SCRIPT_DIR/git/.gitconfig.user.local ~/
fi



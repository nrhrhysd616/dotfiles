#!/usr/bin/env zsh

# Check macOS
if [ $(uname) != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
else
	echo "This is macOS! Execute init.zsh"
fi


SCRIPT_DIR=$(cd $(dirname $0); pwd)

# brew install
type brew > /dev/null 2>&1
if [ $? -ne 0 ] ; then # brew not found
	echo "brew not installed. install brew."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	echo "brew installed."
else
	echo "brew already installed."
fi

# curl install
type curl > /dev/null 2>&1
if [ $? -ne 0 ] ; then # curl not found
	echo "curl not installed. install curl."
	brew install curl
	echo "curl installed."
else
	echo "curl already installed."
fi

# fzf install
type fzf > /dev/null 2>&1
if [ $? -ne 0 ] ; then # fzf not found
	echo "fzf not installed. install fzf."
	brew install fzf
	echo "fzf installed."
else
	echo "fzf already installed."
fi

# Python3.8 install
type python3.8 > /dev/null 2>&1
if [ $? -ne 0 ] ; then # python3.8 not found
	echo "python3.8 not installed. install python3.8."
	brew install python@3.8
	echo "python3.8 installed."
else
	echo "python3.8 already installed."
fi

# Python3.9 install
type python3.9 > /dev/null 2>&1
if [ $? -ne 0 ] ; then # python3.9 not found
	echo "python3.9 not installed. install python3.9."
	brew install python@3.9
	echo "python3.9 installed."
else
	echo "python3.9 already installed."
fi

type volta > /dev/null 2>&1
if [ $? -ne 0 ] ; then # volta not found
	echo "volta not installed. install volta."
	# @see https://docs.volta.sh/guide/getting-started
	curl https://get.volta.sh | bash
	echo "volta installed."
else
	echo "volta already installed."
fi

# go install
type go > /dev/null 2>&1
if [ $? -ne 0 ] ; then # go not found
	echo "go not installed. install go."
	brew install go
	echo "go installed."
else
	echo "go already installed."
fi

# sdkman install
curl -s "https://get.sdkman.io" | bash > /dev/null 2>&1
if [ $? -ne 0 ] ; then # sdkman not found
	echo "sdkman not installed. install sdkman."
	# @see https://sdkman.io/install
	curl -s "https://get.sdkman.io" | bash
	source "$HOME/.sdkman/bin/sdkman-init.sh"
	echo "sdkman installed."
else
	echo "sdkman already installed."
fi

type bun > /dev/null 2>&1
if [ $? -ne 0 ] ; then # bun not found
	echo "bun not installed. install bun."
	# @see https://bun.sh/docs/installation
	brew tap oven-sh/bun
	brew install bun
	echo "bun installed."
else
	echo "bun already installed."
fi

# zsh
# require curl
# require fzf command
# require Python3.7 Python3.8 Python3.9
# require nodebrew
# require go
# require sdkman
# require bun
ln -nfs $SCRIPT_DIR/zsh/.zshrc ~/
echo ".zshrc file created."

# git
ln -nfs $SCRIPT_DIR/git/.gitconfig ~/
ln -nfs $SCRIPT_DIR/git/.gitignore_global ~/
if [ ! -f ~/.gitconfig.user.local ]; then
	cp $SCRIPT_DIR/git/.gitconfig.user.local ~/
fi
echo "git configuration files created."

# System Configuration
# Do not create .DS_Store on USB or Network drives
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
echo "macOS System Configuration done."

echo "Complete!"
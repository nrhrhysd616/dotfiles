#!/usr/bin/env zsh

# Check macOS
if [ $(uname) != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
else
	echo "This is macOS! Execute mac-init.zsh"
fi

# iTerm2 shell integration install
curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
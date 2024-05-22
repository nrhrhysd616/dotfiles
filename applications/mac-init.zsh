#!/usr/bin/env zsh

# Check macOS
if [ $(uname) != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
else
	echo "This is macOS! Execute mac-init.zsh"
fi

SCRIPT_DIR=$(cd $(dirname $0); pwd)

# Cursor user settings
# require Cursor application
ln -nfs $SCRIPT_DIR/cursor/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
ln -nfs $SCRIPT_DIR/cursor/keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json

# iTerm2 shell integration install
curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
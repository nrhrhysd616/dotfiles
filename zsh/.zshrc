# homebrew PATH
if [ "$(uname -m)" = "arm64" ]; then
  # For arm64
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  # For x86_64
fi

# Alias
alias cdproject='cd ~/Documents/Project/'
alias ..='cd ..'
alias ls='ls -F'
alias la='ls -A'
alias ll='ls -lh'
alias lla='ll -A'
alias speedtest='networkQuality'

# historyexec command
function historyexec() {
  # コマンド履歴を番号なし(-n)降順(-r)直近500件(-500)で取得したものをfzfに渡し、複数選択なし(--no-multi)で選択したコマンドをevalで実行
  eval `history -n -r -500 | fzf --no-multi --prompt="Command history >"`
}

# fetch gitignore
function gitignore() { curl -sLw n https://www.toptal.com/developers/gitignore/api/$@ ;}

# Python 3.8
export PATH="/usr/local/opt/python@3.8/bin:$PATH"
# Python 3.9
export PATH="/usr/local/opt/python@3.9/bin:$PATH"

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# curl
export PATH="/usr/local/opt/curl/bin:$PATH"

# go library
export PATH="$HOME/go/bin:$PATH"

# SQLite3
export PATH="/usr/local/opt/sqlite/bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# iTerm2 shell integration load
[[ -s "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"

# Herd configurations
[[ -d "$HOME/Library/Application Support/Herd" ]] # @see https://zsh.sourceforge.io/Doc/Release/Conditional-Expressions.html#Conditional-Expressions
if [ $? -eq 0 ] ; then
  # Herd injected PHP binary.
  export PATH="$HOME/Library/Application Support/Herd/bin":$PATH
  # Herd injected PHP 8.3 configuration.
  export HERD_PHP_83_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/83/"
fi

# Claude code
export PATH="$HOME/.bun/bin:$PATH"

# Prompt
local p_current="%F{green}@%2d%f"
local p_history="%F{yellow}%!%f"
local p_endmark="%B%(?,%F{green}$,%F{red}!!\$!!)%f%b"
PROMPT="$p_current $p_history$p_endmark"

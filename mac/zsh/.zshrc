# Alias
alias cdproject='cd ~/Documents/project/'
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

# Python 3.7
export PATH="/usr/local/opt/python@3.7/bin:$PATH"
# Python 3.8
export PATH="/usr/local/opt/python@3.8/bin:$PATH"
# Python 3.9
export PATH="/usr/local/opt/python@3.9/bin:$PATH"

# nodebrew
export NODEBREW_ROOT=/usr/local/var/nodebrew
export PATH=$NODEBREW_ROOT/current/bin:$PATH

# curl
export PATH="/usr/local/opt/curl/bin:$PATH"

# boost
export BOOST_ROOT=/usr/local/opt/boost

# go library
export PATH="$HOME/go/bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Prompt
local p_current="%F{green}@%2d%f"
local p_history="%F{yellow}%!%f"
local p_endmark="%B%(?,%F{green}$,%F{red}!!!\$!!!)%f%b"
PROMPT="$p_current $p_history$p_endmark"


# Nix PATH - 最優先で読み込み
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# homebrew PATH
if [ "$(uname -m)" = "arm64" ]; then
  # For arm64
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  # For x86_64
fi

# Alias
alias cdproject='cd ~/Documents/Project'
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

# mise (multi-language version manager)
eval "$(mise activate zsh)"

# $HOME/.local/bin PATH
export PATH="$HOME/.local/bin:$PATH"

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

# Prompt
local p_current="%F{green}@%2d%f"
local p_history="%F{yellow}%!%f"
local p_endmark="%B%(?,%F{green}$,%F{red}!!\$!!)%f%b"
PROMPT="$p_current $p_history$p_endmark"

# tmux auto-attach (interactive, non-tmux, non-vscode terminal)
# $-はシェルオプションフラグの文字列。"i"が含まれていればインタラクティブシェル（手動操作用）
# -z "$TMUX" はtmux内でなければtrue（二重起動を防ぐ）
# "$TERM_PROGRAM" != "vscode" はVSCode統合ターミナルを除外
if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then
  # $SSH_CLIENT はSSH接続元のIPとポートが入る変数（SSH接続時のみセットされる）
  # $SSH_TTY はSSH接続時に割り当てられた端末デバイスのパス（SSH接続時のみセットされる）
  # どちらか一方でもセットされていればSSH接続と判定する
  if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    # SSH接続時は専用セッション "remote" にアタッチ（なければ新規作成）
    tmux new-session -A -s remote
  else
    # ローカル起動時はメインセッション "main" にアタッチ（なければ新規作成）
    tmux new-session -A -s main
  fi
fi

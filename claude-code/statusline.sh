#!/bin/bash

# Claude Code から stdin 経由で渡される JSON を読み込む
input=$(cat)

# コンテキスト使用率（%）を整数に丸める
# used_percentage = (input_tokens + cache_tokens) / context_window_size * 100
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%.0f", $1}')

# 実際の使用トークン数（input + cache_creation + cache_read の合計）
USED=$(echo "$input" | jq -r '
  (.context_window.current_usage.input_tokens // 0)
  + (.context_window.current_usage.cache_creation_input_tokens // 0)
  + (.context_window.current_usage.cache_read_input_tokens // 0)')

# 最大コンテキストウィンドウサイズ（トークン数）
TOTAL=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

# モデル名と現在のディレクトリを取得
MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')

# Gitリポジトリの場合にブランチ名を取得
GIT_BRANCH=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        GIT_BRANCH=" | 🌿 $BRANCH"
    fi
fi

# コンテキスト使用率が80%以上の場合は赤色にする
RED='\033[31m'
RESET='\033[0m'

if [ "$PCT" -ge 80 ]; then
    CONTEXT_TEXT="${RED}Context: ${PCT}% (${USED}/${TOTAL} tokens)${RESET}"
else
    CONTEXT_TEXT="Context: ${PCT}% (${USED}/${TOTAL} tokens)"
fi

# ステータスラインに出力（例: "Context: 42% (85000/200000 tokens)  [Sonnet 4.6] 📁 org/my_project | 🌿 develop）
echo -e "${CONTEXT_TEXT}  [$MODEL_DISPLAY] 📁 ${CURRENT_DIR##*github.com/}$GIT_BRANCH"

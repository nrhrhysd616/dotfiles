#!/bin/bash

# ~/.claude/statusline.sh はこのファイルへのシンボリックリンクのため、
# BASH_SOURCE をそのまま使うとリンク先ではなくリンク自体のパスになる。
# RunCat Neo向けメトリクスJSONの出力先を本リポジトリ内に固定するため実体パスを解決する
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
RUNCAT_JSON="$SCRIPT_DIR/runcat-metrics.json"

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

# セッションの累計コスト（USD）を取得
COST_USD=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# レート制限の使用率（%）とリセット時刻（resets_at: Unix epoch秒）。
# Pro/Maxプランかつ初回API応答後のみ存在し、各ウィンドウは独立して欠落しうるため、
# 値が無い場合は空文字のままにしておき、後段で存在チェックする
FIVE_HOUR_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_HOUR_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
SEVEN_DAY_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
SEVEN_DAY_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# スクリプトはセッション開始時のディレクトリで実行されるため、
# セッション中のディレクトリ移動に追従するよう workspace.current_dir へ移動する
cd "$CURRENT_DIR" 2>/dev/null

# Gitリポジトリの場合にブランチ名を取得
GIT_BRANCH=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        GIT_BRANCH=" | 🌿 $BRANCH"
    fi
fi

# コンテキスト使用率が70%以上の場合は赤色にする
RED='\033[31m'
RESET='\033[0m'

if [ "$PCT" -ge 70 ]; then
    CONTEXT_TEXT="${RED}Context: ${PCT}% (${USED}/${TOTAL} tokens)${RESET}"
else
    CONTEXT_TEXT="Context: ${PCT}% (${USED}/${TOTAL} tokens)"
fi

# ステータスラインに出力（例: "Context: 42% (85000/200000 tokens)  [Sonnet 4.6] 📁 org/my_project | 🌿 develop）
echo -e "${CONTEXT_TEXT}  [$MODEL_DISPLAY] 📁 ${CURRENT_DIR##*github.com/}$GIT_BRANCH"

# RunCat Neo (https://github.com/runcat-dev/RunCatNeo) のCustom Metrics向けにJSONを出力する。
# 本来の役割であるステータスライン出力に影響を与えないよう、失敗しても握りつぶす
{
    NORMALIZED_PCT=$(awk -v p="$PCT" 'BEGIN { v = p / 100; if (v < 0) v = 0; if (v > 1) v = 1; printf "%.4f", v }')
    COST_FORMATTED=$(awk -v c="$COST_USD" 'BEGIN { printf "$%.2f", c }')
    NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    NOW_EPOCH=$(date +%s)

    # resets_at（Unix epoch秒）と現在時刻の差から「あと何分/時間/日でリセットか」を組み立てる。
    # 例: 45m / 2h30m / 4d21h。RunCat NeoはJSONをポーリング表示するため、
    # statuslineが再実行されるまで相対時間は固定される（時間経過で実態とズレる）点に留意
    format_reset() {
        awk -v r="$1" -v n="$2" 'BEGIN {
            diff = r - n
            if (diff < 0) diff = 0
            d = int(diff / 86400)
            h = int((diff % 86400) / 3600)
            m = int((diff % 3600) / 60)
            if (d > 0) printf "%dd%dh", d, h
            else if (h > 0) printf "%dh%dm", h, m
            else printf "%dm", m
        }'
    }

    # 5時間/7日のレート制限は値が存在する場合のみformattedValue/normalizedValueを組み立てる。
    # resets_atがあれば「 (resets in ...)」を併記する
    FIVE_HOUR_FORMATTED=""
    FIVE_HOUR_NORM="0"
    if [ -n "$FIVE_HOUR_PCT" ]; then
        FIVE_HOUR_FORMATTED="$(awk -v p="$FIVE_HOUR_PCT" 'BEGIN { printf "%.0f%%", p }')"
        if [ -n "$FIVE_HOUR_RESET" ]; then
            FIVE_HOUR_FORMATTED="$FIVE_HOUR_FORMATTED (resets in $(format_reset "$FIVE_HOUR_RESET" "$NOW_EPOCH"))"
        fi
        FIVE_HOUR_NORM=$(awk -v p="$FIVE_HOUR_PCT" 'BEGIN { v = p / 100; if (v < 0) v = 0; if (v > 1) v = 1; printf "%.4f", v }')
    fi

    SEVEN_DAY_FORMATTED=""
    SEVEN_DAY_NORM="0"
    if [ -n "$SEVEN_DAY_PCT" ]; then
        SEVEN_DAY_FORMATTED="$(awk -v p="$SEVEN_DAY_PCT" 'BEGIN { printf "%.0f%%", p }')"
        if [ -n "$SEVEN_DAY_RESET" ]; then
            SEVEN_DAY_FORMATTED="$SEVEN_DAY_FORMATTED (resets in $(format_reset "$SEVEN_DAY_RESET" "$NOW_EPOCH"))"
        fi
        SEVEN_DAY_NORM=$(awk -v p="$SEVEN_DAY_PCT" 'BEGIN { v = p / 100; if (v < 0) v = 0; if (v > 1) v = 1; printf "%.4f", v }')
    fi

    jq -n \
        --arg title "Claude Code" \
        --arg symbol "staroflife" \
        --arg barValue "${PCT}%" \
        --arg model "$MODEL_DISPLAY" \
        --arg contextFormatted "${PCT}% (${USED}/${TOTAL} tokens)" \
        --argjson contextNorm "$NORMALIZED_PCT" \
        --arg costFormatted "$COST_FORMATTED" \
        --arg dirLabel "${CURRENT_DIR##*github.com/}" \
        --arg branchLabel "$BRANCH" \
        --arg fiveHourFormatted "$FIVE_HOUR_FORMATTED" \
        --argjson fiveHourNorm "$FIVE_HOUR_NORM" \
        --arg sevenDayFormatted "$SEVEN_DAY_FORMATTED" \
        --argjson sevenDayNorm "$SEVEN_DAY_NORM" \
        --arg now "$NOW_ISO" \
        '{
            title: $title,
            symbol: $symbol,
            metricsBarValue: $barValue,
            metrics: (
                [
                    { title: "Model", formattedValue: $model },
                    { title: "Context", formattedValue: $contextFormatted, normalizedValue: $contextNorm },
                    { title: "Cost", formattedValue: $costFormatted },
                    { title: "Directory", formattedValue: $dirLabel }
                ]
                + (if $branchLabel != "" then [{ title: "Branch", formattedValue: $branchLabel }] else [] end)
                + (if $fiveHourFormatted != "" then [{ title: "5h Usage", formattedValue: $fiveHourFormatted, normalizedValue: $fiveHourNorm }] else [] end)
                + (if $sevenDayFormatted != "" then [{ title: "7-Day Usage", formattedValue: $sevenDayFormatted, normalizedValue: $sevenDayNorm }] else [] end)
            ),
            lastUpdatedDate: $now
        }' >"${RUNCAT_JSON}.tmp.$$" && mv "${RUNCAT_JSON}.tmp.$$" "$RUNCAT_JSON"
} 2>/dev/null || true

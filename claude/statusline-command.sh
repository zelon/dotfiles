#!/usr/bin/env bash

input=$(cat)

#echo "$input" > D:/tmp/claude-statusline-input.json

parse() {
  echo "$input" | python -c "
import json, sys
d = json.load(sys.stdin)
key = '$1'
parts = key.split('.')
val = d
try:
    for p in parts:
        val = val[p]
    print(val)
except:
    print('')
"
}

# ASCII Color Codes
WHITE='\033[36m'
CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; BLUE='\033[34m'
RESET='\033[0m'

# 2. Current directory
cwd=$(parse "cwd")

# context window
context_used_percent=$(parse "context_window.used_percentage")
context_remaining_percent=$(parse "context_window.remaining_percentage")

# current branch
current_branch=""
git rev-parse --git-dir > /dev/null 2>&1 && current_branch="$(git branch --show-current 2>/dev/null)"

TZ=Asia/Seoul

# 3. 5-hour rate limit usage
five_percent=$(parse "rate_limits.five_hour.used_percentage")
five_reset_stamp=$(parse "rate_limits.five_hour.resets_at")
five_resets="$(date -d @$five_reset_stamp "+%Y-%m-%d %H:%M:%S %Z")"

# weekly reset
week_percent=$(parse "rate_limits.seven_day.used_percentage")
week_reset_stamp=$(parse "rate_limits.seven_day.resets_at")
week_resets="$(date -d @$week_reset_stamp "+%Y-%m-%d %H:%M:%S %Z")"

# select color
CONTEXT_WINDOW_COLOR=""
if [ "$context_used_percent" -ge 80 ]; then CONTEXT_WINDOW_COLOR="$YELLOW"
fi
if [ "$context_used_percent" -ge 90 ]; then CONTEXT_WINDOW_COLOR="$RED"
fi
CURRENT_USAGE_COLOR=""
if [ "$five_percent" -ge 70 ]; then CURRENT_USAGE_COLOR="$YELLOW"
fi
if [ "$five_percent" -ge 90 ]; then CURRENT_USAGE_COLOR="$RED"
fi
WEEK_USAGE_COLOR=""
if [ "$week_percent" -ge 70 ]; then WEEK_USAGE_COLOR="$YELLOW"
fi
if [ "$week_percent" -ge 90 ]; then WEEK_USAGE_COLOR="$RED"
fi

FILLED=$((five_percent / 10)); EMPTY=$((10 - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
current_bar="${FILL// /█}${PAD// /░}"

FILLED=$((week_percent / 10)); EMPTY=$((10 - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
week_bar="${FILL// /█}${PAD// /░}"

# OUTPUT
echo -e "${cwd} | 🌿 ${current_branch} |${CONTEXT_WINDOW_COLOR} context_window_used: ${context_used_percent}% ${RESET}"
echo -e "${CURRENT_USAGE_COLOR} current: ${current_bar} ${five_percent}%, reset: ${five_resets} ${RESET}"
echo -e "${WEEK_USAGE_COLOR}    week: ${week_bar} ${week_percent}%, reset: ${week_resets} ${RESET}"

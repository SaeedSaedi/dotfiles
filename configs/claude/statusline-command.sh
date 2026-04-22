#!/bin/sh
# Claude Code status line — modern design with progress bar and icons
input=$(cat)

# ── ANSI palette (256-color for VS Code + terminal) ───────────────────────────
R='\033[0m'
DIM='\033[2m'
BOLD='\033[1m'
CYAN='\033[38;5;80m'
BLUE='\033[38;5;111m'
PURPLE='\033[38;5;183m'
GREEN='\033[38;5;114m'
YELLOW='\033[38;5;221m'
RED='\033[38;5;203m'
ORANGE='\033[38;5;215m'
GRAY='\033[38;5;244m'
SEP="${DIM} │ ${R}"

# ── Data ──────────────────────────────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
dir=$(basename "$cwd")

branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
        || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
fi

model=$(echo "$input" | jq -r '.model.display_name // ""' | sed 's/Claude //')

used_pct=$(echo   "$input" | jq -r '.context_window.used_percentage // empty')
remaining=$(echo  "$input" | jq -r '.context_window.remaining_percentage // empty')
total_in=$(echo   "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo  "$input" | jq -r '.context_window.total_output_tokens // 0')
cur_in=$(echo     "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cur_cw=$(echo     "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cur_cr=$(echo     "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
five_pct=$(echo   "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo   "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ── Cost (Sonnet 4.6 pricing) ─────────────────────────────────────────────────
cost=""
if [ "$total_in" -gt 0 ] 2>/dev/null || [ "$total_out" -gt 0 ] 2>/dev/null; then
  cost=$(printf '%s %s %s %s' "$total_in" "$total_out" "$cur_cw" "$cur_cr" | awk '{
    c = ($1*3 + $3*3.75 + $4*0.30) / 1e6 + $2*15/1e6
    if (c < 0.01) printf "<$0.01"
    else          printf "$%.2f", c
  }')
fi

# ── 10-cell block progress bar ────────────────────────────────────────────────
bar() {
  pct="$1" width=10
  filled=$(printf '%s %s' "$pct" "$width" | awk '{printf "%d", $1*$2/100+0.5}')
  empty=$((width - filled))
  out="" i=0
  while [ $i -lt $filled ]; do out="${out}█"; i=$((i+1)); done
  while [ $i -lt $width  ]; do out="${out}░"; i=$((i+1)); done
  printf '%s' "$out"
}

# ── Render ────────────────────────────────────────────────────────────────────

# Directory
printf "${BOLD}${CYAN}%s${R}" "$dir"

# Branch
if [ -n "$branch" ]; then
  printf " ${DIM}on${R} ${PURPLE}⎇  %s${R}" "$branch"
fi

printf "${SEP}"

# Model
printf "${BLUE}◈ %s${R}" "$model"

# Context progress bar
if [ -n "$used_pct" ] && [ -n "$remaining" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  b=$(bar "$used_int")
  if   [ "$used_int" -ge 80 ] 2>/dev/null; then bc="$RED"
  elif [ "$used_int" -ge 50 ] 2>/dev/null; then bc="$YELLOW"
  else                                          bc="$GREEN"
  fi
  printf "${SEP}${bc}%s${R} ${DIM}%s%%${R}" "$b" "$used_int"
fi

# Token count
if [ "$cur_in" -gt 0 ] 2>/dev/null; then
  tok=$(printf '%s' "$cur_in" | awk '{printf "%.1fk", $1/1000}')
  printf " ${GRAY}∙ %s tok${R}" "$tok"
fi

# Session cost
if [ -n "$cost" ]; then
  printf "${SEP}${ORANGE}%s${R}" "$cost"
fi

# Rate limits
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  printf "${SEP}"
  [ -n "$five_pct" ] && printf "${GRAY}5h $(printf '%.0f' "$five_pct")%%${R} "
  [ -n "$week_pct" ] && printf "${GRAY}7d $(printf '%.0f' "$week_pct")%%${R}"
fi

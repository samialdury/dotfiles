#!/usr/bin/env bash
# Claude Code statusline script
# Outputs: branch + model + context %

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

branch=$(echo "$input" | jq -r '.worktree.branch // empty')
if [ -z "$branch" ] && [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || true)
fi
if [ -n "$branch" ]; then
  branch_part=$(printf '\033[33m(%s)\033[0m' "$branch")
else
  branch_part=""
fi

model=$(echo "$input" | jq -r '.model.display_name // empty')
if [ -n "$model" ]; then
  model_part=$(printf '\033[35m%s\033[0m' "$model")
else
  model_part=""
fi

effort=$(echo "$input" | jq -r '.effort.level // empty')
if [ -n "$effort" ]; then
  effort_upper=$(printf '%s' "$effort" | tr '[:lower:]' '[:upper:]')
  effort_part=$(printf '\033[36m%s\033[0m' "$effort_upper")
else
  effort_part=""
fi

ctx_json=$(echo "$input" | jq -r '
  .context_window
  | {
      used_pct: (.used_percentage // empty),
      remaining_pct: (.remaining_percentage // empty),
      used: (((.total_input_tokens // 0) + (.total_output_tokens // 0)) | if . > 0 then . else empty end),
      total: (.context_window_size // empty)
    }
  | @json
')
used_pct=$(echo "$ctx_json" | jq -r '.used_pct // empty')
remaining=$(echo "$ctx_json" | jq -r '.remaining_pct // empty')
used_tokens=$(echo "$ctx_json" | jq -r '.used // empty')
total_tokens=$(echo "$ctx_json" | jq -r '.total // empty')

format_tokens() {
  local n=$1
  if [ -z "$n" ] || [ "$n" = "null" ]; then
    printf ''
    return
  fi
  if [ "$n" -ge 1000000 ]; then
    awk -v n="$n" 'BEGIN { printf "%.1fm", n/1000000 }' | sed 's/\.0m/m/'
  elif [ "$n" -ge 1000 ]; then
    awk -v n="$n" 'BEGIN { printf "%dk", n/1000 }'
  else
    printf '%s' "$n"
  fi
}

if [ -n "$used_pct" ] || [ -n "$remaining" ]; then
  if [ -n "$used_pct" ]; then
    used_int=$(printf '%.0f' "$used_pct")
  else
    remaining_int=$(printf '%.0f' "$remaining")
    used_int=$((100 - remaining_int))
  fi

  tokens_suffix=""
  if [ -n "$used_tokens" ] && [ -n "$total_tokens" ] && [ "$used_tokens" != "null" ] && [ "$total_tokens" != "null" ]; then
    used_fmt=$(format_tokens "$used_tokens")
    total_fmt=$(format_tokens "$total_tokens")
    tokens_suffix=" ($used_fmt/$total_fmt)"
  fi

  if [ "$used_int" -ge 80 ]; then
    color=31
  elif [ "$used_int" -ge 60 ]; then
    color=33
  else
    color=32
  fi
  ctx_part=$(printf '\033[%sm%s%%%s\033[0m' "$color" "$used_int" "$tokens_suffix")
else
  ctx_part=""
fi

parts=()
[ -n "$branch_part" ] && parts+=("$branch_part")
[ -n "$model_part" ]  && parts+=("$model_part")
[ -n "$effort_part" ] && parts+=("$effort_part")
[ -n "$ctx_part" ]    && parts+=("$ctx_part")

out=""
for part in "${parts[@]}"; do
  if [ -z "$out" ]; then
    out="$part"
  else
    out="$out  $part"
  fi
done

printf '%s' "$out"

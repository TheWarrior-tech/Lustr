#!/usr/bin/env bash
# Lustr — disk usage analyzer
# shellcheck disable=SC1091

lustr_analyze() {
  ui_section "Disk analysis"

  ui_disk_meter
  printf "\n"

  local locations=(
    "Home|$HOME"
    "Applications|/Applications"
    "User Library|$HOME/Library"
    "Caches|$HOME/Library/Caches"
    "Application Support|$HOME/Library/Application Support"
    "Containers|$HOME/Library/Containers"
    "Developer|$HOME/Library/Developer"
    "Documents|$HOME/Documents"
    "Downloads|$HOME/Downloads"
    "Desktop|$HOME/Desktop"
    "Movies|$HOME/Movies"
    "Music|$HOME/Music"
    "Pictures|$HOME/Pictures"
    "Trash|$HOME/.Trash"
  )

  start_spinner "Measuring key locations..."

  declare -a rows=()
  local entry name path size
  for entry in "${locations[@]}"; do
    name="${entry%%|*}"
    path="${entry#*|}"
    if [[ -e "$path" ]]; then
      size=$(dir_size "$path")
    else
      size=0
    fi
    rows+=("${size}|${name}|${path}")
  done

  stop_spinner

  # Sort by size desc
  local sorted line size name path max=0 pct bar_w filled empty
  local content_w loc_w
  content_w=$(ui_content_width)
  loc_w=$(( content_w / 3 ))
  (( loc_w < 16 )) && loc_w=16
  (( loc_w > 28 )) && loc_w=28
  bar_w=$(( content_w - loc_w - 18 ))
  (( bar_w < 12 )) && bar_w=12
  (( bar_w > 44 )) && bar_w=44
  sorted=$(printf '%s\n' "${rows[@]}" | sort -t'|' -k1 -nr)

  # Find max for relative bars
  max=$(echo "$sorted" | head -1 | cut -d'|' -f1)
  [[ -z "$max" || "$max" -eq 0 ]] && max=1

  printf "  ${DIM}%-*s  %10s   usage${RESET}\n" "$loc_w" "Location" "Size"
  ui_divider "·"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    size=$(echo "$line" | cut -d'|' -f1)
    name=$(echo "$line" | cut -d'|' -f2)
    (( size == 0 )) && continue
    pct=$(( size * 100 / max ))
    (( pct < 1 && size > 0 )) && pct=1
    filled=$(( pct * bar_w / 100 ))
    empty=$(( bar_w - filled ))

    printf "  ${WHITE}%-*s${RESET}  ${BOLD}%10s${RESET}   ${TEAL}" \
      "$loc_w" "$(ui_truncate "$name" "$loc_w")" "$(bytes_human "$size")"
    printf "%*s" "$filled" "" | tr ' ' '█'
    printf "${DARK}"
    printf "%*s" "$empty" "" | tr ' ' '░'
    printf "${RESET}\n"
  done <<< "$sorted"

  printf "\n"
  ui_dim "Tip: run  lustr clean --dry-run  to preview safe reclaimable junk."
  printf "\n"
}

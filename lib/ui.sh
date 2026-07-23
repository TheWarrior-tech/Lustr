#!/usr/bin/env bash
# Lustr — premium terminal UI
# shellcheck disable=SC1091

# ── Branding ──────────────────────────────────────────────────────────
ui_banner() {
  local cols
  cols=$(term_cols)
  printf "\n"
  printf "  ${CYAN}${BOLD}"
  cat << 'EOF'
  ╦  ╦ ╦╔═╗╔╦╗╦═╗
  ║  ║ ║╚═╗ ║ ╠╦╝
  ╩═╝╚═╝╚═╝ ╩ ╩╚═
EOF
  printf "${RESET}"
  printf "  ${DIM}Polish your Mac. Keep what matters.${RESET}\n"
  printf "  ${GRAY}v%s${RESET}\n\n" "$LUSTR_VERSION"
}

ui_divider() {
  local cols char="${1:-─}"
  cols=$(term_cols)
  local width=$(( cols < 72 ? cols - 4 : 68 ))
  printf "  ${DARK}"
  printf "%*s" "$width" "" | tr ' ' "$char"
  printf "${RESET}\n"
}

ui_section() {
  local title="$1"
  printf "\n  ${VIOLET}${BOLD}%s${RESET}\n" "$title"
  ui_divider "·"
}

ui_item() {
  # ui_item STATUS LABEL SIZE [DETAIL]
  local status="$1" label="$2" size="${3:-}" detail="${4:-}"
  local icon color
  case "$status" in
    ok|done|clean) icon="✓"; color="$GREEN" ;;
    skip)          icon="○"; color="$GRAY" ;;
    warn)          icon="!"; color="$ORANGE" ;;
    err|fail)      icon="✗"; color="$RED" ;;
    scan|info)     icon="·"; color="$CYAN" ;;
    dry)           icon="◇"; color="$GOLD" ;;
    *)             icon="·"; color="$CYAN" ;;
  esac

  printf "  ${color}%s${RESET}  %-36s" "$icon" "$label"
  if [[ -n "$size" ]]; then
    printf "  ${BOLD}%10s${RESET}" "$size"
  fi
  if [[ -n "$detail" ]]; then
    printf "  ${DIM}%s${RESET}" "$detail"
  fi
  printf "\n"
}

ui_row() {
  local left="$1" right="${2:-}"
  printf "  ${WHITE}%-28s${RESET}" "$left"
  if [[ -n "$right" ]]; then
    printf "  ${CYAN}%s${RESET}" "$right"
  fi
  printf "\n"
}

ui_kv() {
  local key="$1" val="$2"
  printf "  ${DIM}%-22s${RESET} ${WHITE}%s${RESET}\n" "$key" "$val"
}

ui_success() {
  printf "  ${GREEN}✓${RESET} %s\n" "$1"
}

ui_warn() {
  printf "  ${ORANGE}!${RESET} %s\n" "$1"
}

ui_error() {
  printf "  ${RED}✗${RESET} %s\n" "$1"
}

ui_info() {
  printf "  ${CYAN}·${RESET} %s\n" "$1"
}

ui_dim() {
  printf "  ${DIM}%s${RESET}\n" "$1"
}

# Progress bar: ui_bar PERCENT [WIDTH]
ui_bar() {
  local pct="$1"
  local width="${2:-28}"
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  local color="$TEAL"
  (( pct >= 85 )) && color="$ORANGE"
  (( pct >= 95 )) && color="$RED"

  printf "${color}"
  printf "%*s" "$filled" "" | tr ' ' '█'
  printf "${DARK}"
  printf "%*s" "$empty" "" | tr ' ' '░'
  printf "${RESET}"
}

# Disk usage bar with labels
ui_disk_meter() {
  local used total free pct
  used=$(disk_used)
  total=$(disk_total)
  free=$(disk_free)
  if [[ "$total" -gt 0 ]]; then
    pct=$(( used * 100 / total ))
  else
    pct=0
  fi

  printf "  ${DIM}Disk${RESET}  "
  ui_bar "$pct" 32
  printf "  ${WHITE}%s%%${RESET}  ${DIM}%s free of %s${RESET}\n" \
    "$pct" "$(bytes_human "$free")" "$(bytes_human "$total")"
}

# Summary box after clean
ui_summary() {
  local freed="$1"
  local free_now="$2"
  local mode="${3:-clean}"

  printf "\n"
  ui_divider "═"
  if [[ "$mode" == "dry" ]]; then
    printf "  ${GOLD}${BOLD}Would free${RESET}  ${WHITE}%s${RESET}  ${DIM}(dry run — nothing deleted)${RESET}\n" \
      "$(bytes_human "$freed")"
  else
    printf "  ${GREEN}${BOLD}Space freed${RESET}  ${WHITE}%s${RESET}   ${DIM}│${RESET}   ${CYAN}Free now${RESET}  ${WHITE}%s${RESET}\n" \
      "$(bytes_human "$freed")" "$(bytes_human "$free_now")"
  fi
  ui_divider "═"
  printf "\n"
}

# Interactive menu
ui_menu() {
  local choice
  ui_banner
  ui_disk_meter
  printf "\n"
  printf "  ${BOLD}${WHITE}What would you like to do?${RESET}\n\n"
  printf "  ${CYAN}1${RESET}  ${WHITE}Scan${RESET}      ${DIM}Find reclaimable junk (safe preview)${RESET}\n"
  printf "  ${CYAN}2${RESET}  ${WHITE}Clean${RESET}     ${DIM}Deep clean caches, logs & trash${RESET}\n"
  printf "  ${CYAN}3${RESET}  ${WHITE}Analyze${RESET}   ${DIM}See what's eating your disk${RESET}\n"
  printf "  ${CYAN}4${RESET}  ${WHITE}Status${RESET}    ${DIM}Live system health snapshot${RESET}\n"
  printf "  ${CYAN}5${RESET}  ${WHITE}Dry run${RESET}   ${DIM}Simulate a full clean${RESET}\n"
  printf "  ${CYAN}q${RESET}  ${WHITE}Quit${RESET}\n"
  printf "\n"
  printf "  ${DIM}Select${RESET} ${CYAN}›${RESET} "
  read -r choice || true
  echo "$choice"
}

ui_help() {
  cat << EOF

  ${CYAN}${BOLD}Lustr${RESET} ${DIM}v${LUSTR_VERSION}${RESET}  —  polish your Mac from the terminal

  ${BOLD}Usage${RESET}
    lustr [command] [options]

  ${BOLD}Commands${RESET}
    ${CYAN}scan${RESET}                 Scan for junk and report reclaimable space
    ${CYAN}clean${RESET}                Deep clean safe junk (asks before deleting)
    ${CYAN}analyze${RESET}              Disk usage breakdown of key locations
    ${CYAN}status${RESET}               System health snapshot
    ${CYAN}update${RESET}               Update Lustr to the latest version
    ${CYAN}uninstall${RESET}            Remove Lustr from this Mac
    ${CYAN}help${RESET}                 Show this help
    ${CYAN}version${RESET}              Print version

  ${BOLD}Options${RESET}
    ${CYAN}--dry-run${RESET}, ${CYAN}-n${RESET}        Preview only — never delete
    ${CYAN}--yes${RESET}, ${CYAN}-y${RESET}            Skip confirmation prompts
    ${CYAN}--quiet${RESET}, ${CYAN}-q${RESET}          Minimal output
    ${CYAN}--no-color${RESET}           Disable ANSI colors

  ${BOLD}Examples${RESET}
    ${DIM}lustr${RESET}                Interactive menu
    ${DIM}lustr scan${RESET}           Safe preview of junk
    ${DIM}lustr clean --dry-run${RESET}
    ${DIM}lustr clean -y${RESET}       Clean without prompts

  ${BOLD}Safety${RESET}
    Lustr only touches known junk: caches, logs, temp files, and Trash.
    Documents, Photos, Mail, Messages, Keychains, and apps stay untouched.

  ${DIM}https://github.com/TheWarrior-tech/Lustr${RESET}

EOF
}

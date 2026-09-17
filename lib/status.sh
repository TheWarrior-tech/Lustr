#!/usr/bin/env bash
# Lustr — system status snapshot
# shellcheck disable=SC1091

lustr_status() {
  ui_section "System status"

  local model chip mem macos host uptime_str
  host=$(scutil --get ComputerName 2>/dev/null || hostname)
  model=$(sysctl -n hw.model 2>/dev/null || echo "Mac")
  macos=$(sw_vers -productVersion 2>/dev/null || echo "?")
  chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "")
  # Apple Silicon friendly
  # Prefer fast sysctl; only fall back to a lightweight uname hint
  if [[ -z "$chip" ]]; then
    chip=$(uname -m 2>/dev/null || echo "")
  fi
  mem=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
  uptime_str=$(uptime | sed 's/.*up //' | sed 's/, [0-9]* user.*//' | xargs)

  printf "  ${BOLD}${WHITE}%s${RESET}  ${DIM}·${RESET}  ${CYAN}%s${RESET}\n" "$host" "macOS $macos"
  printf "  ${DIM}%s${RESET}" "$model"
  [[ -n "$chip" ]] && printf "  ${DIM}·${RESET}  ${DIM}%s${RESET}" "$chip"
  printf "  ${DIM}·${RESET}  ${DIM}%s RAM${RESET}\n" "$(bytes_human "$mem")"
  printf "  ${DIM}Up %s${RESET}\n\n" "$uptime_str"

  # Memory pressure
  local pages_free pages_active pages_inactive pages_wired page_size
  page_size=$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)
  pages_free=$(vm_stat 2>/dev/null | awk '/Pages free/ {gsub(/\./,"",$3); print $3}')
  pages_active=$(vm_stat 2>/dev/null | awk '/Pages active/ {gsub(/\./,"",$3); print $3}')
  pages_inactive=$(vm_stat 2>/dev/null | awk '/Pages inactive/ {gsub(/\./,"",$3); print $3}')
  pages_wired=$(vm_stat 2>/dev/null | awk '/Pages wired/ {gsub(/\./,"",$4); print $4}')
  pages_free=${pages_free:-0}
  pages_active=${pages_active:-0}
  pages_inactive=${pages_inactive:-0}
  pages_wired=${pages_wired:-0}

  local mem_used=$(( (pages_active + pages_wired + pages_inactive) * page_size ))
  local mem_free=$(( pages_free * page_size ))
  local mem_pct=0
  if [[ "$mem" -gt 0 ]]; then
    mem_pct=$(( mem_used * 100 / mem ))
    (( mem_pct > 100 )) && mem_pct=100
  fi

  printf "  ${DIM}Memory${RESET}  "
  ui_bar "$mem_pct" 32
  printf "  ${WHITE}%s%%${RESET}  ${DIM}%s used${RESET}\n" "$mem_pct" "$(bytes_human "$mem_used")"

  ui_disk_meter

  # Load average
  local load
  load=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2, $3, $4}')
  printf "  ${DIM}Load${RESET}    ${WHITE}%s${RESET}  ${DIM}(1 / 5 / 15 min)${RESET}\n" "$load"

  # Battery if present
  local batt batt_pct charge_status
  batt=$(pmset -g batt 2>/dev/null | awk -F'[;\t]' 'NR==2 {gsub(/^ +| +$/,"",$1); print $1}')
  if [[ -n "$batt" && "$batt" != *"InternalBattery"* && "$batt" != *"Now drawing"* ]]; then
    # Prefer percentage field from pmset line like: " -InternalBattery-0 (id=...) 82%; charging; ..."
    batt_pct=$(pmset -g batt 2>/dev/null | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
    charge_status=$(pmset -g batt 2>/dev/null | awk -F';' 'NR==2 {
      for (i=1;i<=NF;i++) if ($i ~ /charg|discharg|charged|AC/ ) { gsub(/^ +| +$/,"",$i); print $i; exit }
    }')
    if [[ -n "$batt_pct" ]]; then
      printf "  ${DIM}Battery${RESET} "
      ui_bar "$batt_pct" 32
      printf "  ${WHITE}%s%%${RESET}  ${DIM}%s${RESET}\n" "$batt_pct" "${charge_status:-}"
    fi
  fi

  # Top CPU processes (brief)
  local content_w proc_w
  content_w=$(ui_content_width)
  proc_w=$(( content_w - 24 ))
  (( proc_w < 18 )) && proc_w=18
  (( proc_w > 42 )) && proc_w=42
  printf "\n  ${VIOLET}${BOLD}Top processes${RESET}\n"
  ui_divider "·"
  while read -r cpu rss comm; do
    rss_b=$(( rss * 1024 ))
    base=$(basename "$comm" 2>/dev/null || echo "$comm")
    printf "  ${WHITE}%-*s${RESET}  ${CYAN}%5s%%${RESET}  ${DIM}%s${RESET}\n" \
      "$proc_w" "$(ui_truncate "$base" "$proc_w")" "$cpu" "$(bytes_human "$rss_b")"
  done < <(ps -Aro %cpu,rss,comm 2>/dev/null | head -6 | tail -5)

  printf "\n"
  ui_dim "Run  lustr scan  to find reclaimable junk."
  printf "\n"
}

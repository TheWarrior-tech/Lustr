#!/usr/bin/env bash
# Lustr — shared utilities
# shellcheck disable=SC2034

set -euo pipefail

LUSTR_VERSION="1.0.0"
LUSTR_NAME="Lustr"
LUSTR_HOME="${LUSTR_HOME:-$HOME/.lustr}"
LUSTR_LOG_DIR="${LUSTR_HOME}/logs"
LUSTR_CONFIG="${LUSTR_HOME}/config"
LUSTR_LOG="${LUSTR_LOG_DIR}/operations.log"

# ── Colors (premium palette) ──────────────────────────────────────────
if [[ -t 1 ]] && [[ "${NO_COLOR:-}" != "1" ]]; then
  RESET='\033[0m'
  BOLD='\033[1m'
  DIM='\033[2m'
  ITALIC='\033[3m'
  UNDERLINE='\033[4m'

  # Soft premium palette
  CYAN='\033[38;5;81m'
  TEAL='\033[38;5;44m'
  VIOLET='\033[38;5;141m'
  LAVENDER='\033[38;5;183m'
  GOLD='\033[38;5;221m'
  ROSE='\033[38;5;211m'
  GREEN='\033[38;5;114m'
  RED='\033[38;5;203m'
  ORANGE='\033[38;5;215m'
  WHITE='\033[38;5;255m'
  GRAY='\033[38;5;245m'
  DARK='\033[38;5;238m'
else
  RESET='' BOLD='' DIM='' ITALIC='' UNDERLINE=''
  CYAN='' TEAL='' VIOLET='' LAVENDER='' GOLD='' ROSE=''
  GREEN='' RED='' ORANGE='' WHITE='' GRAY='' DARK=''
fi

# ── Terminal helpers ──────────────────────────────────────────────────
term_cols() {
  local c
  c=$(tput cols 2>/dev/null || echo 80)
  [[ "$c" -lt 40 ]] && c=40
  echo "$c"
}

hide_cursor() { printf '\033[?25l' 2>/dev/null || true; }
show_cursor() { printf '\033[?25h' 2>/dev/null || true; }
clear_line()  { printf '\r\033[K'; }

# ── Size formatting ───────────────────────────────────────────────────
# Bytes → human readable (B, KB, MB, GB, TB)
bytes_human() {
  local bytes="${1:-0}"
  # Strip non-digits
  bytes=$(echo "$bytes" | tr -cd '0-9')
  [[ -z "$bytes" || "$bytes" -eq 0 ]] && { echo "0 B"; return; }

  local units=("B" "KB" "MB" "GB" "TB")
  local unit=0
  local whole="$bytes"
  local frac=0

  while (( whole >= 1024 && unit < 4 )); do
    frac=$(( (whole % 1024) * 10 / 1024 ))
    whole=$(( whole / 1024 ))
    ((unit++))
  done

  if (( unit == 0 )); then
    echo "${whole} B"
  else
    echo "${whole}.${frac} ${units[$unit]}"
  fi
}

# Get directory size in bytes (fast, best-effort)
dir_size() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo 0
    return
  fi
  # du -sk returns KB; convert to bytes
  local kb
  kb=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
  [[ -z "$kb" ]] && kb=0
  echo $(( kb * 1024 ))
}

# Sum of sizes for multiple paths
paths_size() {
  local total=0 size
  for p in "$@"; do
    [[ -e "$p" ]] || continue
    size=$(dir_size "$p")
    total=$(( total + size ))
  done
  echo "$total"
}

# Disk stats for the data volume (APFS-aware). Prefer the volume that
# holds $HOME so we report user-relevant free space, not the sealed system slice.
_disk_df_line() {
  # Prefer home volume; fall back to /
  df -k "$HOME" 2>/dev/null | awk 'NR==2 {print; exit}'
  # if home failed somehow
  df -k / 2>/dev/null | awk 'NR==2 {print; exit}'
}

# Free (available) bytes
disk_free() {
  df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $4 * 1024; exit}'
}

# Total capacity bytes
disk_total() {
  df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $2 * 1024; exit}'
}

# Used bytes — derive from total - available for APFS accuracy
disk_used() {
  df -k "$HOME" 2>/dev/null | awk 'NR==2 {
    total=$2*1024; avail=$4*1024;
    used=total-avail; if (used<0) used=0; print used; exit
  }'
}

# ── Logging ───────────────────────────────────────────────────────────
ensure_dirs() {
  mkdir -p "$LUSTR_LOG_DIR" "$LUSTR_CONFIG" 2>/dev/null || true
}

log_op() {
  ensure_dirs
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $*" >> "$LUSTR_LOG" 2>/dev/null || true
}

# ── Confirmation ──────────────────────────────────────────────────────
confirm() {
  local prompt="${1:-Continue?}"
  local default="${2:-n}"
  local reply
  if [[ "$default" == "y" ]]; then
    printf "${CYAN}?${RESET} %s ${DIM}[Y/n]${RESET} " "$prompt"
  else
    printf "${CYAN}?${RESET} %s ${DIM}[y/N]${RESET} " "$prompt"
  fi
  read -r reply || true
  reply=$(echo "${reply:-$default}" | tr '[:upper:]' '[:lower:]')
  [[ "$reply" == "y" || "$reply" == "yes" ]]
}

# ── Require macOS ─────────────────────────────────────────────────────
require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    printf "${RED}✗${RESET} Lustr is designed for macOS only.\n"
    exit 1
  fi
}

# ── Spinner ───────────────────────────────────────────────────────────
_SPINNER_PID=""

start_spinner() {
  local msg="${1:-Working...}"
  if [[ ! -t 1 ]]; then
    printf "  %s\n" "$msg"
    return
  fi
  hide_cursor
  (
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while true; do
      printf "\r  ${CYAN}%s${RESET} ${DIM}%s${RESET}" "${frames[$i]}" "$msg"
      i=$(( (i + 1) % ${#frames[@]} ))
      sleep 0.08
    done
  ) &
  _SPINNER_PID=$!
  disown "$_SPINNER_PID" 2>/dev/null || true
}

stop_spinner() {
  if [[ -n "${_SPINNER_PID:-}" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null || true
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
    clear_line
  fi
  show_cursor
}

# Cleanup spinner on exit
trap 'stop_spinner; show_cursor' EXIT INT TERM

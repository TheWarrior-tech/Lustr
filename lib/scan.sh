#!/usr/bin/env bash
# Lustr — scan for reclaimable junk
# shellcheck disable=SC1091

# Global scan results: name|bytes|path_or_tag|category
declare -a SCAN_RESULTS=()
SCAN_TOTAL=0

_scan_add() {
  local name="$1" bytes="$2" tag="$3" category="${4:-General}"
  bytes=$(echo "$bytes" | tr -cd '0-9')
  [[ -z "$bytes" ]] && bytes=0
  if (( bytes == 0 )); then
    return 0
  fi
  SCAN_RESULTS+=("${name}|${bytes}|${tag}|${category}")
  SCAN_TOTAL=$(( SCAN_TOTAL + bytes ))
  return 0
}

_scan_size_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    dir_size "$path"
  else
    echo 0
  fi
}

# Scan user Library/Caches (aggregate + top offenders)
_scan_user_caches() {
  local base="$HOME/Library/Caches"
  [[ -d "$base" ]] || return 0

  local total
  total=$(_scan_size_if_exists "$base")
  _scan_add "User app caches" "$total" "user_caches" "Caches"
}

_scan_user_logs() {
  local base="$HOME/Library/Logs"
  [[ -d "$base" ]] || return 0
  local total
  total=$(_scan_size_if_exists "$base")
  _scan_add "User logs" "$total" "user_logs" "Logs"
}

_scan_trash() {
  local base="$HOME/.Trash"
  [[ -d "$base" ]] || return 0
  local total
  total=$(_scan_size_if_exists "$base")
  _scan_add "Trash" "$total" "trash" "Trash"
}

_scan_xcode() {
  local d size
  d="$HOME/Library/Developer/Xcode/DerivedData"
  size=$(_scan_size_if_exists "$d")
  _scan_add "Xcode DerivedData" "$size" "xcode_derived" "Developer"

  d="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
  size=$(_scan_size_if_exists "$d")
  _scan_add "Xcode iOS DeviceSupport" "$size" "xcode_ios_support" "Developer"

  d="$HOME/Library/Developer/CoreSimulator/Caches"
  size=$(_scan_size_if_exists "$d")
  _scan_add "iOS Simulator caches" "$size" "sim_caches" "Developer"

  d="$HOME/Library/Developer/Xcode/Archives"
  size=$(_scan_size_if_exists "$d")
  # Archives can be intentional — report but mark optional
  _scan_add "Xcode Archives (optional)" "$size" "xcode_archives" "Developer"
}

_scan_package_managers() {
  local d size

  # Prefer known cache paths — avoid spawning `brew` (slow cold start)
  d="$HOME/Library/Caches/Homebrew"
  size=$(_scan_size_if_exists "$d")
  if (( size == 0 )); then
    d="$HOME/Library/Caches/Homebrew/downloads"
    size=$(_scan_size_if_exists "$HOME/Library/Caches/Homebrew")
  fi
  _scan_add "Homebrew cache" "$size" "homebrew" "Dev Tools"

  d="$HOME/.npm/_cacache"
  size=$(_scan_size_if_exists "$d")
  _scan_add "npm cache" "$size" "npm" "Dev Tools"

  d="$HOME/.yarn/cache"
  [[ ! -d "$d" ]] && d="$HOME/.cache/yarn"
  size=$(_scan_size_if_exists "$d")
  _scan_add "Yarn cache" "$size" "yarn" "Dev Tools"

  d="$HOME/.pnpm-store"
  size=$(_scan_size_if_exists "$d")
  if (( size == 0 )); then
    d="$HOME/Library/pnpm/store"
    size=$(_scan_size_if_exists "$d")
  fi
  _scan_add "pnpm store (cache)" "$size" "pnpm" "Dev Tools"

  d="$HOME/.cache/pip"
  size=$(_scan_size_if_exists "$d")
  if (( size == 0 )); then
    d="$HOME/Library/Caches/pip"
    size=$(_scan_size_if_exists "$d")
  fi
  _scan_add "pip cache" "$size" "pip" "Dev Tools"

  d="$HOME/.cargo/registry/cache"
  size=$(_scan_size_if_exists "$d")
  _scan_add "Cargo registry cache" "$size" "cargo" "Dev Tools"

  d="$HOME/.gradle/caches"
  size=$(_scan_size_if_exists "$d")
  _scan_add "Gradle caches" "$size" "gradle" "Dev Tools"

  d="$HOME/Library/Caches/CocoaPods"
  size=$(_scan_size_if_exists "$d")
  _scan_add "CocoaPods cache" "$size" "cocoapods" "Dev Tools"
}

_scan_browsers() {
  local d size total=0

  for d in \
    "$HOME/Library/Caches/Google/Chrome" \
    "$HOME/Library/Caches/Google/Chrome Canary" \
    "$HOME/Library/Caches/com.apple.Safari" \
    "$HOME/Library/Caches/Firefox" \
    "$HOME/Library/Caches/BraveSoftware" \
    "$HOME/Library/Caches/company.thebrowser.Browser" \
    "$HOME/Library/Caches/com.operasoftware.Opera"
  do
    size=$(_scan_size_if_exists "$d")
    total=$(( total + size ))
  done
  _scan_add "Browser caches" "$total" "browsers" "Browsers"
}

_scan_system_temp() {
  # Only estimate user-owned temp under /private/var/folders — careful
  local size=0
  # User temp dir
  if [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]]; then
    size=$(_scan_size_if_exists "$TMPDIR")
  fi
  _scan_add "Temporary files" "$size" "temp" "System"
}

_scan_misc() {
  local d size

  d="$HOME/Library/Saved Application State"
  size=$(_scan_size_if_exists "$d")
  _scan_add "Saved application state" "$size" "saved_state" "System"

  d="$HOME/Library/Logs/DiagnosticReports"
  size=$(_scan_size_if_exists "$d")
  _scan_add "Diagnostic reports" "$size" "diagnostics" "Logs"

  # .DS_Store: shallow scan only (depth-limited for speed)
  local ds_count=0
  local root
  for root in "$HOME/Desktop" "$HOME/Downloads"; do
    [[ -d "$root" ]] || continue
    ds_count=$(( ds_count + $(find "$root" -maxdepth 4 -name '.DS_Store' -type f 2>/dev/null | wc -l | tr -d ' ') ))
  done
  size=$(( ds_count * 6144 ))
  (( size > 0 )) && _scan_add ".DS_Store files (~${ds_count})" "$size" "ds_store" "System"
}

# Main scan entry
lustr_scan() {
  local quiet="${1:-0}"
  SCAN_RESULTS=()
  SCAN_TOTAL=0

  safety_init_allowlist

  if [[ "$quiet" != "1" ]]; then
    start_spinner "Scanning your Mac for reclaimable junk..."
  fi

  _scan_user_caches
  _scan_user_logs
  _scan_trash
  _scan_xcode
  _scan_package_managers
  _scan_browsers
  _scan_system_temp
  _scan_misc

  if [[ "$quiet" != "1" ]]; then
    stop_spinner
  fi
}

# Print scan results as a table
lustr_scan_print() {
  local dry="${1:-0}"
  local status="scan"
  [[ "$dry" == "1" ]] && status="dry"

  ui_section "Reclaimable space"

  if (( ${#SCAN_RESULTS[@]} == 0 )); then
    ui_success "Nothing significant found — your Mac looks tidy."
    return 0
  fi

  # Sort by size descending
  local sorted
  sorted=$(printf '%s\n' "${SCAN_RESULTS[@]}" | sort -t'|' -k2 -nr)

  local line name bytes tag cat
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    name=$(echo "$line" | cut -d'|' -f1)
    bytes=$(echo "$line" | cut -d'|' -f2)
    cat=$(echo "$line" | cut -d'|' -f4)
    ui_item "$status" "$name" "$(bytes_human "$bytes")" "$cat"
  done <<< "$sorted"

  printf "\n"
  ui_divider
  printf "  ${BOLD}Total reclaimable${RESET}                  ${CYAN}${BOLD}%10s${RESET}\n" \
    "$(bytes_human "$SCAN_TOTAL")"
  ui_divider
  printf "\n"
  ui_dim "Only safe junk is listed. Documents, apps, and personal data are never touched."
}

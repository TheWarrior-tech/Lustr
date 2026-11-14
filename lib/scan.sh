#!/usr/bin/env bash
# Lustr — scan for reclaimable junk (deeper coverage)
# shellcheck disable=SC1091

declare -a SCAN_RESULTS=()
SCAN_TOTAL=0

_scan_add() {
  local name="$1" bytes="$2" tag="$3" category="${4:-General}"
  bytes=$(echo "$bytes" | tr -cd '0-9')
  [[ -z "$bytes" ]] && bytes=0
  if (( bytes == 0 )); then return 0; fi
  SCAN_RESULTS+=("${name}|${bytes}|${tag}|${category}")
  SCAN_TOTAL=$(( SCAN_TOTAL + bytes ))
}

_scan_size_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then dir_size "$path"; else echo 0; fi
}

_scan_user_caches() {
  local base="$HOME/Library/Caches"
  [[ -d "$base" ]] || return 0
  _scan_add "User app caches" "$(_scan_size_if_exists "$base")" "user_caches" "Caches"
}

_scan_user_logs() {
  local base="$HOME/Library/Logs"
  [[ -d "$base" ]] || return 0
  _scan_add "User logs" "$(_scan_size_if_exists "$base")" "user_logs" "Logs"
}

_scan_trash() {
  local base="$HOME/.Trash"
  [[ -d "$base" ]] || return 0
  _scan_add "Trash" "$(_scan_size_if_exists "$base")" "trash" "Trash"
}

_scan_xcode() {
  local d size
  d="$HOME/Library/Developer/Xcode/DerivedData"; size=$(_scan_size_if_exists "$d")
  _scan_add "Xcode DerivedData" "$size" "xcode_derived" "Developer"
  d="$HOME/Library/Developer/Xcode/iOS DeviceSupport"; size=$(_scan_size_if_exists "$d")
  _scan_add "Xcode iOS DeviceSupport" "$size" "xcode_ios_support" "Developer"
  d="$HOME/Library/Developer/Xcode/watchOS DeviceSupport"; size=$(_scan_size_if_exists "$d")
  _scan_add "Xcode watchOS DeviceSupport" "$size" "xcode_watch_support" "Developer"
  d="$HOME/Library/Developer/CoreSimulator/Caches"; size=$(_scan_size_if_exists "$d")
  _scan_add "iOS Simulator caches" "$size" "sim_caches" "Developer"
  d="$HOME/Library/Developer/Xcode/Archives"; size=$(_scan_size_if_exists "$d")
  _scan_add "Xcode Archives (optional)" "$size" "xcode_archives" "Developer"
  d="$HOME/Library/Caches/org.swift.swiftpm"; size=$(_scan_size_if_exists "$d")
  _scan_add "SwiftPM cache" "$size" "swiftpm" "Developer"
  d="$HOME/Library/Caches/com.apple.dt.Xcode"; size=$(_scan_size_if_exists "$d")
  _scan_add "Xcode app cache" "$size" "xcode_app_cache" "Developer"
}

_scan_package_managers() {
  local d size
  d="$HOME/Library/Caches/Homebrew"; size=$(_scan_size_if_exists "$d")
  _scan_add "Homebrew cache" "$size" "homebrew" "Dev Tools"
  d="$HOME/.npm/_cacache"; size=$(_scan_size_if_exists "$d")
  _scan_add "npm cache" "$size" "npm" "Dev Tools"
  d="$HOME/.yarn/cache"; [[ ! -d "$d" ]] && d="$HOME/.cache/yarn"
  size=$(_scan_size_if_exists "$d"); _scan_add "Yarn cache" "$size" "yarn" "Dev Tools"
  d="$HOME/.pnpm-store"; size=$(_scan_size_if_exists "$d")
  if (( size == 0 )); then d="$HOME/Library/pnpm/store"; size=$(_scan_size_if_exists "$d"); fi
  _scan_add "pnpm store" "$size" "pnpm" "Dev Tools"
  d="$HOME/.cache/pip"; size=$(_scan_size_if_exists "$d")
  if (( size == 0 )); then d="$HOME/Library/Caches/pip"; size=$(_scan_size_if_exists "$d"); fi
  _scan_add "pip cache" "$size" "pip" "Dev Tools"
  d="$HOME/.cache/uv"; size=$(_scan_size_if_exists "$d")
  _scan_add "uv cache" "$size" "uv" "Dev Tools"
  d="$HOME/.cargo/registry/cache"; size=$(_scan_size_if_exists "$d")
  _scan_add "Cargo registry cache" "$size" "cargo" "Dev Tools"
  d="$HOME/.gradle/caches"; size=$(_scan_size_if_exists "$d")
  _scan_add "Gradle caches" "$size" "gradle" "Dev Tools"
  d="$HOME/Library/Caches/CocoaPods"; size=$(_scan_size_if_exists "$d")
  _scan_add "CocoaPods cache" "$size" "cocoapods" "Dev Tools"
  d="$HOME/.bun/install/cache"; size=$(_scan_size_if_exists "$d")
  _scan_add "Bun install cache" "$size" "bun" "Dev Tools"
  d="$HOME/Library/Caches/go-build"; size=$(_scan_size_if_exists "$d")
  _scan_add "Go build cache" "$size" "go" "Dev Tools"
}

_scan_browsers() {
  local d size total=0
  for d in "$HOME/Library/Caches/Google/Chrome" "$HOME/Library/Caches/Google/Chrome Canary" \
    "$HOME/Library/Caches/com.apple.Safari" "$HOME/Library/Caches/Firefox" \
    "$HOME/Library/Caches/BraveSoftware" "$HOME/Library/Caches/company.thebrowser.Browser" \
    "$HOME/Library/Caches/com.operasoftware.Opera" "$HOME/Library/Caches/Microsoft Edge"; do
    size=$(_scan_size_if_exists "$d"); total=$(( total + size ))
  done
  _scan_add "Browser caches" "$total" "browsers" "Browsers"
}

_scan_apps() {
  local d size total=0
  for d in "$HOME/Library/Caches/com.spotify.client" "$HOME/Library/Caches/com.tinyspeck.slackmacgap" \
    "$HOME/Library/Caches/com.hnc.Discord" "$HOME/Library/Caches/us.zoom.xos" \
    "$HOME/Library/Caches/com.microsoft.VSCode" "$HOME/Library/Caches/JetBrains" \
    "$HOME/Library/Caches/com.jetbrains"; do
    size=$(_scan_size_if_exists "$d"); total=$(( total + size ))
  done
  _scan_add "App caches (Spotify/Slack/Discord/Zoom/VSCode/JetBrains)" "$total" "app_caches" "Apps"
}

_scan_system_temp() {
  local size=0
  if [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]]; then size=$(_scan_size_if_exists "$TMPDIR"); fi
  _scan_add "Temporary files" "$size" "temp" "System"
}

_scan_misc() {
  local d size
  d="$HOME/Library/Saved Application State"; size=$(_scan_size_if_exists "$d")
  _scan_add "Saved application state" "$size" "saved_state" "System"
  d="$HOME/Library/Logs/DiagnosticReports"; size=$(_scan_size_if_exists "$d")
  _scan_add "Diagnostic reports" "$size" "diagnostics" "Logs"
  d="$HOME/Library/HTTPStorages"; size=$(_scan_size_if_exists "$d")
  _scan_add "HTTP storages" "$size" "http_storages" "Caches"
  d="$HOME/Library/WebKit"; size=$(_scan_size_if_exists "$d")
  _scan_add "WebKit data" "$size" "webkit" "Caches"
  local ds_count=0 root
  for root in "$HOME/Desktop" "$HOME/Downloads" "$HOME/Documents"; do
    [[ -d "$root" ]] || continue
    ds_count=$(( ds_count + $(find "$root" -maxdepth 3 -name '.DS_Store' -type f 2>/dev/null | wc -l | tr -d ' ') ))
  done
  size=$(( ds_count * 6144 ))
  (( size > 0 )) && _scan_add ".DS_Store files (~${ds_count})" "$size" "ds_store" "System"
}

_scan_docker() {
  command -v docker &>/dev/null || return 0
  local d="$HOME/Library/Containers/com.docker.docker/Data" size=0
  [[ -d "$d" ]] && size=$(_scan_size_if_exists "$d")
  (( size > 0 )) && _scan_add "Docker data (use docker system prune)" "$size" "docker" "Dev Tools"
}

lustr_scan() {
  local quiet="${1:-0}"
  SCAN_RESULTS=(); SCAN_TOTAL=0
  safety_init_allowlist
  [[ "$quiet" != "1" ]] && start_spinner "Scanning your Mac for reclaimable junk..."
  _scan_user_caches; _scan_user_logs; _scan_trash; _scan_xcode
  _scan_package_managers; _scan_browsers; _scan_apps; _scan_system_temp; _scan_misc; _scan_docker
  [[ "$quiet" != "1" ]] && stop_spinner
}

lustr_scan_print() {
  local dry="${1:-0}" status="scan"
  [[ "$dry" == "1" ]] && status="dry"
  ui_section "Reclaimable space"
  if (( ${#SCAN_RESULTS[@]} == 0 )); then
    ui_success "Nothing significant found — your Mac looks tidy."
    return 0
  fi
  local sorted line name bytes cat
  sorted=$(printf '%s\n' "${SCAN_RESULTS[@]}" | sort -t'|' -k2 -nr)
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    name=$(echo "$line" | cut -d'|' -f1)
    bytes=$(echo "$line" | cut -d'|' -f2)
    cat=$(echo "$line" | cut -d'|' -f4)
    ui_item "$status" "$name" "$(bytes_human "$bytes")" "$cat"
  done <<< "$sorted"
  printf "\n"; ui_divider
  printf "  ${BOLD}%-24s${RESET}  ${CYAN}${BOLD}%10s${RESET}\n" "Total reclaimable" "$(bytes_human "$SCAN_TOTAL")"
  ui_divider; printf "\n"
  ui_dim "Only safe junk is listed. Documents, apps, and personal data are never touched."
}

#!/usr/bin/env bash
# Lustr — safe cleaning operations (deeper coverage)
# shellcheck disable=SC1091

CLEAN_FREED=0

_clean_report() {
  local status="$1" label="$2" bytes="$3"
  CLEAN_FREED=$(( CLEAN_FREED + bytes ))
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
    ui_item "dry" "$label" "$(bytes_human "$bytes")"
  else
    ui_item "done" "$label" "$(bytes_human "$bytes")"
  fi
}

_clean_path_contents() {
  local label="$1" path="$2"
  [[ -e "$path" ]] || return 0
  if ! safety_is_path_safe "$path"; then
    ui_item "skip" "$label" "" "protected"; return 0
  fi
  local before dry_flag=""
  before=$(dir_size "$path"); (( before == 0 )) && return 0
  [[ "${LUSTR_DRY_RUN:-0}" == "1" ]] && dry_flag="--dry-run"
  if [[ -d "$path" ]]; then safety_rm_contents "$path" $dry_flag || true
  else safety_rm "$path" $dry_flag || true; fi
  local freed=$SAFETY_LAST_FREED
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" && "$freed" -eq 0 ]]; then freed=$before; fi
  _clean_report "done" "$label" "$freed"
}

_clean_trash() {
  local path="$HOME/.Trash"
  [[ -d "$path" ]] || return 0
  local before; before=$(dir_size "$path"); (( before == 0 )) && return 0
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then _clean_report "dry" "Trash" "$before"; return 0; fi
  if osascript -e 'tell application "Finder" to empty trash' &>/dev/null; then
    _clean_report "done" "Trash" "$before"; log_op "Emptied Trash via Finder ($before bytes)"
  else
    safety_rm_contents "$path" || true; _clean_report "done" "Trash" "$SAFETY_LAST_FREED"
  fi
}

_clean_homebrew() {
  local bc="$HOME/Library/Caches/Homebrew" before=0
  before=$(dir_size "$bc"); (( before == 0 )) && return 0
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then _clean_report "dry" "Homebrew cache" "$before"; return 0; fi
  command -v brew &>/dev/null && brew cleanup -s --prune=all &>/dev/null || true
  if [[ -d "$bc" ]] && safety_is_path_safe "$bc"; then safety_rm_contents "$bc" || true; fi
  local after freed; after=$(dir_size "$bc"); freed=$(( before - after ))
  (( freed < 0 )) && freed=0; (( freed == 0 && before > 0 )) && freed=$before
  (( freed > 0 )) && _clean_report "done" "Homebrew cache" "$freed"
}

_clean_npm() {
  local path="$HOME/.npm/_cacache"
  [[ -d "$path" ]] || return 0
  local before; before=$(dir_size "$path"); (( before == 0 )) && return 0
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then _clean_report "dry" "npm cache" "$before"; return 0; fi
  command -v npm &>/dev/null && npm cache clean --force &>/dev/null || true
  if [[ -d "$path" ]] && safety_is_path_safe "$path"; then safety_rm_contents "$path" || true; fi
  _clean_report "done" "npm cache" "$before"
}

_clean_pip() {
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
    local s; s=$(dir_size "$HOME/.cache/pip"); (( s == 0 )) && s=$(dir_size "$HOME/Library/Caches/pip")
    (( s > 0 )) && _clean_report "dry" "pip cache" "$s"; return 0
  fi
  command -v pip3 &>/dev/null && pip3 cache purge &>/dev/null || true
  command -v pip &>/dev/null && pip cache purge &>/dev/null || true
  _clean_path_contents "pip cache" "$HOME/.cache/pip"
  _clean_path_contents "pip cache (Library)" "$HOME/Library/Caches/pip"
}

_clean_uv() {
  local path="$HOME/.cache/uv"
  [[ -d "$path" ]] || return 0
  local before; before=$(dir_size "$path"); (( before == 0 )) && return 0
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then _clean_report "dry" "uv cache" "$before"; return 0; fi
  command -v uv &>/dev/null && uv cache clean &>/dev/null || true
  _clean_path_contents "uv cache" "$path"
}

_clean_pnpm() {
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
    local s; s=$(dir_size "$HOME/.pnpm-store"); (( s == 0 )) && s=$(dir_size "$HOME/Library/pnpm/store")
    (( s > 0 )) && _clean_report "dry" "pnpm store" "$s"; return 0
  fi
  command -v pnpm &>/dev/null && pnpm store prune &>/dev/null || true
}

_clean_docker() {
  command -v docker &>/dev/null || return 0
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then ui_item "dry" "Docker (system prune)" "via CLI"; return 0; fi
  if docker system prune -f &>/dev/null; then
    ui_item "done" "Docker system prune" "completed"; log_op "Ran docker system prune -f"
  fi
}

_clean_simulators() {
  command -v xcrun &>/dev/null || return 0
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then ui_item "dry" "Unavailable simulators" "via simctl"; return 0; fi
  if xcrun simctl delete unavailable &>/dev/null; then
    ui_item "done" "Unavailable simulators" "cleaned"; log_op "Ran xcrun simctl delete unavailable"
  fi
}

_clean_ds_store() {
  local roots=("$HOME/Desktop" "$HOME/Downloads") count=0 root f
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
    for root in "${roots[@]}"; do
      [[ -d "$root" ]] || continue
      count=$(( count + $(find "$root" -maxdepth 4 -name '.DS_Store' -type f 2>/dev/null | wc -l | tr -d ' ') ))
    done
    local size=$(( count * 6144 )); (( size > 0 )) && _clean_report "dry" ".DS_Store files" "$size"
    return 0
  fi
  for root in "${roots[@]}"; do
    [[ -d "$root" ]] || continue
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      rm -f "$f" 2>/dev/null && count=$(( count + 1 )) || true
    done < <(find "$root" -maxdepth 4 -name '.DS_Store' -type f 2>/dev/null)
  done
  local size=$(( count * 6144 )); (( size > 0 )) && _clean_report "done" ".DS_Store files" "$size"
  log_op "Removed $count .DS_Store files"
}

lustr_clean() {
  local include_archives="${INCLUDE_ARCHIVES:-0}"
  CLEAN_FREED=0
  safety_init_allowlist; ensure_dirs
  local free_before; free_before=$(disk_free)
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then ui_section "Dry run — nothing will be deleted"
  else ui_section "Deep clean"; fi

  _clean_path_contents "User app caches" "$HOME/Library/Caches"
  _clean_path_contents "User logs" "$HOME/Library/Logs"
  _clean_trash
  _clean_path_contents "Saved application state" "$HOME/Library/Saved Application State"
  _clean_path_contents "Diagnostic reports" "$HOME/Library/Logs/DiagnosticReports"

  _clean_path_contents "Xcode DerivedData" "$HOME/Library/Developer/Xcode/DerivedData"
  _clean_path_contents "Xcode iOS DeviceSupport" "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
  _clean_path_contents "Xcode watchOS DeviceSupport" "$HOME/Library/Developer/Xcode/watchOS DeviceSupport"
  _clean_path_contents "Simulator caches" "$HOME/Library/Developer/CoreSimulator/Caches"
  _clean_path_contents "SwiftPM cache" "$HOME/Library/Caches/org.swift.swiftpm"
  _clean_path_contents "Xcode app cache" "$HOME/Library/Caches/com.apple.dt.Xcode"
  _clean_simulators
  [[ "$include_archives" == "1" ]] && _clean_path_contents "Xcode Archives" "$HOME/Library/Developer/Xcode/Archives"

  _clean_homebrew; _clean_npm
  _clean_path_contents "Yarn cache" "$HOME/.yarn/cache"
  _clean_path_contents "Yarn cache (.cache)" "$HOME/.cache/yarn"
  _clean_pnpm; _clean_pip; _clean_uv
  _clean_path_contents "Cargo registry cache" "$HOME/.cargo/registry/cache"
  _clean_path_contents "Gradle caches" "$HOME/.gradle/caches"
  _clean_path_contents "CocoaPods cache" "$HOME/Library/Caches/CocoaPods"
  _clean_path_contents "Bun install cache" "$HOME/.bun/install/cache"
  _clean_path_contents "Go build cache" "$HOME/Library/Caches/go-build"

  _clean_path_contents "Chrome cache" "$HOME/Library/Caches/Google"
  _clean_path_contents "Firefox cache" "$HOME/Library/Caches/Firefox"
  _clean_path_contents "Safari cache" "$HOME/Library/Caches/com.apple.Safari"
  _clean_path_contents "Brave cache" "$HOME/Library/Caches/BraveSoftware"
  _clean_path_contents "Spotify cache" "$HOME/Library/Caches/com.spotify.client"
  _clean_path_contents "Slack cache" "$HOME/Library/Caches/com.tinyspeck.slackmacgap"
  _clean_path_contents "Discord cache" "$HOME/Library/Caches/com.hnc.Discord"
  _clean_path_contents "Zoom cache" "$HOME/Library/Caches/us.zoom.xos"
  _clean_path_contents "VS Code cache" "$HOME/Library/Caches/com.microsoft.VSCode"
  _clean_path_contents "JetBrains caches" "$HOME/Library/Caches/JetBrains"
  _clean_path_contents "HTTP storages" "$HOME/Library/HTTPStorages"
  _clean_path_contents "WebKit data" "$HOME/Library/WebKit"
  _clean_docker

  if [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]]; then
    if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
      local tsize; tsize=$(dir_size "$TMPDIR"); (( tsize > 0 )) && _clean_report "dry" "Temporary files" "$tsize"
    else
      local before after freed; before=$(dir_size "$TMPDIR")
      find "$TMPDIR" -type f -mtime +1 -delete 2>/dev/null || true
      find "$TMPDIR" -type d -empty -delete 2>/dev/null || true
      after=$(dir_size "$TMPDIR"); freed=$(( before - after )); (( freed < 0 )) && freed=0
      (( freed > 0 )) && _clean_report "done" "Temporary files" "$freed"
      log_op "Cleaned TMPDIR older files ($freed bytes)"
    fi
  fi
  _clean_ds_store

  local free_after mode="clean"; free_after=$(disk_free)
  [[ "${LUSTR_DRY_RUN:-0}" == "1" ]] && mode="dry"
  local reported=$CLEAN_FREED
  if [[ "$mode" != "dry" ]]; then
    local delta=$(( free_after - free_before )); (( delta > reported )) && reported=$delta
  fi
  ui_summary "$reported" "$free_after" "$mode"
  log_op "Clean finished. freed≈$reported dry=${LUSTR_DRY_RUN:-0}"
}

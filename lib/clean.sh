#!/usr/bin/env bash
# Lustr — safe cleaning operations
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
  if [[ ! -e "$path" ]]; then
    return 0
  fi
  if ! safety_is_path_safe "$path"; then
    ui_item "skip" "$label" "" "protected"
    return 0
  fi

  local before dry_flag=""
  before=$(dir_size "$path")
  (( before == 0 )) && return 0

  [[ "${LUSTR_DRY_RUN:-0}" == "1" ]] && dry_flag="--dry-run"

  if [[ -d "$path" ]]; then
    safety_rm_contents "$path" $dry_flag || true
  else
    safety_rm "$path" $dry_flag || true
  fi

  local freed=$SAFETY_LAST_FREED
  # Fallback to before size if dry-run
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" && "$freed" -eq 0 ]]; then
    freed=$before
  fi
  _clean_report "done" "$label" "$freed"
}

_clean_path_remove() {
  local label="$1" path="$2"
  if [[ ! -e "$path" ]]; then
    return 0
  fi
  if ! safety_is_path_safe "$path"; then
    ui_item "skip" "$label" "" "protected"
    return 0
  fi

  local before dry_flag=""
  before=$(dir_size "$path")
  (( before == 0 )) && return 0

  [[ "${LUSTR_DRY_RUN:-0}" == "1" ]] && dry_flag="--dry-run"
  safety_rm "$path" $dry_flag || true

  local freed=$SAFETY_LAST_FREED
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" && "$freed" -eq 0 ]]; then
    freed=$before
  fi
  _clean_report "done" "$label" "$freed"
}

# Empty Trash via Finder (safer) or rm
_clean_trash() {
  local path="$HOME/.Trash"
  if [[ ! -d "$path" ]]; then
    return 0
  fi
  local before
  before=$(dir_size "$path")
  (( before == 0 )) && return 0

  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
    _clean_report "dry" "Trash" "$before"
    return 0
  fi

  # Try osascript empty trash first
  if osascript -e 'tell application "Finder" to empty trash' &>/dev/null; then
    _clean_report "done" "Trash" "$before"
    log_op "Emptied Trash via Finder ($before bytes)"
  else
    safety_rm_contents "$path" || true
    _clean_report "done" "Trash" "$SAFETY_LAST_FREED"
  fi
}

_clean_homebrew() {
  local bc="$HOME/Library/Caches/Homebrew"
  local before=0
  before=$(dir_size "$bc")
  (( before == 0 )) && return 0

  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
    _clean_report "dry" "Homebrew cache" "$before"
    return 0
  fi

  # Prefer brew cleanup when available; always fall back to cache dir wipe
  if command -v brew &>/dev/null; then
    brew cleanup -s --prune=all &>/dev/null || true
  fi
  if [[ -d "$bc" ]] && safety_is_path_safe "$bc"; then
    safety_rm_contents "$bc" || true
  fi
  local after freed
  after=$(dir_size "$bc")
  freed=$(( before - after ))
  (( freed < 0 )) && freed=0
  (( freed == 0 && before > 0 )) && freed=$before
  (( freed > 0 )) && _clean_report "done" "Homebrew cache" "$freed"
}

_clean_npm() {
  local path="$HOME/.npm/_cacache"
  if [[ ! -d "$path" ]]; then
    return 0
  fi
  local before
  before=$(dir_size "$path")
  (( before == 0 )) && return 0

  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
    _clean_report "dry" "npm cache" "$before"
    return 0
  fi

  if command -v npm &>/dev/null; then
    npm cache clean --force &>/dev/null || true
  fi
  if [[ -d "$path" ]] && safety_is_path_safe "$path"; then
    safety_rm_contents "$path" || true
  fi
  _clean_report "done" "npm cache" "$before"
}

_clean_pip() {
  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
    local s
    s=$(dir_size "$HOME/.cache/pip")
    (( s == 0 )) && s=$(dir_size "$HOME/Library/Caches/pip")
    (( s > 0 )) && _clean_report "dry" "pip cache" "$s"
    return 0
  fi
  if command -v pip3 &>/dev/null; then
    pip3 cache purge &>/dev/null || true
  elif command -v pip &>/dev/null; then
    pip cache purge &>/dev/null || true
  fi
  _clean_path_contents "pip cache" "$HOME/.cache/pip"
  _clean_path_contents "pip cache (Library)" "$HOME/Library/Caches/pip"
}

_clean_ds_store() {
  # Shallow, high-traffic folders only — avoids cloud/iCloud trees
  local roots=("$HOME/Desktop" "$HOME/Downloads")
  local count=0 root f

  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
    for root in "${roots[@]}"; do
      [[ -d "$root" ]] || continue
      count=$(( count + $(find "$root" -maxdepth 4 -name '.DS_Store' -type f 2>/dev/null | wc -l | tr -d ' ') ))
    done
    local size=$(( count * 6144 ))
    (( size > 0 )) && _clean_report "dry" ".DS_Store files" "$size"
    return 0
  fi

  for root in "${roots[@]}"; do
    [[ -d "$root" ]] || continue
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      rm -f "$f" 2>/dev/null && count=$(( count + 1 )) || true
    done < <(find "$root" -maxdepth 4 -name '.DS_Store' -type f 2>/dev/null)
  done

  local size=$(( count * 6144 ))
  (( size > 0 )) && _clean_report "done" ".DS_Store files" "$size"
  log_op "Removed $count .DS_Store files"
}

# Main clean
# Usage: lustr_clean [--dry-run] [--yes] [--include-archives]
lustr_clean() {
  local include_archives=0
  CLEAN_FREED=0

  safety_init_allowlist
  ensure_dirs

  local free_before
  free_before=$(disk_free)

  if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
    ui_section "Dry run — nothing will be deleted"
  else
    ui_section "Deep clean"
  fi

  # Core safe targets
  _clean_path_contents "User app caches" "$HOME/Library/Caches"
  _clean_path_contents "User logs" "$HOME/Library/Logs"
  _clean_trash
  _clean_path_contents "Saved application state" "$HOME/Library/Saved Application State"
  _clean_path_contents "Diagnostic reports" "$HOME/Library/Logs/DiagnosticReports"

  # Developer
  _clean_path_contents "Xcode DerivedData" "$HOME/Library/Developer/Xcode/DerivedData"
  _clean_path_contents "Xcode iOS DeviceSupport" "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
  _clean_path_contents "Simulator caches" "$HOME/Library/Developer/CoreSimulator/Caches"

  if [[ "$include_archives" == "1" ]]; then
    _clean_path_contents "Xcode Archives" "$HOME/Library/Developer/Xcode/Archives"
  fi

  # Package managers
  _clean_homebrew
  _clean_npm
  _clean_path_contents "Yarn cache" "$HOME/.yarn/cache"
  _clean_path_contents "Yarn cache (.cache)" "$HOME/.cache/yarn"
  _clean_path_contents "pnpm store" "$HOME/.pnpm-store"
  _clean_pip
  _clean_path_contents "Cargo registry cache" "$HOME/.cargo/registry/cache"
  _clean_path_contents "Gradle caches" "$HOME/.gradle/caches"
  _clean_path_contents "CocoaPods cache" "$HOME/Library/Caches/CocoaPods"

  # Browsers (cache dirs only — already under Library/Caches, but explicit)
  _clean_path_contents "Chrome cache" "$HOME/Library/Caches/Google"
  _clean_path_contents "Firefox cache" "$HOME/Library/Caches/Firefox"
  _clean_path_contents "Safari cache" "$HOME/Library/Caches/com.apple.Safari"
  _clean_path_contents "Brave cache" "$HOME/Library/Caches/BraveSoftware"

  # Temp
  if [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]]; then
    # Only clear files older than 1 day in TMPDIR to avoid active app breakage
    if [[ "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
      local tsize
      tsize=$(dir_size "$TMPDIR")
      (( tsize > 0 )) && _clean_report "dry" "Temporary files" "$tsize"
    else
      local before after freed
      before=$(dir_size "$TMPDIR")
      find "$TMPDIR" -type f -mtime +1 -delete 2>/dev/null || true
      find "$TMPDIR" -type d -empty -delete 2>/dev/null || true
      after=$(dir_size "$TMPDIR")
      freed=$(( before - after ))
      (( freed < 0 )) && freed=0
      (( freed > 0 )) && _clean_report "done" "Temporary files" "$freed"
      log_op "Cleaned TMPDIR older files ($freed bytes)"
    fi
  fi

  _clean_ds_store

  # Optional: flush DNS / user font cache (non-destructive, no space)
  if [[ "${LUSTR_DRY_RUN:-0}" != "1" ]]; then
    # Font cache rebuild is optional and can be slow — skip by default
    :
  fi

  local free_after mode="clean"
  free_after=$(disk_free)
  [[ "${LUSTR_DRY_RUN:-0}" == "1" ]] && mode="dry"

  # Prefer measured CLEAN_FREED; fall back to disk delta
  local reported=$CLEAN_FREED
  if [[ "$mode" != "dry" ]]; then
    local delta=$(( free_after - free_before ))
    (( delta > reported )) && reported=$delta
  fi

  ui_summary "$reported" "$free_after" "$mode"
  log_op "Clean finished. freed≈$reported dry=${LUSTR_DRY_RUN:-0}"
}

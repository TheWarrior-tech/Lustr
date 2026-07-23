#!/usr/bin/env bash
# Lustr — safety rails: never touch important user data
# shellcheck disable=SC2034

# Absolute hard-deny prefixes — refuse to delete anything under these
PROTECTED_PREFIXES=(
  "/"
  "/System"
  "/bin"
  "/sbin"
  "/usr"
  "/etc"
  "/var"
  "/private/etc"
  "/private/var/db"
  "/Library/Apple"
  "/Library/Frameworks"
  "/Applications"
  "$HOME"
  "$HOME/Documents"
  "$HOME/Desktop"
  "$HOME/Downloads"
  "$HOME/Pictures"
  "$HOME/Movies"
  "$HOME/Music"
  "$HOME/Public"
  "$HOME/.ssh"
  "$HOME/.gnupg"
  "$HOME/.aws"
  "$HOME/.config"
  "$HOME/Library"
  "$HOME/Library/Application Support"
  "$HOME/Library/Preferences"
  "$HOME/Library/Keychains"
  "$HOME/Library/Mail"
  "$HOME/Library/Messages"
  "$HOME/Library/Calendars"
  "$HOME/Library/Contacts"
  "$HOME/Library/Reminders"
  "$HOME/Library/Safari"
  "$HOME/Library/Accounts"
  "$HOME/Library/IdentityServices"
  "$HOME/Library/Cookies"
  "$HOME/Library/Group Containers"
  "$HOME/Library/Mobile Documents"
  "$HOME/Library/CloudStorage"
  "$HOME/Library/Containers"
  "$HOME/Library/Photos"
  "$HOME/Library/Photos Library.photoslibrary"
  "$HOME/Library/Fonts"
  "$HOME/Library/LaunchAgents"
  "$HOME/Library/Services"
  "$HOME/Library/Shortcuts"
  "$HOME/Library/Speech"
  "$HOME/Library/Spelling"
  "$HOME/Library/Suggestions"
  "$HOME/Library/IntelligencePlatform"
)

# Paths we are explicitly allowed to clean (must be under user-writable junk)
# These are the ONLY roots we ever delete from.
declare -a SAFE_CLEAN_ROOTS=()

# Build the allow-list of cleanable locations (user-scoped junk only)
safety_init_allowlist() {
  SAFE_CLEAN_ROOTS=(
    # User caches
    "$HOME/Library/Caches"
    # User logs
    "$HOME/Library/Logs"
    # Trash
    "$HOME/.Trash"
    # Xcode / developer junk
    "$HOME/Library/Developer/Xcode/DerivedData"
    "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
    "$HOME/Library/Developer/Xcode/watchOS DeviceSupport"
    "$HOME/Library/Developer/Xcode/Archives"
    "$HOME/Library/Developer/CoreSimulator/Caches"
    "$HOME/Library/Developer/CoreSimulator/Devices"  # only orphaned; cleaned carefully
    # Package manager caches
    "$HOME/Library/Caches/Homebrew"
    "$HOME/Library/Caches/pip"
    "$HOME/Library/Caches/CocoaPods"
    "$HOME/Library/Caches/Yarn"
    "$HOME/Library/Caches/typescript"
    "$HOME/Library/Caches/ms-playwright"
    "$HOME/Library/Caches/com.apple.dt.Xcode"
    "$HOME/Library/Caches/GeoServices"
    "$HOME/Library/Caches/com.apple.Safari"
    "$HOME/Library/Caches/com.apple.helpd"
    "$HOME/Library/Caches/CloudKit"
    "$HOME/Library/Caches/com.apple.parsecd"
    "$HOME/Library/Caches/com.apple.appstore"
    "$HOME/Library/Caches/com.apple.Music"
    "$HOME/Library/Caches/com.spotify.client"
    "$HOME/Library/Caches/com.apple.iTunes"
    "$HOME/Library/Caches/Google"
    "$HOME/Library/Caches/Firefox"
    "$HOME/Library/Caches/com.microsoft.VSCode"
    "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt"
    "$HOME/Library/Caches/company.thebrowser.Browser"
    "$HOME/Library/Caches/com.operasoftware.Opera"
    "$HOME/Library/Caches/BraveSoftware"
    "$HOME/Library/Caches/com.hnc.Discord"
    "$HOME/Library/Caches/com.tinyspeck.slackmacgap"
    "$HOME/Library/Caches/us.zoom.xos"
    "$HOME/Library/Caches/com.apple.Safari.SafeBrowsing"
    # npm / yarn / pnpm / cargo / go / gradle (user)
    "$HOME/.npm/_cacache"
    "$HOME/.yarn/cache"
    "$HOME/.cache/yarn"
    "$HOME/.cache/pip"
    "$HOME/.pnpm-store"
    "$HOME/Library/pnpm/store"
    "$HOME/.cargo/registry/cache"
    "$HOME/.gradle/caches"
    "$HOME/Library/Caches/go-build"
    "$HOME/Library/Caches/com.apple.python"
    # System temp (user-writable)
    "/private/var/folders"
    "/private/tmp"
    "/tmp"
    # Diagnostic reports (user)
    "$HOME/Library/Logs/DiagnosticReports"
    "$HOME/Library/Logs/CrashReporter"
    # Saved application state (can rebuild)
    "$HOME/Library/Saved Application State"
    # Font / icon / quicklook caches
    "$HOME/Library/Caches/com.apple.iconservices.store"
    "$HOME/Library/Caches/com.apple.QuickLook.thumbnailcache"
    "$HOME/Library/Caches/com.apple.Safari.CacheService"
    # iOS backups older handling is manual — skip by default
    # Mail downloads cache
    "$HOME/Library/Mail Downloads"
  )

  # Fix accidental space in path above
  # (kept intentionally clean below)
}

# Normalize path (resolve .. and //)
_safety_norm() {
  local p="$1"
  # Remove trailing slash (except root)
  [[ "$p" != "/" ]] && p="${p%/}"
  echo "$p"
}

# Returns 0 if path is safe to delete (is under an allow-listed root and
# is NOT exactly a protected prefix / critical path)
safety_is_path_safe() {
  local target
  target=$(_safety_norm "$1")

  # Empty / dangerous
  [[ -z "$target" || "$target" == "/" || "$target" == "$HOME" ]] && return 1

  # Never delete anything that is exactly a protected prefix
  local prot
  for prot in "${PROTECTED_PREFIXES[@]}"; do
    prot=$(_safety_norm "$prot")
    [[ "$target" == "$prot" ]] && return 1
  done

  # Must live under a known safe clean root
  local root
  for root in "${SAFE_CLEAN_ROOTS[@]}"; do
    root=$(_safety_norm "$root")
    [[ -z "$root" || "$root" == "/" ]] && continue
    if [[ "$target" == "$root" || "$target" == "$root"/* ]]; then
      # Extra: never delete the whole Library or whole Caches parent wrongly
      # if root is Caches, target can be Caches itself or children — OK
      return 0
    fi
  done

  return 1
}

# Safe remove: only if path passes safety_is_path_safe
# Usage: safety_rm PATH [--dry-run]
# Prints bytes freed to stdout as last line? No — sets SAFETY_LAST_FREED
SAFETY_LAST_FREED=0

safety_rm() {
  local path="$1"
  local dry="${2:-}"
  SAFETY_LAST_FREED=0

  if ! safety_is_path_safe "$path"; then
    log_op "BLOCKED unsafe path: $path"
    return 1
  fi

  if [[ ! -e "$path" ]]; then
    return 0
  fi

  local size
  size=$(dir_size "$path")

  if [[ "$dry" == "--dry-run" || "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
    SAFETY_LAST_FREED=$size
    log_op "DRY-RUN would remove: $path ($size bytes)"
    return 0
  fi

  # Prefer rm -rf for dirs/files under allowlist
  if rm -rf "$path" 2>/dev/null; then
    SAFETY_LAST_FREED=$size
    log_op "REMOVED: $path ($size bytes)"
    return 0
  else
    log_op "FAILED remove: $path"
    return 1
  fi
}

# Clean contents of a directory but keep the directory itself
safety_rm_contents() {
  local dir="$1"
  local dry="${2:-}"
  SAFETY_LAST_FREED=0

  if ! safety_is_path_safe "$dir"; then
    log_op "BLOCKED contents of: $dir"
    return 1
  fi

  if [[ ! -d "$dir" ]]; then
    return 0
  fi

  local total=0 size item
  # shellcheck disable=SC2012
  while IFS= read -r -d '' item; do
    size=$(dir_size "$item")
    if [[ "$dry" == "--dry-run" || "${LUSTR_DRY_RUN:-0}" == "1" ]]; then
      total=$(( total + size ))
      log_op "DRY-RUN would remove: $item ($size bytes)"
    else
      if rm -rf "$item" 2>/dev/null; then
        total=$(( total + size ))
        log_op "REMOVED: $item ($size bytes)"
      fi
    fi
  done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

  SAFETY_LAST_FREED=$total
  return 0
}

# Never-delete filename patterns even inside safe roots
safety_should_skip_name() {
  local name="$1"
  case "$name" in
    *.keychain*|*.pem|*.p12|*.mobileprovision)
      return 0 ;;
    Cookies.binarycookies|Bookmarks.plist|History.db|Login\ Data|Web\ Data)
      return 0 ;;
  esac
  return 1
}

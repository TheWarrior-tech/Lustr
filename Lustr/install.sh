#!/usr/bin/env bash
# Lustr installer — one-line install for macOS
# curl -fsSL https://raw.githubusercontent.com/TheWarrior-tech/Lustr/main/install.sh | bash
set -euo pipefail

REPO="TheWarrior-tech/Lustr"
BRANCH="${LUSTR_BRANCH:-main}"
INSTALL_DIR="${LUSTR_INSTALL_DIR:-$HOME/.lustr}"
BIN_NAME="lustr"

# Colors
if [[ -t 1 ]]; then
  C='\033[38;5;81m'; G='\033[38;5;114m'; R='\033[38;5;203m'
  D='\033[2m'; B='\033[1m'; Z='\033[0m'
else
  C=''; G=''; R=''; D=''; B=''; Z=''
fi

info()  { printf "  ${C}·${Z} %s\n" "$*"; }
ok()    { printf "  ${G}✓${Z} %s\n" "$*"; }
err()   { printf "  ${R}✗${Z} %s\n" "$*"; exit 1; }

printf "\n"
printf "  ${C}${B}Lustr${Z} ${D}installer${Z}\n"
printf "  ${D}Polish your Mac. Keep what matters.${Z}\n\n"

# macOS only
[[ "$(uname -s)" == "Darwin" ]] || err "Lustr requires macOS."

# Dependencies
command -v curl >/dev/null || err "curl is required."
command -v tar  >/dev/null || err "tar is required."

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

info "Downloading Lustr from GitHub..."
ARCHIVE_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

if ! curl -fsSL "$ARCHIVE_URL" -o "$TMP/lustr.tar.gz" 2>/dev/null; then
  # Fallback: git clone if tarball fails (e.g. empty repo)
  if command -v git >/dev/null; then
    info "Tarball unavailable — cloning repository..."
    git clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO}.git" "$TMP/repo" \
      || err "Could not download Lustr. Is the repo public at github.com/${REPO}?"
    SRC="$TMP/repo"
  else
    err "Could not download Lustr. Check https://github.com/${REPO}"
  fi
else
  tar -xzf "$TMP/lustr.tar.gz" -C "$TMP"
  # GitHub archive extracts to Repo-branch
  SRC="$(find "$TMP" -maxdepth 1 -type d -name 'Lustr-*' | head -1)"
  [[ -n "$SRC" && -d "$SRC" ]] || err "Unexpected archive layout."
fi

[[ -f "$SRC/bin/lustr" ]] || err "bin/lustr missing from download."

info "Installing to ${INSTALL_DIR}..."
mkdir -p "$INSTALL_DIR"
# Replace contents cleanly
rm -rf "${INSTALL_DIR}/bin" "${INSTALL_DIR}/lib"
cp -R "$SRC/bin" "$INSTALL_DIR/"
cp -R "$SRC/lib" "$INSTALL_DIR/"
# Optional docs
[[ -f "$SRC/README.md" ]] && cp "$SRC/README.md" "$INSTALL_DIR/" || true
[[ -f "$SRC/LICENSE" ]] && cp "$SRC/LICENSE" "$INSTALL_DIR/" || true

chmod +x "$INSTALL_DIR/bin/lustr"

# Prefer ~/.local/bin (no sudo), fall back to /usr/local/bin
LINK_DIR=""
if [[ -d "$HOME/.local/bin" ]] || mkdir -p "$HOME/.local/bin" 2>/dev/null; then
  LINK_DIR="$HOME/.local/bin"
elif [[ -w "/usr/local/bin" ]]; then
  LINK_DIR="/usr/local/bin"
elif mkdir -p /usr/local/bin 2>/dev/null; then
  LINK_DIR="/usr/local/bin"
else
  # last resort: try sudo for /usr/local/bin
  if command -v sudo >/dev/null && sudo mkdir -p /usr/local/bin 2>/dev/null; then
    LINK_DIR="/usr/local/bin"
  fi
fi

if [[ -n "$LINK_DIR" ]]; then
  ln -sfn "$INSTALL_DIR/bin/lustr" "$LINK_DIR/lustr"
  if [[ "$LINK_DIR" == "/usr/local/bin" ]] && [[ ! -w "$LINK_DIR/lustr" ]] && [[ ! -L "$LINK_DIR/lustr" ]]; then
    sudo ln -sfn "$INSTALL_DIR/bin/lustr" "$LINK_DIR/lustr"
  fi
  ok "Linked ${LINK_DIR}/lustr"
else
  err "Could not create a bin symlink. Add ${INSTALL_DIR}/bin to your PATH."
fi

# PATH hint
path_ok=0
case ":$PATH:" in
  *":$LINK_DIR:"*) path_ok=1 ;;
esac

printf "\n"
ok "Lustr installed successfully."
printf "\n"

if [[ "$path_ok" != "1" ]]; then
  printf "  ${D}Add this to your shell profile (~/.zshrc or ~/.bashrc):${Z}\n\n"
  printf "    ${C}export PATH=\"%s:\$PATH\"${Z}\n\n" "$LINK_DIR"
  printf "  ${D}Then run:  source ~/.zshrc${Z}\n\n"
fi

printf "  ${B}Get started${Z}\n"
printf "    ${C}lustr${Z}              ${D}interactive menu${Z}\n"
printf "    ${C}lustr scan${Z}         ${D}preview reclaimable junk${Z}\n"
printf "    ${C}lustr clean -n${Z}     ${D}dry-run deep clean${Z}\n"
printf "    ${C}lustr clean${Z}        ${D}polish your Mac${Z}\n"
printf "\n"

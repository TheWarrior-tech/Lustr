# Lustr

**Polish your Mac. Keep what matters.**

A premium terminal cleaner for macOS — deep-cleans caches, logs, and junk without touching your documents, photos, mail, or apps.

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-black?style=flat-square" alt="macOS" />
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT" />
  <img src="https://img.shields.io/badge/install-1%20line-brightgreen?style=flat-square" alt="1-line install" />
</p>

---

## Install (one line)

```bash
curl -fsSL https://raw.githubusercontent.com/TheWarrior-tech/Lustr/main/install.sh | bash
```

Then:

```bash
lustr
```

---

## Why Lustr?

Most cleaners either scare you with dark-pattern “threats,” or go so deep they risk real data. Lustr sits in the middle:

| Principle | What it means |
|-----------|----------------|
| **Junk only** | Caches, logs, Trash, temp, package-manager caches |
| **Never personal** | Documents, Desktop, Photos, Mail, Messages, Keychains stay off-limits |
| **Preview first** | `scan` and `--dry-run` show exactly what would free space |
| **Confirm by default** | Real deletes ask you first (unless you pass `-y`) |
| **Zero bloat** | Pure Bash + macOS built-ins — no agents, no accounts, no GUI tax |

Inspired by tools like [Mole](https://github.com/tw93/mole) and the idea behind CleanMyMac — rebuilt as a focused, open, terminal-native polisher.

---

## Commands

```text
lustr                 Interactive menu
lustr scan            Find reclaimable junk (safe preview)
lustr clean           Deep clean (asks before deleting)
lustr clean --dry-run Simulate a full clean
lustr clean -y        Clean without prompts
lustr analyze         Disk usage of key locations
lustr status          System health snapshot
lustr update          Pull the latest version
lustr uninstall       Remove Lustr
lustr help            Show help
```

### Options

| Flag | Description |
|------|-------------|
| `-n`, `--dry-run` | Preview only — never delete |
| `-y`, `--yes` | Skip confirmation |
| `-q`, `--quiet` | Minimal output |
| `--no-color` | Disable colors |
| `--include-archives` | Also clear Xcode Archives (off by default) |

---

## What gets cleaned

**Safe by design**

- User app caches (`~/Library/Caches`)
- User logs & diagnostic reports
- Trash
- Browser caches (Chrome, Safari, Firefox, Brave, …)
- Xcode DerivedData & iOS DeviceSupport
- Simulator caches
- Homebrew / npm / Yarn / pnpm / pip / Cargo / Gradle / CocoaPods caches
- Saved application state
- Old temp files
- `.DS_Store` clutter under your home folder

**Never touched**

- `/System`, `/Applications`, and system frameworks  
- `Documents`, `Desktop`, `Downloads`, `Pictures`, `Movies`, `Music`  
- Mail, Messages, Calendars, Contacts, Photos libraries  
- Keychains, SSH keys, cloud credentials  
- App preferences, Safari bookmarks/history, cookies  
- Your actual project source code  

---

## Safety model

1. **Allow-list only** — deletes only under known junk roots.  
2. **Hard deny-list** — refuses whole home, Library roots, and personal folders.  
3. **Dry-run everywhere** — `lustr clean -n` reports sizes without removing a byte.  
4. **Operation log** — actions append to `~/.lustr/logs/operations.log`.  

> Always run `lustr scan` or `lustr clean --dry-run` the first time.

---

## Uninstall

```bash
lustr uninstall
# or
curl -fsSL https://raw.githubusercontent.com/TheWarrior-tech/Lustr/main/install.sh | bash -s -- # then lustr uninstall
```

Removes `~/.lustr` and the `lustr` symlink. Your files stay put.

---

## Manual / local install

```bash
git clone https://github.com/TheWarrior-tech/Lustr.git
cd Lustr
./install.sh
# or run in place:
./bin/lustr scan
```

---

## Requirements

- macOS 13+ (earlier versions may work; untested)
- `bash`, `curl`, standard UNIX tools (all present by default)

---

## License

MIT © TheWarrior-tech

---

<p align="center"><sub>Lustr — polish your Mac. Keep what matters.</sub></p>

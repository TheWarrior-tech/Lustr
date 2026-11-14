# Lustr 2.0

**Polish your Mac. Keep what matters.**

A premium terminal cleaner for macOS — rebuilt from the ground up with [OpenTUI](https://github.com/anomalyco/opentui) for a modern interactive experience, significantly deeper cleaning coverage, and **external volume support**.

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-black?style=flat-square" alt="macOS" />
  <img src="https://img.shields.io/badge/runtime-Bun-f472b6?style=flat-square" alt="Bun" />
  <img src="https://img.shields.io/badge/UI-OpenTUI-5eead4?style=flat-square" alt="OpenTUI" />
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT" />
  <img src="https://img.shields.io/badge/version-2.0.0-cyan?style=flat-square" alt="version" />
</p>

---

## What's new in 2.0

| Area | Before (1.x Bash) | 2.0 |
|------|-------------------|-----|
| UI | Simple ANSI menu | Full **OpenTUI** interactive dashboard |
| Coverage | Surface caches | Deep developer + package + app + browser targets |
| Volumes | Home only | **External drives** (`.Trashes`, optional indexes) |
| Runtime | Pure Bash | **Bun + TypeScript** |
| Safety | Allow-list | Same hard safety model, expanded roots |

---

## Install

**Requires [Bun](https://bun.sh) 1.1+** (and macOS 13+).

```bash
git clone https://github.com/TheWarrior-tech/Lustr.git
cd Lustr
bun install
bun link   # optional: puts `lustr` on your PATH
```

Or run in place:

```bash
bun run src/index.ts
```

---

## Usage

```text
lustr                 Interactive OpenTUI dashboard
lustr scan            Scan reclaimable junk (home + external volumes)
lustr clean           Deep clean (asks before deleting)
lustr clean --dry-run Preview only
lustr clean -y        Clean without prompts
lustr help
```

### Keys (interactive)

- `s` — scan
- `c` — clean
- `d` — dry-run
- `q` — quit

### Flags

| Flag | Description |
|------|-------------|
| `-n`, `--dry-run` | Never delete |
| `-y`, `--yes` | Skip confirmation |
| `--include-optional` | Include Xcode Archives + optional volume indexes |
| `--no-volumes` | Skip external drives |

---

## What gets cleaned

**Home**

- User caches & logs, Trash, diagnostic reports
- HTTPStorages, WebKit
- Xcode DerivedData, DeviceSupport, Simulator caches, SwiftPM
- Unavailable simulators (`simctl delete unavailable`)
- Homebrew, npm, Yarn, pnpm, pip, uv, Cargo, Gradle, CocoaPods, Bun, Go
- Docker reclaimable (`docker system prune`)
- Chrome, Safari, Firefox, Brave, Edge, Arc
- Spotify, Slack, Discord, Zoom, VS Code, JetBrains

**External volumes** (when mounted)

- `.Trashes` (per-user trash on the drive)
- Optional: `.Spotlight-V100`, `.fseventsd`, `.TemporaryItems`

**Never touched**

Documents, Desktop, Downloads, Pictures, Movies, Music, Mail, Messages, Keychains, SSH keys, app preferences, Photos libraries, Ollama models, project source.

---

## Architecture

```
src/
  index.ts          CLI + TUI launcher
  ui/app.ts         OpenTUI dashboard
  engine/
    types.ts        Shared types
    targets.ts      Allow-listed clean targets
    volumes.ts      Internal + external volume discovery
    safety.ts       Hard deny / allow checks
    scan.ts         Size scan
    clean.ts        Safe delete + tool-native commands
  utils/size.ts     Human sizes + du helpers
```

---

## Safety model

1. **Allow-list only** — every path must match a known junk root.
2. **Hard protected set** — `/`, `/System`, home root, personal folders.
3. **Dry-run everywhere** — `lustr clean -n` never deletes.
4. **Tool-native first** — prefers `brew cleanup`, `npm cache clean`, `docker system prune`, etc.
5. **Volumes** — only hidden system/trash folders on external mounts; never user files.

---

## License

MIT © TheWarrior-tech

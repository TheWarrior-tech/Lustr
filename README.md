# Lustr 2.0

**Polish your Mac. Keep what matters.**

A premium terminal cleaner for macOS — rebuilt with [OpenTUI](https://github.com/anomalyco/opentui), **Normal / Deep** modes, multi-drive selection, and deeper junk coverage.

## Install (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/TheWarrior-tech/Lustr/main/install.sh | bash
```

Then open a new terminal (or `source ~/.zshrc`) and run `lustr`.

## Interactive flow

1. **Choose mode** — ↑↓ select **Normal** or **Deep**, Enter  
2. **Pick drives** — ↑↓ move, **Space** toggle volumes (1–9 also work)  
3. **Scan / clean** — Enter to scan, `c` clean, `d` dry-run  

| Key | Action |
|-----|--------|
| ↑↓ / j k | Move selection |
| Space | Toggle volume |
| a / n | Select all / none volumes |
| Enter | Continue / scan |
| c | Clean |
| d | Dry-run |
| 1 / 2 | Normal / Deep on home screen |
| q / Esc | Quit / back |

## CLI

```text
lustr scan
lustr scan --deep
lustr clean --deep --dry-run
lustr clean -y --deep
```

| Flag | Description |
|------|-------------|
| `-n`, `--dry-run` | Never delete |
| `-y`, `--yes` | Skip confirmation |
| `--deep` | Deep clean target set |
| `--no-volumes` | Skip external drives |

## What gets cleaned

**Normal** — caches, logs, Trash, Xcode DerivedData, package managers, browsers, common apps.

**Deep adds** — Telegram, Notion, Figma, Adobe, Steam, Teams, OneDrive, more browsers, Xcode Archives, Docker image prune, Playwright/Cypress/Android/Flutter/Maven, volume Spotlight/fseventsd, Quick Look / Music / TV / Photos *app caches* (never libraries).

**Never touched** — Documents, Photos libraries, Mail, Messages, Keychains, SSH keys, project source.

## License

MIT © TheWarrior-tech

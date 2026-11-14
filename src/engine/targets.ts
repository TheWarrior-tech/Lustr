/** Comprehensive clean targets — deeper than previous Bash surface clean */

import type { CleanTarget } from "./types";

const home = (p: string) => `{home}${p}`;

/** Primary allow-listed targets under the user home */
export const HOME_TARGETS: CleanTarget[] = [
  // ── Core ──────────────────────────────────────────────
  { id: "user_caches", name: "User app caches", category: "Caches", path: home("/Library/Caches"), mode: "contents", risk: "low" },
  { id: "user_logs", name: "User logs", category: "Logs", path: home("/Library/Logs"), mode: "contents", risk: "low" },
  { id: "trash", name: "Trash", category: "Trash", path: home("/.Trash"), mode: "contents", risk: "low" },
  { id: "saved_state", name: "Saved application state", category: "System", path: home("/Library/Saved Application State"), mode: "contents", risk: "low" },
  { id: "diagnostics", name: "Diagnostic reports", category: "Logs", path: home("/Library/Logs/DiagnosticReports"), mode: "contents", risk: "low" },
  { id: "http_storages", name: "HTTP storages", category: "Caches", path: home("/Library/HTTPStorages"), mode: "contents", risk: "low" },
  { id: "webkit", name: "WebKit data", category: "Caches", path: home("/Library/WebKit"), mode: "contents", risk: "low" },

  // ── Developer / Xcode ─────────────────────────────────
  { id: "xcode_derived", name: "Xcode DerivedData", category: "Developer", path: home("/Library/Developer/Xcode/DerivedData"), mode: "contents", risk: "low" },
  { id: "xcode_ios_support", name: "Xcode iOS DeviceSupport", category: "Developer", path: home("/Library/Developer/Xcode/iOS DeviceSupport"), mode: "contents", risk: "low" },
  { id: "xcode_watch_support", name: "Xcode watchOS DeviceSupport", category: "Developer", path: home("/Library/Developer/Xcode/watchOS DeviceSupport"), mode: "contents", risk: "low" },
  { id: "xcode_tv_support", name: "Xcode tvOS DeviceSupport", category: "Developer", path: home("/Library/Developer/Xcode/tvOS DeviceSupport"), mode: "contents", risk: "low" },
  { id: "sim_caches", name: "Simulator caches", category: "Developer", path: home("/Library/Developer/CoreSimulator/Caches"), mode: "contents", risk: "low" },
  { id: "swiftpm", name: "SwiftPM cache", category: "Developer", path: home("/Library/Caches/org.swift.swiftpm"), mode: "contents", risk: "low" },
  { id: "xcode_app_cache", name: "Xcode app cache", category: "Developer", path: home("/Library/Caches/com.apple.dt.Xcode"), mode: "contents", risk: "low" },
  { id: "xcode_archives", name: "Xcode Archives", category: "Developer", path: home("/Library/Developer/Xcode/Archives"), mode: "contents", risk: "medium", optional: true },
  { id: "sim_unavailable", name: "Unavailable simulators", category: "Developer", path: "", mode: "command", command: "xcrun simctl delete unavailable", risk: "low" },

  // ── Package managers ──────────────────────────────────
  { id: "homebrew", name: "Homebrew cache", category: "Dev Tools", path: home("/Library/Caches/Homebrew"), mode: "contents", command: "brew cleanup -s --prune=all", risk: "low" },
  { id: "npm", name: "npm cache", category: "Dev Tools", path: home("/.npm/_cacache"), mode: "contents", command: "npm cache clean --force", risk: "low" },
  { id: "yarn", name: "Yarn cache", category: "Dev Tools", path: home("/.yarn/cache"), mode: "contents", risk: "low" },
  { id: "yarn_cache2", name: "Yarn cache (.cache)", category: "Dev Tools", path: home("/.cache/yarn"), mode: "contents", risk: "low" },
  { id: "pnpm", name: "pnpm store", category: "Dev Tools", path: home("/Library/pnpm/store"), mode: "command", command: "pnpm store prune", risk: "medium" },
  { id: "pip", name: "pip cache", category: "Dev Tools", path: home("/.cache/pip"), mode: "contents", command: "pip3 cache purge", risk: "low" },
  { id: "uv", name: "uv cache", category: "Dev Tools", path: home("/.cache/uv"), mode: "contents", command: "uv cache clean", risk: "low" },
  { id: "cargo", name: "Cargo registry cache", category: "Dev Tools", path: home("/.cargo/registry/cache"), mode: "contents", risk: "low" },
  { id: "gradle", name: "Gradle caches", category: "Dev Tools", path: home("/.gradle/caches"), mode: "contents", risk: "low" },
  { id: "cocoapods", name: "CocoaPods cache", category: "Dev Tools", path: home("/Library/Caches/CocoaPods"), mode: "contents", risk: "low" },
  { id: "bun", name: "Bun install cache", category: "Dev Tools", path: home("/.bun/install/cache"), mode: "contents", risk: "low" },
  { id: "go", name: "Go build cache", category: "Dev Tools", path: home("/Library/Caches/go-build"), mode: "contents", risk: "low" },
  { id: "docker", name: "Docker reclaimable", category: "Dev Tools", path: "", mode: "command", command: "docker system prune -f", risk: "medium" },

  // ── Browsers ──────────────────────────────────────────
  { id: "chrome", name: "Chrome cache", category: "Browsers", path: home("/Library/Caches/Google"), mode: "contents", risk: "low" },
  { id: "firefox", name: "Firefox cache", category: "Browsers", path: home("/Library/Caches/Firefox"), mode: "contents", risk: "low" },
  { id: "safari", name: "Safari cache", category: "Browsers", path: home("/Library/Caches/com.apple.Safari"), mode: "contents", risk: "low" },
  { id: "brave", name: "Brave cache", category: "Browsers", path: home("/Library/Caches/BraveSoftware"), mode: "contents", risk: "low" },
  { id: "edge", name: "Edge cache", category: "Browsers", path: home("/Library/Caches/Microsoft Edge"), mode: "contents", risk: "low" },
  { id: "arc", name: "Arc cache", category: "Browsers", path: home("/Library/Caches/company.thebrowser.Browser"), mode: "contents", risk: "low" },

  // ── Heavy apps ────────────────────────────────────────
  { id: "spotify", name: "Spotify cache", category: "Apps", path: home("/Library/Caches/com.spotify.client"), mode: "contents", risk: "low" },
  { id: "slack", name: "Slack cache", category: "Apps", path: home("/Library/Caches/com.tinyspeck.slackmacgap"), mode: "contents", risk: "low" },
  { id: "discord", name: "Discord cache", category: "Apps", path: home("/Library/Caches/com.hnc.Discord"), mode: "contents", risk: "low" },
  { id: "zoom", name: "Zoom cache", category: "Apps", path: home("/Library/Caches/us.zoom.xos"), mode: "contents", risk: "low" },
  { id: "vscode", name: "VS Code cache", category: "Apps", path: home("/Library/Caches/com.microsoft.VSCode"), mode: "contents", risk: "low" },
  { id: "jetbrains", name: "JetBrains caches", category: "Apps", path: home("/Library/Caches/JetBrains"), mode: "contents", risk: "low" },
];

/** Targets applied per external volume root */
export const VOLUME_TARGETS: CleanTarget[] = [
  {
    id: "vol_trash",
    name: "Volume Trash (.Trashes)",
    category: "Volumes",
    path: "{volume}/.Trashes",
    mode: "contents",
    volumeOnly: true,
    risk: "low",
  },
  {
    id: "vol_spotlight",
    name: "Volume Spotlight index",
    category: "Volumes",
    path: "{volume}/.Spotlight-V100",
    mode: "remove",
    volumeOnly: true,
    risk: "medium",
    optional: true,
  },
  {
    id: "vol_fsevents",
    name: "Volume fseventsd",
    category: "Volumes",
    path: "{volume}/.fseventsd",
    mode: "contents",
    volumeOnly: true,
    risk: "medium",
    optional: true,
  },
  {
    id: "vol_tmp",
    name: "Volume temporary files",
    category: "Volumes",
    path: "{volume}/.TemporaryItems",
    mode: "contents",
    volumeOnly: true,
    risk: "low",
  },
];

export function resolvePath(template: string, homeDir: string, volumePath?: string): string {
  return template
    .replaceAll("{home}", homeDir)
    .replaceAll("{volume}", volumePath ?? "");
}

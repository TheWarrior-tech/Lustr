/** Comprehensive clean targets — normal + deep modes */

import type { CleanTarget } from "./types";

const home = (p: string) => `{home}${p}`;

export const HOME_TARGETS: CleanTarget[] = [
  { id: "user_caches", name: "User app caches", category: "Caches", path: home("/Library/Caches"), mode: "contents", risk: "low" },
  { id: "user_logs", name: "User logs", category: "Logs", path: home("/Library/Logs"), mode: "contents", risk: "low" },
  { id: "trash", name: "Trash", category: "Trash", path: home("/.Trash"), mode: "contents", risk: "low" },
  { id: "saved_state", name: "Saved application state", category: "System", path: home("/Library/Saved Application State"), mode: "contents", risk: "low" },
  { id: "diagnostics", name: "Diagnostic reports", category: "Logs", path: home("/Library/Logs/DiagnosticReports"), mode: "contents", risk: "low" },
  { id: "http_storages", name: "HTTP storages", category: "Caches", path: home("/Library/HTTPStorages"), mode: "contents", risk: "low" },
  { id: "webkit", name: "WebKit data", category: "Caches", path: home("/Library/WebKit"), mode: "contents", risk: "low" },
  { id: "crash_reporter", name: "CrashReporter logs", category: "Logs", path: home("/Library/Logs/CrashReporter"), mode: "contents", risk: "low" },
  { id: "xcode_derived", name: "Xcode DerivedData", category: "Developer", path: home("/Library/Developer/Xcode/DerivedData"), mode: "contents", risk: "low" },
  { id: "xcode_ios_support", name: "Xcode iOS DeviceSupport", category: "Developer", path: home("/Library/Developer/Xcode/iOS DeviceSupport"), mode: "contents", risk: "low" },
  { id: "xcode_watch_support", name: "Xcode watchOS DeviceSupport", category: "Developer", path: home("/Library/Developer/Xcode/watchOS DeviceSupport"), mode: "contents", risk: "low" },
  { id: "xcode_tv_support", name: "Xcode tvOS DeviceSupport", category: "Developer", path: home("/Library/Developer/Xcode/tvOS DeviceSupport"), mode: "contents", risk: "low" },
  { id: "sim_caches", name: "Simulator caches", category: "Developer", path: home("/Library/Developer/CoreSimulator/Caches"), mode: "contents", risk: "low" },
  { id: "swiftpm", name: "SwiftPM cache", category: "Developer", path: home("/Library/Caches/org.swift.swiftpm"), mode: "contents", risk: "low" },
  { id: "xcode_app_cache", name: "Xcode app cache", category: "Developer", path: home("/Library/Caches/com.apple.dt.Xcode"), mode: "contents", risk: "low" },
  { id: "xcode_archives", name: "Xcode Archives", category: "Developer", path: home("/Library/Developer/Xcode/Archives"), mode: "contents", risk: "medium", optional: true, depth: "deep" },
  { id: "sim_unavailable", name: "Unavailable simulators", category: "Developer", path: "", mode: "command", command: "xcrun simctl delete unavailable", risk: "low" },
  { id: "homebrew", name: "Homebrew cache", category: "Dev Tools", path: home("/Library/Caches/Homebrew"), mode: "contents", command: "brew cleanup -s --prune=all", risk: "low" },
  { id: "npm", name: "npm cache", category: "Dev Tools", path: home("/.npm/_cacache"), mode: "contents", command: "npm cache clean --force", risk: "low" },
  { id: "npm_logs", name: "npm logs", category: "Dev Tools", path: home("/.npm/_logs"), mode: "contents", risk: "low", depth: "deep" },
  { id: "yarn", name: "Yarn cache", category: "Dev Tools", path: home("/.yarn/cache"), mode: "contents", risk: "low" },
  { id: "yarn_cache2", name: "Yarn cache (.cache)", category: "Dev Tools", path: home("/.cache/yarn"), mode: "contents", risk: "low" },
  { id: "pnpm", name: "pnpm store", category: "Dev Tools", path: home("/Library/pnpm/store"), mode: "command", command: "pnpm store prune", risk: "medium" },
  { id: "pip", name: "pip cache", category: "Dev Tools", path: home("/.cache/pip"), mode: "contents", command: "pip3 cache purge", risk: "low" },
  { id: "uv", name: "uv cache", category: "Dev Tools", path: home("/.cache/uv"), mode: "contents", command: "uv cache clean", risk: "low" },
  { id: "cargo", name: "Cargo registry cache", category: "Dev Tools", path: home("/.cargo/registry/cache"), mode: "contents", risk: "low" },
  { id: "cargo_git", name: "Cargo git checkouts", category: "Dev Tools", path: home("/.cargo/git/checkouts"), mode: "contents", risk: "low", depth: "deep" },
  { id: "gradle", name: "Gradle caches", category: "Dev Tools", path: home("/.gradle/caches"), mode: "contents", risk: "low" },
  { id: "cocoapods", name: "CocoaPods cache", category: "Dev Tools", path: home("/Library/Caches/CocoaPods"), mode: "contents", risk: "low" },
  { id: "bun", name: "Bun install cache", category: "Dev Tools", path: home("/.bun/install/cache"), mode: "contents", risk: "low" },
  { id: "go", name: "Go build cache", category: "Dev Tools", path: home("/Library/Caches/go-build"), mode: "contents", risk: "low" },
  { id: "docker", name: "Docker reclaimable", category: "Dev Tools", path: "", mode: "command", command: "docker system prune -f", risk: "medium" },
  { id: "docker_deep", name: "Docker prune (images + build cache)", category: "Dev Tools", path: "", mode: "command", command: "docker system prune -af", risk: "medium", depth: "deep" },
  { id: "playwright", name: "Playwright browsers cache", category: "Dev Tools", path: home("/Library/Caches/ms-playwright"), mode: "contents", risk: "medium", depth: "deep" },
  { id: "cypress", name: "Cypress cache", category: "Dev Tools", path: home("/Library/Caches/Cypress"), mode: "contents", risk: "low", depth: "deep" },
  { id: "android", name: "Android build cache", category: "Dev Tools", path: home("/.android/build-cache"), mode: "contents", risk: "low", depth: "deep" },
  { id: "android_cache", name: "Android cache", category: "Dev Tools", path: home("/.android/cache"), mode: "contents", risk: "low", depth: "deep" },
  { id: "flutter_pub", name: "Flutter / Dart pub cache", category: "Dev Tools", path: home("/.pub-cache"), mode: "contents", risk: "medium", depth: "deep" },
  { id: "composer", name: "Composer cache", category: "Dev Tools", path: home("/.composer/cache"), mode: "contents", risk: "low", depth: "deep" },
  { id: "maven", name: "Maven repository cache", category: "Dev Tools", path: home("/.m2/repository"), mode: "contents", risk: "medium", depth: "deep" },
  { id: "chrome", name: "Chrome cache", category: "Browsers", path: home("/Library/Caches/Google"), mode: "contents", risk: "low" },
  { id: "firefox", name: "Firefox cache", category: "Browsers", path: home("/Library/Caches/Firefox"), mode: "contents", risk: "low" },
  { id: "safari", name: "Safari cache", category: "Browsers", path: home("/Library/Caches/com.apple.Safari"), mode: "contents", risk: "low" },
  { id: "brave", name: "Brave cache", category: "Browsers", path: home("/Library/Caches/BraveSoftware"), mode: "contents", risk: "low" },
  { id: "edge", name: "Edge cache", category: "Browsers", path: home("/Library/Caches/Microsoft Edge"), mode: "contents", risk: "low" },
  { id: "arc", name: "Arc cache", category: "Browsers", path: home("/Library/Caches/company.thebrowser.Browser"), mode: "contents", risk: "low" },
  { id: "opera", name: "Opera cache", category: "Browsers", path: home("/Library/Caches/com.operasoftware.Opera"), mode: "contents", risk: "low", depth: "deep" },
  { id: "vivaldi", name: "Vivaldi cache", category: "Browsers", path: home("/Library/Caches/Vivaldi"), mode: "contents", risk: "low", depth: "deep" },
  { id: "chromium", name: "Chromium cache", category: "Browsers", path: home("/Library/Caches/Chromium"), mode: "contents", risk: "low", depth: "deep" },
  { id: "spotify", name: "Spotify cache", category: "Apps", path: home("/Library/Caches/com.spotify.client"), mode: "contents", risk: "low" },
  { id: "slack", name: "Slack cache", category: "Apps", path: home("/Library/Caches/com.tinyspeck.slackmacgap"), mode: "contents", risk: "low" },
  { id: "discord", name: "Discord cache", category: "Apps", path: home("/Library/Caches/com.hnc.Discord"), mode: "contents", risk: "low" },
  { id: "zoom", name: "Zoom cache", category: "Apps", path: home("/Library/Caches/us.zoom.xos"), mode: "contents", risk: "low" },
  { id: "vscode", name: "VS Code cache", category: "Apps", path: home("/Library/Caches/com.microsoft.VSCode"), mode: "contents", risk: "low" },
  { id: "jetbrains", name: "JetBrains caches", category: "Apps", path: home("/Library/Caches/JetBrains"), mode: "contents", risk: "low" },
  { id: "telegram", name: "Telegram cache", category: "Apps", path: home("/Library/Caches/ru.keepcoder.Telegram"), mode: "contents", risk: "low", depth: "deep" },
  { id: "notion", name: "Notion cache", category: "Apps", path: home("/Library/Caches/notion.id"), mode: "contents", risk: "low", depth: "deep" },
  { id: "figma", name: "Figma cache", category: "Apps", path: home("/Library/Caches/com.figma.Desktop"), mode: "contents", risk: "low", depth: "deep" },
  { id: "adobe", name: "Adobe caches", category: "Apps", path: home("/Library/Caches/Adobe"), mode: "contents", risk: "low", depth: "deep" },
  { id: "steam", name: "Steam appcache", category: "Apps", path: home("/Library/Application Support/Steam/appcache"), mode: "contents", risk: "medium", depth: "deep" },
  { id: "dropbox_cache", name: "Dropbox cache", category: "Apps", path: home("/Library/Caches/com.getdropbox.dropbox"), mode: "contents", risk: "low", depth: "deep" },
  { id: "onedrive", name: "OneDrive cache", category: "Apps", path: home("/Library/Caches/com.microsoft.OneDrive"), mode: "contents", risk: "low", depth: "deep" },
  { id: "teams", name: "Microsoft Teams cache", category: "Apps", path: home("/Library/Caches/com.microsoft.teams"), mode: "contents", risk: "low", depth: "deep" },
  { id: "obsidian", name: "Obsidian cache", category: "Apps", path: home("/Library/Caches/md.obsidian"), mode: "contents", risk: "low", depth: "deep" },
  { id: "linear", name: "Linear cache", category: "Apps", path: home("/Library/Caches/com.linear"), mode: "contents", risk: "low", depth: "deep" },
  { id: "raycast", name: "Raycast cache", category: "Apps", path: home("/Library/Caches/com.raycast.macos"), mode: "contents", risk: "low", depth: "deep" },
  { id: "icloud_cache", name: "CloudKit cache leftovers", category: "Caches", path: home("/Library/Caches/CloudKit"), mode: "contents", risk: "low", depth: "deep" },
  { id: "quicklook", name: "Quick Look thumbnails", category: "Caches", path: home("/Library/Caches/com.apple.QuickLook.thumbnailcache"), mode: "contents", risk: "low", depth: "deep" },
  { id: "music_cache", name: "Music app cache", category: "Caches", path: home("/Library/Caches/com.apple.Music"), mode: "contents", risk: "low", depth: "deep" },
  { id: "tv_cache", name: "TV app cache", category: "Caches", path: home("/Library/Caches/com.apple.TV"), mode: "contents", risk: "low", depth: "deep" },
  { id: "photos_cache", name: "Photos app cache (not library)", category: "Caches", path: home("/Library/Caches/com.apple.Photos"), mode: "contents", risk: "low", depth: "deep" },
];

export const VOLUME_TARGETS: CleanTarget[] = [
  { id: "vol_trash", name: "Volume Trash (.Trashes)", category: "Volumes", path: "{volume}/.Trashes", mode: "contents", volumeOnly: true, risk: "low" },
  { id: "vol_tmp", name: "Volume temporary files", category: "Volumes", path: "{volume}/.TemporaryItems", mode: "contents", volumeOnly: true, risk: "low" },
  { id: "vol_spotlight", name: "Volume Spotlight index", category: "Volumes", path: "{volume}/.Spotlight-V100", mode: "remove", volumeOnly: true, risk: "medium", optional: true, depth: "deep" },
  { id: "vol_fsevents", name: "Volume fseventsd", category: "Volumes", path: "{volume}/.fseventsd", mode: "contents", volumeOnly: true, risk: "medium", optional: true, depth: "deep" },
  { id: "vol_docrevs", name: "Volume DocumentRevisions", category: "Volumes", path: "{volume}/.DocumentRevisions-V100", mode: "contents", volumeOnly: true, risk: "medium", optional: true, depth: "deep" },
];

export function resolvePath(template: string, homeDir: string, volumePath?: string): string {
  return template.replaceAll("{home}", homeDir).replaceAll("{volume}", volumePath ?? "");
}

export function targetMatchesMode(t: CleanTarget, mode: "normal" | "deep"): boolean {
  const depth = t.depth ?? "normal";
  if (mode === "deep") return true;
  if (depth === "deep") return false;
  if (t.optional) return false;
  return true;
}

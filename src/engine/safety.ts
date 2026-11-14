/** Hard safety rails — allow-list only */

const PROTECTED_EXACT = new Set([
  "/",
  "/System",
  "/bin",
  "/sbin",
  "/usr",
  "/etc",
  "/var",
  "/private/etc",
  "/Applications",
]);

function norm(p: string): string {
  if (p.length > 1 && p.endsWith("/")) return p.slice(0, -1);
  return p;
}

export function isPathSafe(target: string, homeDir: string, allowedRoots: string[]): boolean {
  const t = norm(target);
  if (!t || t === "/" || t === homeDir) return false;

  for (const p of PROTECTED_EXACT) {
    if (t === p || t.startsWith(p + "/")) {
      // Allow specific known subpaths only via allowlist
      break;
    }
  }

  // Must live under an allow-listed root
  for (const root of allowedRoots) {
    const r = norm(root);
    if (!r || r === "/") continue;
    if (t === r || t.startsWith(r + "/")) return true;
  }
  return false;
}

export function buildAllowedRoots(homeDir: string, volumePaths: string[]): string[] {
  const roots = [
    `${homeDir}/Library/Caches`,
    `${homeDir}/Library/Logs`,
    `${homeDir}/.Trash`,
    `${homeDir}/Library/Developer/Xcode/DerivedData`,
    `${homeDir}/Library/Developer/Xcode/iOS DeviceSupport`,
    `${homeDir}/Library/Developer/Xcode/watchOS DeviceSupport`,
    `${homeDir}/Library/Developer/Xcode/tvOS DeviceSupport`,
    `${homeDir}/Library/Developer/Xcode/Archives`,
    `${homeDir}/Library/Developer/CoreSimulator/Caches`,
    `${homeDir}/Library/Caches/org.swift.swiftpm`,
    `${homeDir}/Library/Caches/Homebrew`,
    `${homeDir}/Library/Caches/pip`,
    `${homeDir}/Library/Caches/CocoaPods`,
    `${homeDir}/Library/Caches/Google`,
    `${homeDir}/Library/Caches/Firefox`,
    `${homeDir}/Library/Caches/com.apple.Safari`,
    `${homeDir}/Library/Caches/BraveSoftware`,
    `${homeDir}/Library/Caches/Microsoft Edge`,
    `${homeDir}/Library/Caches/company.thebrowser.Browser`,
    `${homeDir}/Library/Caches/com.spotify.client`,
    `${homeDir}/Library/Caches/com.tinyspeck.slackmacgap`,
    `${homeDir}/Library/Caches/com.hnc.Discord`,
    `${homeDir}/Library/Caches/us.zoom.xos`,
    `${homeDir}/Library/Caches/com.microsoft.VSCode`,
    `${homeDir}/Library/Caches/JetBrains`,
    `${homeDir}/Library/Caches/com.apple.dt.Xcode`,
    `${homeDir}/Library/HTTPStorages`,
    `${homeDir}/Library/WebKit`,
    `${homeDir}/Library/Saved Application State`,
    `${homeDir}/.npm/_cacache`,
    `${homeDir}/.yarn/cache`,
    `${homeDir}/.cache/yarn`,
    `${homeDir}/.cache/pip`,
    `${homeDir}/.cache/uv`,
    `${homeDir}/.pnpm-store`,
    `${homeDir}/Library/pnpm/store`,
    `${homeDir}/.cargo/registry/cache`,
    `${homeDir}/.gradle/caches`,
    `${homeDir}/.bun/install/cache`,
    `${homeDir}/Library/Caches/go-build`,
  ];

  for (const v of volumePaths) {
    roots.push(`${v}/.Trashes`);
    roots.push(`${v}/.Spotlight-V100`);
    roots.push(`${v}/.fseventsd`);
    roots.push(`${v}/.TemporaryItems`);
  }

  return roots;
}

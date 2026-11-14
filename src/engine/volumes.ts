/** Discover internal + external volumes */

import type { VolumeInfo } from "./types";

export async function listVolumes(): Promise<VolumeInfo[]> {
  const volumes: VolumeInfo[] = [];

  // Internal data volume (home)
  const home = process.env.HOME ?? "/Users/unknown";
  const internal = await dfFor(home);
  volumes.push({
    path: "/",
    name: "Macintosh HD",
    freeBytes: internal.free,
    totalBytes: internal.total,
    isInternal: true,
    isExternal: false,
  });

  // Mounted volumes under /Volumes
  try {
    const proc = Bun.spawn(["ls", "-1", "/Volumes"], { stdout: "pipe", stderr: "pipe" });
    const out = await new Response(proc.stdout).text();
    await proc.exited;
    const names = out
      .split("\n")
      .map((s) => s.trim())
      .filter(Boolean);

    for (const name of names) {
      // Skip the primary volume symlink often named after the disk
      const mount = `/Volumes/${name}`;
      const stats = await dfFor(mount);
      if (stats.total === 0) continue;

      // Heuristic: external if not the root filesystem
      const rootDev = await deviceFor("/");
      const thisDev = await deviceFor(mount);
      const isExternal = rootDev !== "" && thisDev !== "" && rootDev !== thisDev;

      volumes.push({
        path: mount,
        name,
        freeBytes: stats.free,
        totalBytes: stats.total,
        isInternal: !isExternal,
        isExternal,
      });
    }
  } catch {
    // /Volumes may be restricted
  }

  return volumes;
}

async function dfFor(path: string): Promise<{ free: number; total: number }> {
  try {
    const proc = Bun.spawn(["df", "-k", path], { stdout: "pipe", stderr: "pipe" });
    const out = await new Response(proc.stdout).text();
    await proc.exited;
    const line = out.trim().split("\n")[1];
    if (!line) return { free: 0, total: 0 };
    const parts = line.split(/\s+/);
    const total = parseInt(parts[1] ?? "0", 10) * 1024;
    const free = parseInt(parts[3] ?? "0", 10) * 1024;
    return { free: Number.isFinite(free) ? free : 0, total: Number.isFinite(total) ? total : 0 };
  } catch {
    return { free: 0, total: 0 };
  }
}

async function deviceFor(path: string): Promise<string> {
  try {
    const proc = Bun.spawn(["df", path], { stdout: "pipe", stderr: "pipe" });
    const out = await new Response(proc.stdout).text();
    await proc.exited;
    const line = out.trim().split("\n")[1];
    return line?.split(/\s+/)[0] ?? "";
  } catch {
    return "";
  }
}

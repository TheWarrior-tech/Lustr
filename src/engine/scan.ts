/** Scan engine — home + external volumes */

import type { ScanItem, ScanResult, CleanOptions } from "./types";
import { HOME_TARGETS, VOLUME_TARGETS, resolvePath } from "./targets";
import { listVolumes } from "./volumes";
import { dirSize, pathExists } from "../utils/size";

export async function scan(options: { includeVolumes?: boolean; includeOptional?: boolean } = {}): Promise<ScanResult> {
  const homeDir = process.env.HOME ?? "";
  const includeVolumes = options.includeVolumes !== false;
  const includeOptional = options.includeOptional === true;

  const volumes = await listVolumes();
  const items: ScanItem[] = [];

  // Home targets
  for (const t of HOME_TARGETS) {
    if (t.optional && !includeOptional) continue;
    if (t.mode === "command" && !t.path) {
      // Command-only: report as present if binary exists
      const bin = t.command?.split(/\s+/)[0];
      if (bin) {
        const check = Bun.spawn(["which", bin], { stdout: "pipe", stderr: "pipe" });
        const ok = (await check.exited) === 0;
        if (ok) {
          items.push({
            id: t.id,
            name: t.name,
            category: t.category,
            path: `(command: ${t.command})`,
            bytes: 0,
            volume: "/",
            optional: t.optional,
            risk: t.risk,
          });
        }
      }
      continue;
    }

    const path = resolvePath(t.path, homeDir);
    if (!(await pathExists(path))) continue;
    const bytes = await dirSize(path);
    if (bytes <= 0) continue;

    items.push({
      id: t.id,
      name: t.name,
      category: t.category,
      path,
      bytes,
      volume: "/",
      optional: t.optional,
      risk: t.risk,
    });
  }

  // External volumes
  if (includeVolumes) {
    for (const vol of volumes.filter((v) => v.isExternal)) {
      for (const t of VOLUME_TARGETS) {
        if (t.optional && !includeOptional) continue;
        const path = resolvePath(t.path, homeDir, vol.path);
        if (!(await pathExists(path))) continue;
        const bytes = await dirSize(path);
        if (bytes <= 0) continue;

        items.push({
          id: `${t.id}:${vol.path}`,
          name: `${t.name} (${vol.name})`,
          category: t.category,
          path,
          bytes,
          volume: vol.path,
          optional: t.optional,
          risk: t.risk,
        });
      }
    }
  }

  items.sort((a, b) => b.bytes - a.bytes);
  const totalBytes = items.reduce((s, i) => s + i.bytes, 0);

  return {
    items,
    totalBytes,
    volumes,
    scannedAt: new Date().toISOString(),
  };
}

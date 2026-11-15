/** Clean engine with safety + dry-run + mode / volume filters */

import type { CleanOptions, CleanReport, ScanItem } from "./types";
import { HOME_TARGETS, VOLUME_TARGETS } from "./targets";
import { buildAllowedRoots, isPathSafe } from "./safety";
import { dirSize, pathExists } from "../utils/size";
import { listVolumes } from "./volumes";

async function rmContents(dir: string): Promise<number> {
  const before = await dirSize(dir);
  const proc = Bun.spawn(
    ["bash", "-c", `find ${JSON.stringify(dir)} -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -rf 2>/dev/null || true`],
    { stdout: "pipe", stderr: "pipe" },
  );
  await proc.exited;
  return before;
}

async function rmPath(path: string): Promise<number> {
  const before = await dirSize(path);
  const proc = Bun.spawn(["rm", "-rf", path], { stdout: "pipe", stderr: "pipe" });
  await proc.exited;
  return before;
}

async function runCommand(cmd: string): Promise<boolean> {
  const proc = Bun.spawn(["bash", "-c", cmd], { stdout: "pipe", stderr: "pipe" });
  return (await proc.exited) === 0;
}

export async function clean(
  scanItems: ScanItem[],
  options: CleanOptions,
): Promise<CleanReport> {
  const homeDir = process.env.HOME ?? "";
  const volumes = await listVolumes();
  const allExternal = volumes.filter((v) => v.isExternal).map((v) => v.path);

  const selectedVols =
    options.volumePaths && options.volumePaths.length > 0
      ? options.volumePaths
      : options.includeVolumes
        ? ["/", ...allExternal]
        : ["/"];

  const volumePathsForSafety = selectedVols.filter((p) => p !== "/");
  const allowed = buildAllowedRoots(
    homeDir,
    volumePathsForSafety.length ? volumePathsForSafety : allExternal,
  );

  const report: CleanReport = {
    freedBytes: 0,
    items: [],
    dryRun: options.dryRun,
    mode: options.cleanMode,
  };

  let selected = options.only
    ? scanItems.filter((i) =>
        options.only!.some((id) => i.id === id || i.id.startsWith(id + ":")),
      )
    : [...scanItems];

  selected = selected.filter((i) => selectedVols.includes(i.volume));

  if (!options.includeOptional && options.cleanMode !== "deep") {
    selected = selected.filter((i) => !i.optional);
  }

  for (const item of selected) {
    const baseId = item.id.split(":")[0];
    const def =
      HOME_TARGETS.find((t) => t.id === baseId) ??
      VOLUME_TARGETS.find((t) => t.id === baseId);

    if (!def) {
      report.items.push({ id: item.id, name: item.name, bytes: 0, status: "skip" });
      continue;
    }

    if (def.mode === "command" && def.command) {
      if (options.dryRun) {
        report.items.push({ id: item.id, name: item.name, bytes: item.bytes, status: "dry" });
        report.freedBytes += item.bytes;
        continue;
      }
      const ok = await runCommand(def.command);
      report.items.push({
        id: item.id,
        name: item.name,
        bytes: item.bytes,
        status: ok ? "done" : "fail",
      });
      if (ok) report.freedBytes += item.bytes;
      continue;
    }

    const path = item.path;
    if (!path || path.startsWith("(command")) {
      report.items.push({ id: item.id, name: item.name, bytes: 0, status: "skip" });
      continue;
    }

    if (!isPathSafe(path, homeDir, allowed)) {
      report.items.push({ id: item.id, name: item.name, bytes: 0, status: "skip" });
      continue;
    }

    if (!(await pathExists(path))) {
      report.items.push({ id: item.id, name: item.name, bytes: 0, status: "skip" });
      continue;
    }

    if (options.dryRun) {
      report.items.push({ id: item.id, name: item.name, bytes: item.bytes, status: "dry" });
      report.freedBytes += item.bytes;
      continue;
    }

    try {
      let freed = 0;
      if (def.mode === "contents") {
        if (def.command) await runCommand(def.command);
        freed = await rmContents(path);
      } else {
        freed = await rmPath(path);
      }
      report.items.push({
        id: item.id,
        name: item.name,
        bytes: freed || item.bytes,
        status: "done",
      });
      report.freedBytes += freed || item.bytes;
    } catch {
      report.items.push({ id: item.id, name: item.name, bytes: 0, status: "fail" });
    }
  }

  return report;
}

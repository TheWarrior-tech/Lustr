/** Size helpers */

export function bytesHuman(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return "0 B";
  const units = ["B", "KB", "MB", "GB", "TB"];
  let n = bytes;
  let i = 0;
  while (n >= 1024 && i < units.length - 1) {
    n /= 1024;
    i++;
  }
  return i === 0 ? `${Math.round(n)} B` : `${n.toFixed(1)} ${units[i]}`;
}

export async function dirSize(path: string): Promise<number> {
  try {
    const proc = Bun.spawn(["du", "-sk", path], { stdout: "pipe", stderr: "pipe" });
    const out = await new Response(proc.stdout).text();
    await proc.exited;
    const kb = parseInt(out.trim().split(/\s+/)[0] ?? "0", 10);
    return Number.isFinite(kb) ? kb * 1024 : 0;
  } catch {
    return 0;
  }
}

export async function pathExists(path: string): Promise<boolean> {
  try {
    const s = await Bun.file(path).exists();
    if (s) return true;
  } catch {}
  try {
    const proc = Bun.spawn(["test", "-e", path]);
    return (await proc.exited) === 0;
  } catch {
    return false;
  }
}

/**
 * Lustr OpenTUI dashboard
 * Normal / Deep modes · multi-drive selection · scan / clean / dry-run
 */

import {
  createCliRenderer,
  BoxRenderable,
  TextRenderable,
  type CliRenderer,
} from "@opentui/core";
import { scan } from "../engine/scan";
import { clean } from "../engine/clean";
import { listVolumes } from "../engine/volumes";
import { bytesHuman } from "../utils/size";
import type { ScanResult, VolumeInfo, CleanMode } from "../engine/types";

type Screen = "home" | "volumes" | "scan" | "done";

const COLORS = {
  bg: "#0B0F14",
  accent: "#5EEAD4",
  muted: "#64748B",
  text: "#E2E8F0",
  warn: "#FBBF24",
  danger: "#F87171",
  ok: "#34D399",
  dim: "#334155",
};

export async function runTui() {
  const renderer = await createCliRenderer({
    exitOnCtrlC: true,
    backgroundColor: COLORS.bg,
  });

  let screen: Screen = "home";
  let scanResult: ScanResult | null = null;
  let statusMsg = "Ready";
  let cleanMode: CleanMode = "normal";
  let modeCursor = 0;
  let volumes: VolumeInfo[] = [];
  let selectedVols = new Set<string>(["/"]);
  let volCursor = 0;
  let busy = false;

  const title = new TextRenderable(renderer, {
    id: "title",
    content: "  L U S T R",
    fg: COLORS.accent,
  });
  const subtitle = new TextRenderable(renderer, {
    id: "subtitle",
    content: "  Polish your Mac. Keep what matters.",
    fg: COLORS.muted,
  });
  const body = new TextRenderable(renderer, {
    id: "body",
    content: "",
    fg: COLORS.text,
  });
  const footer = new TextRenderable(renderer, {
    id: "footer",
    content: "",
    fg: COLORS.muted,
  });
  const status = new TextRenderable(renderer, {
    id: "status",
    content: `  ${statusMsg}`,
    fg: COLORS.muted,
  });

  const panel = new BoxRenderable(renderer, {
    width: "100%",
    height: "100%",
    backgroundColor: COLORS.bg,
    padding: 1,
    flexDirection: "column",
    gap: 1,
  });

  const header = new BoxRenderable(renderer, {
    flexDirection: "column",
    gap: 0,
  });
  header.add(title);
  header.add(subtitle);
  panel.add(header);
  panel.add(body);
  panel.add(status);
  panel.add(footer);
  renderer.root.add(panel);

  function setStatus(msg: string, color = COLORS.muted) {
    statusMsg = msg;
    status.content = `  ${msg}`;
    status.fg = color;
  }

  function renderHome() {
    screen = "home";
    const nMark = modeCursor === 0 ? "\u25b8" : " ";
    const dMark = modeCursor === 1 ? "\u25b8" : " ";
    body.content = [
      "",
      "  Choose a clean mode, then pick drives to scan.",
      "",
      `  ${nMark}  Normal clean`,
      "      Everyday caches, logs, Trash, package managers, browsers.",
      "      Fast and safe \u2014 best for regular maintenance.",
      "",
      `  ${dMark}  Deep clean`,
      "      Everything in Normal, plus app caches (Telegram, Adobe,",
      "      Figma\u2026), Xcode Archives, Docker image prune, volume",
      "      Spotlight / fseventsd indexes, more developer debris.",
      "      Still allow-list only \u2014 never Documents, Photos, Mail.",
      "",
      "  \u2191\u2193  select mode   Enter  continue to drives   q  quit",
    ].join("\n");
    footer.content = "  [\u2191\u2193] mode  [Enter] drives  [q] quit";
    setStatus(`Mode: ${cleanMode === "normal" ? "Normal" : "Deep"}`);
  }

  function renderVolumes() {
    screen = "volumes";
    const lines = [
      "",
      `  Mode: ${cleanMode === "deep" ? "Deep clean" : "Normal clean"}`,
      "  Select which volumes to include (Space toggles):",
      "",
    ];
    volumes.forEach((v, i) => {
      const on = selectedVols.has(v.path);
      const cursor = i === volCursor ? "\u25b8" : " ";
      const box = on ? "[\u2713]" : "[ ]";
      const kind = v.isExternal ? "external" : "internal";
      const free = bytesHuman(v.freeBytes);
      const name = v.path === "/" ? `${v.name} (this Mac)` : v.name;
      lines.push(
        `  ${cursor} ${box}  ${name.padEnd(28).slice(0, 28)}  ${kind.padEnd(8)}  free ${free}`,
      );
    });
    if (volumes.length === 0) {
      lines.push("  (no volumes detected)");
    }
    lines.push("");
    lines.push("  \u2191\u2193 move   Space toggle   a all   n none");
    lines.push("  Enter scan   c clean   d dry-run   Esc back");
    body.content = lines.join("\n");
    footer.content =
      "  [\u2191\u2193]  [Space] toggle  [Enter] scan  [c] clean  [d] dry-run  [Esc] back";
    const n = selectedVols.size;
    setStatus(`${n} volume${n === 1 ? "" : "s"} selected \u00b7 ${cleanMode}`);
  }

  function renderScan() {
    screen = "scan";
    if (!scanResult) {
      body.content = "\n  Scanning\u2026";
      return;
    }
    const modeLabel = scanResult.mode === "deep" ? "Deep" : "Normal";
    const lines = [
      "",
      `  ${modeLabel} scan \u00b7 Reclaimable: ${bytesHuman(scanResult.totalBytes)}  \u00b7  ${scanResult.items.length} items`,
      `  Volumes: ${[...selectedVols].map((p) => (p === "/" ? "Macintosh HD" : p.replace("/Volumes/", ""))).join(", ") || "\u2014"}`,
      "",
    ];
    const top = scanResult.items.slice(0, 16);
    for (const item of top) {
      const mark = item.volume === "/" ? "\u00b7" : "\u23cf";
      const deep = item.depth === "deep" ? " \u2605" : "";
      lines.push(
        `  ${mark} ${item.name.padEnd(40).slice(0, 40)} ${bytesHuman(item.bytes).padStart(10)}${deep}`,
      );
    }
    if (scanResult.items.length > 16) {
      lines.push(`  \u2026 and ${scanResult.items.length - 16} more`);
    }
    if (scanResult.items.some((i) => i.depth === "deep")) {
      lines.push("");
      lines.push("  \u2605 = deep-only target");
    }
    lines.push("");
    lines.push("  c clean   d dry-run   v volumes   h home   q quit");
    body.content = lines.join("\n");
    footer.content = "  [c] clean  [d] dry-run  [v] volumes  [h] home  [q] quit";
    setStatus(`Scan complete \u00b7 ${bytesHuman(scanResult.totalBytes)} reclaimable`, COLORS.ok);
  }

  function renderDone(msg: string) {
    screen = "done";
    body.content = `\n  ${msg}\n\n  h home   v volumes   s rescan   q quit\n`;
    footer.content = "  [h] home  [v] volumes  [s] scan  [q] quit";
  }

  async function loadVolumes() {
    volumes = await listVolumes();
    selectedVols = new Set(volumes.map((v) => v.path));
    if (!selectedVols.has("/")) selectedVols.add("/");
    volCursor = 0;
  }

  async function doScan() {
    if (busy) return;
    busy = true;
    setStatus("Scanning\u2026", COLORS.warn);
    body.content = "\n  Scanning selected volumes\u2026\n";
    try {
      const volPaths = [...selectedVols];
      scanResult = await scan({
        includeVolumes: true,
        includeOptional: cleanMode === "deep",
        volumePaths: volPaths,
        cleanMode,
      });
      renderScan();
    } catch (e) {
      setStatus(`Scan failed: ${String(e)}`, COLORS.danger);
    } finally {
      busy = false;
    }
  }

  async function doClean(dryRun: boolean) {
    if (busy) return;
    if (!scanResult) {
      await doScan();
    }
    if (!scanResult || scanResult.totalBytes === 0) {
      setStatus("Nothing to clean", COLORS.ok);
      renderDone("Already clean \u2014 nothing to reclaim.");
      return;
    }
    busy = true;
    setStatus(dryRun ? "Dry run\u2026" : "Cleaning\u2026", COLORS.warn);
    try {
      const report = await clean(scanResult.items, {
        dryRun,
        yes: true,
        includeOptional: cleanMode === "deep",
        includeVolumes: true,
        volumePaths: [...selectedVols],
        cleanMode,
      });
      const label = dryRun
        ? `Dry run \u00b7 would free ${bytesHuman(report.freedBytes)}`
        : `Clean complete \u00b7 freed ${bytesHuman(report.freedBytes)}`;
      setStatus(label, COLORS.ok);
      renderDone(label);
      if (!dryRun) scanResult = null;
    } catch (e) {
      setStatus(`Clean failed: ${String(e)}`, COLORS.danger);
    } finally {
      busy = false;
    }
  }

  renderHome();

  renderer.keyInput.on("keypress", (key: { name?: string; sequence?: string }) => {
    if (busy) return;
    const k = (key.name || "").toLowerCase();

    if (k === "q" || k === "escape") {
      if (screen !== "home" && k === "escape") {
        renderHome();
        return;
      }
      if (k === "q") {
        renderer.destroy();
      }
      return;
    }

    if (screen === "home") {
      if (k === "up" || k === "k") {
        modeCursor = 0;
        cleanMode = "normal";
        renderHome();
        return;
      }
      if (k === "down" || k === "j") {
        modeCursor = 1;
        cleanMode = "deep";
        renderHome();
        return;
      }
      if (k === "1") {
        modeCursor = 0;
        cleanMode = "normal";
        renderHome();
        return;
      }
      if (k === "2") {
        modeCursor = 1;
        cleanMode = "deep";
        renderHome();
        return;
      }
      if (k === "return" || k === "enter") {
        void (async () => {
          setStatus("Loading volumes\u2026");
          await loadVolumes();
          renderVolumes();
        })();
        return;
      }
      return;
    }

    if (screen === "volumes") {
      if (k === "up" || k === "k") {
        volCursor = Math.max(0, volCursor - 1);
        renderVolumes();
        return;
      }
      if (k === "down" || k === "j") {
        volCursor = Math.min(Math.max(0, volumes.length - 1), volCursor + 1);
        renderVolumes();
        return;
      }
      if (k === "space") {
        const v = volumes[volCursor];
        if (v) {
          if (selectedVols.has(v.path)) selectedVols.delete(v.path);
          else selectedVols.add(v.path);
          renderVolumes();
        }
        return;
      }
      if (k === "a") {
        selectedVols = new Set(volumes.map((v) => v.path));
        renderVolumes();
        return;
      }
      if (k === "n") {
        selectedVols = new Set();
        renderVolumes();
        return;
      }
      if (k === "return" || k === "enter" || k === "s") {
        void doScan();
        return;
      }
      if (k === "c") {
        void doClean(false);
        return;
      }
      if (k === "d") {
        void doClean(true);
        return;
      }
      const num = parseInt(k, 10);
      if (num >= 1 && num <= 9 && volumes[num - 1]) {
        const v = volumes[num - 1]!;
        if (selectedVols.has(v.path)) selectedVols.delete(v.path);
        else selectedVols.add(v.path);
        volCursor = num - 1;
        renderVolumes();
        return;
      }
      return;
    }

    if (screen === "scan" || screen === "done") {
      if (k === "c") {
        void doClean(false);
        return;
      }
      if (k === "d") {
        void doClean(true);
        return;
      }
      if (k === "s") {
        void doScan();
        return;
      }
      if (k === "v") {
        void (async () => {
          if (volumes.length === 0) await loadVolumes();
          renderVolumes();
        })();
        return;
      }
      if (k === "h" || k === "home") {
        renderHome();
        return;
      }
    }
  });
}

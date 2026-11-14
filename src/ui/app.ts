/**
 * Lustr OpenTUI dashboard
 * Premium interactive cleaner using @opentui/core
 */

import {
  createCliRenderer,
  BoxRenderable,
  TextRenderable,
  type CliRenderer,
} from "@opentui/core";
import { scan } from "../engine/scan";
import { clean } from "../engine/clean";
import { bytesHuman } from "../utils/size";
import type { ScanResult, ScanItem } from "../engine/types";

type Screen = "home" | "scan" | "clean" | "done";

const COLORS = {
  bg: "#0B0F14",
  panel: "#12181F",
  accent: "#5EEAD4",
  muted: "#64748B",
  text: "#E2E8F0",
  warn: "#FBBF24",
  danger: "#F87171",
  ok: "#34D399",
};

export async function runTui() {
  const renderer = await createCliRenderer({
    exitOnCtrlC: true,
    backgroundColor: COLORS.bg,
  });

  let screen: Screen = "home";
  let scanResult: ScanResult | null = null;
  let statusMsg = "Ready";
  let selected = 0;

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
    content: "  [s] scan  [c] clean  [d] dry-run  [q] quit",
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

  function renderHome() {
    body.content = [
      "",
      "  A premium terminal cleaner for macOS.",
      "  Deep-cleans caches, logs, developer junk, and external volume trash.",
      "",
      "  Safety model:",
      "    • Allow-list only — never Documents, Photos, Mail, Keychains",
      "    • Preview with scan / dry-run before any delete",
      "    • External drives: empties .Trashes when mounted",
      "",
      "  Press s to scan, c to clean, d for dry-run.",
    ].join("\n");
    status.content = `  ${statusMsg}`;
  }

  function renderScan() {
    if (!scanResult) {
      body.content = "\n  Scanning…";
      return;
    }
    const lines = [
      "",
      `  Reclaimable: ${bytesHuman(scanResult.totalBytes)}  ·  ${scanResult.items.length} items`,
      `  Volumes: ${scanResult.volumes.map((v) => v.name).join(", ")}`,
      "",
    ];
    const top = scanResult.items.slice(0, 18);
    for (const item of top) {
      const mark = item.volume === "/" ? "·" : "⏏";
      lines.push(
        `  ${mark} ${item.name.padEnd(42).slice(0, 42)} ${bytesHuman(item.bytes).padStart(10)}  ${item.category}`,
      );
    }
    if (scanResult.items.length > 18) {
      lines.push(`  … and ${scanResult.items.length - 18} more`);
    }
    body.content = lines.join("\n");
    status.content = `  Scan complete · ${bytesHuman(scanResult.totalBytes)} reclaimable`;
  }

  function renderDone(msg: string) {
    body.content = `\n  ${msg}\n`;
    status.content = `  ${statusMsg}`;
  }

  async function doScan() {
    statusMsg = "Scanning home + external volumes…";
    status.content = `  ${statusMsg}`;
    statusMsg = "Scanning…";
    scanResult = await scan({ includeVolumes: true, includeOptional: false });
    screen = "scan";
    renderScan();
  }

  async function doClean(dryRun: boolean) {
    if (!scanResult) {
      await doScan();
    }
    if (!scanResult || scanResult.totalBytes === 0) {
      statusMsg = "Nothing to clean";
      renderDone("Already clean.");
      return;
    }
    statusMsg = dryRun ? "Dry run…" : "Cleaning…";
    status.content = `  ${statusMsg}`;
    const report = await clean(scanResult.items, {
      dryRun,
      yes: true,
      includeOptional: false,
      includeVolumes: true,
    });
    statusMsg = dryRun
      ? `Would free ${bytesHuman(report.freedBytes)}`
      : `Freed ${bytesHuman(report.freedBytes)}`;
    screen = "done";
    renderDone(
      dryRun
        ? `Dry run complete — would free ${bytesHuman(report.freedBytes)}`
        : `Clean complete — freed ${bytesHuman(report.freedBytes)}`,
    );
  }

  renderHome();

  renderer.keyInput.on("keypress", (key) => {
    const k = (key.name || "").toLowerCase();
    if (k === "q" || k === "escape") {
      renderer.destroy();
      return;
    }
    if (k === "s") {
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
    if (k === "h" || k === "home") {
      screen = "home";
      renderHome();
    }
  });
}

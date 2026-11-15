#!/usr/bin/env bun
/**
 * Lustr 2.0 — premium macOS cleaner
 * OpenTUI interactive UI + deep clean engine (home + external volumes)
 */

import { scan } from "./engine/scan";
import { clean } from "./engine/clean";
import { bytesHuman } from "./utils/size";
import type { CleanMode } from "./engine/types";

const VERSION = "2.0.0";

function printHelp() {
  console.log(`
  Lustr v${VERSION}  —  polish your Mac. Keep what matters.

  Usage
    lustr                 Interactive OpenTUI dashboard
    lustr scan            Scan reclaimable junk (home + volumes)
    lustr clean           Deep clean (asks first)
    lustr clean --dry-run Preview only
    lustr clean -y        Clean without prompts
    lustr help            This help
    lustr version         Print version

  Modes
    (default)             Normal clean — everyday caches & logs
    --deep                Deep clean — all junk targets + volume indexes

  Options
    -n, --dry-run         Never delete
    -y, --yes             Skip confirmation
    --deep                Use deep clean target set
    --include-optional    Include Archives / optional volume indexes
    --no-volumes          Skip external drives

  Safety
    Allow-list only. Documents, Photos, Mail, Messages, Keychains
    and app preferences are never touched.
`);
}

async function main() {
  const args = process.argv.slice(2);
  const flags = new Set(args.filter((a) => a.startsWith("-")));
  const cmd = args.find((a) => !a.startsWith("-")) ?? "";

  const dryRun = flags.has("-n") || flags.has("--dry-run");
  const yes = flags.has("-y") || flags.has("--yes");
  const deep = flags.has("--deep");
  const includeOptional = flags.has("--include-optional") || deep;
  const includeVolumes = !flags.has("--no-volumes");
  const cleanMode: CleanMode = deep ? "deep" : "normal";

  if (flags.has("-h") || flags.has("--help") || cmd === "help") {
    printHelp();
    return;
  }
  if (flags.has("-V") || flags.has("--version") || cmd === "version") {
    console.log(`Lustr ${VERSION}`);
    return;
  }

  if (!cmd || cmd === "menu" || cmd === "ui" || cmd === "tui") {
    try {
      const { runTui } = await import("./ui/app");
      await runTui();
    } catch (err) {
      console.error("TUI failed to start (OpenTUI native bindings required on macOS).");
      console.error("Falling back to CLI scan.\n");
      console.error(String(err));
      const result = await scan({ includeVolumes, includeOptional, cleanMode });
      console.log(`Mode: ${cleanMode}`);
      console.log(`Total reclaimable: ${bytesHuman(result.totalBytes)}`);
      for (const item of result.items.slice(0, 25)) {
        console.log(`  ${bytesHuman(item.bytes).padStart(10)}  ${item.name}`);
      }
    }
    return;
  }

  if (cmd === "scan") {
    console.log(`Scanning (${cleanMode})…`);
    const result = await scan({ includeVolumes, includeOptional, cleanMode });
    console.log(
      `\nReclaimable: ${bytesHuman(result.totalBytes)} across ${result.items.length} items [${cleanMode}]\n`,
    );
    for (const item of result.items) {
      const vol = item.volume === "/" ? "" : ` [${item.volume}]`;
      const star = item.depth === "deep" ? " ★" : "";
      console.log(`  ${bytesHuman(item.bytes).padStart(10)}  ${item.name}${vol}${star}`);
    }
    console.log();
    return;
  }

  if (cmd === "clean") {
    console.log(`Scanning (${cleanMode})…`);
    const result = await scan({ includeVolumes, includeOptional, cleanMode });
    if (result.totalBytes === 0) {
      console.log("Already clean — nothing to do.");
      return;
    }
    console.log(
      `\nWould reclaim ~${bytesHuman(result.totalBytes)} (${result.items.length} items) [${cleanMode}]\n`,
    );
    for (const item of result.items.slice(0, 20)) {
      console.log(`  ${bytesHuman(item.bytes).padStart(10)}  ${item.name}`);
    }
    if (result.items.length > 20) console.log(`  … +${result.items.length - 20} more`);

    if (dryRun) {
      console.log("\nDry run — nothing deleted.");
      return;
    }

    if (!yes) {
      console.log("\nThis permanently deletes caches, logs, and Trash contents.");
      console.log("Documents, Photos, Mail, Keychains are never touched.");
      const readline = await import("node:readline");
      const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
      const answer = await new Promise<string>((resolve) => {
        rl.question("Proceed? [y/N] ", resolve);
      });
      rl.close();
      if (!/^y(es)?$/i.test(answer.trim())) {
        console.log("Cancelled.");
        return;
      }
    }

    console.log("\nCleaning…");
    const report = await clean(result.items, {
      dryRun: false,
      yes: true,
      includeOptional,
      includeVolumes,
      cleanMode,
    });
    console.log(`\nFreed ~${bytesHuman(report.freedBytes)} [${report.mode}]`);
    for (const i of report.items.filter((x) => x.status === "done")) {
      console.log(`  ✓ ${i.name}  ${bytesHuman(i.bytes)}`);
    }
    return;
  }

  console.error(`Unknown command: ${cmd}`);
  printHelp();
  process.exit(1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

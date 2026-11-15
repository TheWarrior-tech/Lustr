/** Shared types for Lustr clean engine */

export type Category =
  | "Caches"
  | "Logs"
  | "Trash"
  | "Developer"
  | "Dev Tools"
  | "Browsers"
  | "Apps"
  | "System"
  | "Volumes";

/** normal = everyday safe junk; deep = aggressive but still allow-listed */
export type CleanMode = "normal" | "deep";

export interface CleanTarget {
  id: string;
  name: string;
  category: Category;
  /** Absolute path or template with {home} / {volume} */
  path: string;
  /** How to clean: wipe contents, remove path, or run a command */
  mode: "contents" | "remove" | "command";
  /** Optional shell command (preferred when available) */
  command?: string;
  /** Only on external volumes when true */
  volumeOnly?: boolean;
  /** Opt-in (e.g. Archives) — included automatically in deep mode */
  optional?: boolean;
  /** Estimated risk: low = always safe, medium = regenerable but costly */
  risk: "low" | "medium";
  /**
   * Minimum mode required.
   * normal → always available
   * deep → only when deep mode is selected
   */
  depth?: CleanMode;
}

export interface ScanItem {
  id: string;
  name: string;
  category: Category;
  path: string;
  bytes: number;
  volume: string; // "/" for internal, mount path for external
  optional?: boolean;
  risk: "low" | "medium";
  depth?: CleanMode;
}

export interface ScanResult {
  items: ScanItem[];
  totalBytes: number;
  volumes: VolumeInfo[];
  scannedAt: string;
  mode: CleanMode;
}

export interface VolumeInfo {
  path: string;
  name: string;
  freeBytes: number;
  totalBytes: number;
  isInternal: boolean;
  isExternal: boolean;
}

export interface CleanOptions {
  dryRun: boolean;
  yes: boolean;
  includeOptional: boolean;
  /** Limit to specific target ids */
  only?: string[];
  /** Include external volumes (legacy) */
  includeVolumes: boolean;
  /** Preferred: explicit volume paths to clean ("/" = home/internal) */
  volumePaths?: string[];
  /** normal | deep */
  cleanMode: CleanMode;
}

export interface CleanReport {
  freedBytes: number;
  items: { id: string; name: string; bytes: number; status: "done" | "dry" | "skip" | "fail" }[];
  dryRun: boolean;
  mode: CleanMode;
}

export interface ScanOptions {
  includeVolumes?: boolean;
  includeOptional?: boolean;
  /** Restrict to these volume roots; "/" = internal/home */
  volumePaths?: string[];
  cleanMode?: CleanMode;
}

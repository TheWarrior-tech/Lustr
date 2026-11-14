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
  /** Opt-in (e.g. Archives) */
  optional?: boolean;
  /** Estimated risk: low = always safe, medium = regenerable but costly */
  risk: "low" | "medium";
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
}

export interface ScanResult {
  items: ScanItem[];
  totalBytes: number;
  volumes: VolumeInfo[];
  scannedAt: string;
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
  /** Include external volumes */
  includeVolumes: boolean;
}

export interface CleanReport {
  freedBytes: number;
  items: { id: string; name: string; bytes: number; status: "done" | "dry" | "skip" | "fail" }[];
  dryRun: boolean;
}

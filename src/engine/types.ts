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
  path: string;
  mode: "contents" | "remove" | "command";
  command?: string;
  volumeOnly?: boolean;
  optional?: boolean;
  risk: "low" | "medium";
}

export interface ScanItem {
  id: string;
  name: string;
  category: Category;
  path: string;
  bytes: number;
  volume: string;
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
  only?: string[];
  includeVolumes: boolean;
}

export interface CleanReport {
  freedBytes: number;
  items: { id: string; name: string; bytes: number; status: "done" | "dry" | "skip" | "fail" }[];
  dryRun: boolean;
}

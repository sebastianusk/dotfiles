import { homedir } from "node:os";
import { resolve } from "node:path";

export type HermesMemoryConfig = {
  dataPath: string;
  reviewEveryTurns: number;
  idleDebounceMs: number;
  reviewMinIntervalMs: number;
  ollamaUrl: string;
  ollamaModel: string;
  minConfidence: number;
  maxTranscriptChars: number;
  reviewRetryMs: number;
  userCharLimit: number;
  globalCharLimit: number;
  projectCharLimit: number;
};

const defaults: HermesMemoryConfig = {
  dataPath: "~/.local/share/opencode/hermes-memory",
  reviewEveryTurns: 10,
  idleDebounceMs: 10_000,
  reviewMinIntervalMs: 1_800_000,
  ollamaUrl: "http://127.0.0.1:11434",
  ollamaModel: "qwen3:14b",
  minConfidence: 0.9,
  maxTranscriptChars: 12_000,
  reviewRetryMs: 300_000,
  userCharLimit: 1375,
  globalCharLimit: 2200,
  projectCharLimit: 3000,
};

export function parseConfig(raw: string): HermesMemoryConfig {
  const parsed = JSON.parse(raw.replace(/^\s*\/\/.*$/gm, "")) as Partial<HermesMemoryConfig>;
  const config: HermesMemoryConfig = { ...defaults, ...parsed };
  for (const key of ["reviewEveryTurns", "idleDebounceMs", "reviewMinIntervalMs", "reviewRetryMs", "maxTranscriptChars", "userCharLimit", "globalCharLimit", "projectCharLimit"] as const) {
    if (!Number.isInteger(config[key]) || config[key] <= 0) throw new Error(`${key} must be a positive integer.`);
  }
  if (!Number.isFinite(config.minConfidence) || config.minConfidence < 0 || config.minConfidence > 1) throw new Error("minConfidence must be between 0 and 1.");
  const url = new URL(config.ollamaUrl);
  if (url.protocol !== "http:") throw new Error("ollamaUrl must use http.");
  if (!new Set(["127.0.0.1", "localhost", "::1"]).has(url.hostname.replace(/^\[|\]$/g, ""))) throw new Error("ollamaUrl must be loopback.");
  if (!config.ollamaModel.trim()) throw new Error("ollamaModel must not be empty.");
  config.dataPath = expandHome(config.dataPath);
  return config;
}

export function expandHome(path: string): string {
  return path === "~" ? homedir() : path.startsWith("~/") ? resolve(homedir(), path.slice(2)) : resolve(path);
}

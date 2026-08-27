import { homedir } from "node:os";
import { lstat, readFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import type { ApprovalReviewConfig, RedactionConfigResult } from "./types.js";

const defaults = {
  dataPath: "~/.local/share/opencode/approval-review",
  retentionDays: 90,
  promotablePermissions: [] as string[],
};

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    && Object.getPrototypeOf(value) === Object.prototype;
}

function stripComments(raw: string): string {
  return raw.replace(/^\s*\/\/.*$/gm, "");
}

function stringArray(value: unknown, key: string): string[] {
  if (!Array.isArray(value) || value.some((entry) => typeof entry !== "string")) {
    throw new Error(`${key} must be an array of strings.`);
  }
  return value;
}

export function parseConfig(raw: string): ApprovalReviewConfig {
  const parsed: unknown = JSON.parse(stripComments(raw));
  if (!isPlainObject(parsed)) throw new Error("configuration object must be a non-null plain object.");
  const dataPath = parsed.dataPath === undefined ? defaults.dataPath : parsed.dataPath;
  const retentionDays = parsed.retentionDays === undefined ? defaults.retentionDays : parsed.retentionDays;
  const promotablePermissions = parsed.promotablePermissions === undefined
    ? defaults.promotablePermissions
    : stringArray(parsed.promotablePermissions, "promotablePermissions");
  if (typeof dataPath !== "string" || !dataPath.trim()) throw new Error("dataPath must not be empty.");
  if (typeof retentionDays !== "number" || !Number.isInteger(retentionDays) || retentionDays <= 0) {
    throw new Error("retentionDays must be a positive integer.");
  }
  return {
    dataPath: expandHome(dataPath),
    retentionDays,
    promotablePermissions,
  };
}

export function expandHome(path: string): string {
  return path === "~" ? homedir() : path.startsWith("~/") ? resolve(homedir(), path.slice(2)) : resolve(path);
}

export function getVibeguardConfigCandidates(
  directory: string,
  environment: Record<string, string | undefined> = process.env,
): string[] {
  const projectDirectory = resolve(directory);
  const candidates = [
    join(projectDirectory, "vibeguard.config.json"),
    join(projectDirectory, ".opencode", "vibeguard.config.json"),
    join(homedir(), ".config", "opencode", "vibeguard.config.json"),
  ];
  const configured = environment.OPENCODE_VIBEGUARD_CONFIG;
  return configured ? [resolve(projectDirectory, configured), ...candidates] : candidates;
}

export async function loadVibeguardRedactionConfig(
  directory: string,
  environment: Record<string, string | undefined> = process.env,
): Promise<RedactionConfigResult> {
  for (const source of getVibeguardConfigCandidates(directory, environment)) {
    try {
      await lstat(source);
    } catch (error) {
      if (isMissingFile(error)) continue;
      return { status: "invalid", source, reason: error instanceof Error ? error.message : "configuration is unavailable." };
    }
    try {
      const raw: unknown = JSON.parse(await readFile(source, "utf8"));
      return compileVibeguardRedactionConfig(raw, source);
    } catch (error) {
      return { status: "invalid", source, reason: error instanceof Error ? error.message : "invalid JSON" };
    }
  }
  return { status: "absent", reason: "No Vibeguard configuration was found." };
}

export function compileVibeguardRedactionConfig(raw: unknown, source = "<inline>"): RedactionConfigResult {
  if (!isPlainObject(raw)) return { status: "invalid", source, reason: "configuration must be an object." };
  if (typeof raw.enabled !== "boolean") return { status: "invalid", source, reason: "enabled must be a boolean." };
  if (!raw.enabled) return { status: "disabled", source, reason: "Vibeguard is disabled." };
  if (!isPlainObject(raw.patterns)) return { status: "invalid", source, reason: "patterns must be an object." };

  const regexRules = raw.patterns.regex;
  const keywordRules = raw.patterns.keywords;
  if (regexRules !== undefined && !Array.isArray(regexRules)) {
    return { status: "invalid", source, reason: "patterns.regex must be an array." };
  }
  if (keywordRules !== undefined && !Array.isArray(keywordRules)) {
    return { status: "invalid", source, reason: "patterns.keywords must be an array." };
  }

  try {
    const patterns: RegExp[] = [];
    for (const rule of regexRules ?? []) {
      if (!isPlainObject(rule) || typeof rule.pattern !== "string" || !rule.pattern.trim()) {
        throw new Error("patterns.regex contains a malformed or blank entry.");
      }
      const { pattern, flags } = peelInlineFlags(rule.pattern, rule.flags);
      patterns.push(makeGlobalRegExp(pattern, flags));
    }
    for (const rule of keywordRules ?? []) {
      if (!isPlainObject(rule) || typeof rule.value !== "string" || !rule.value.trim()) {
        throw new Error("patterns.keywords contains a malformed or blank entry.");
      }
      patterns.push(makeGlobalRegExp(escapeRegExp(rule.value), ""));
    }
    if (patterns.length === 0) throw new Error("patterns.regex and patterns.keywords must not both be blank.");
    return { status: "ready", source, patterns };
  } catch (error) {
    return { status: "invalid", source, reason: error instanceof Error ? error.message : "invalid pattern" };
  }
}

function peelInlineFlags(pattern: string, rawFlags: unknown): { pattern: string; flags: string } {
  let remaining = pattern;
  let flags = typeof rawFlags === "string" ? rawFlags : "";
  while (remaining.startsWith("(?i)") || remaining.startsWith("(?m)")) {
    const inlineFlag = remaining.slice(2, 3);
    remaining = remaining.slice(4);
    if (!flags.includes(inlineFlag)) flags += inlineFlag;
  }
  return { pattern: remaining, flags };
}

function makeGlobalRegExp(pattern: string, flags: string): RegExp {
  const normalizedFlags = flags.replace("y", "").includes("g") ? flags.replace("y", "") : `${flags.replace("y", "")}g`;
  return new RegExp(pattern, normalizedFlags);
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function isMissingFile(error: unknown): boolean {
  return typeof error === "object" && error !== null && "code" in error && error.code === "ENOENT";
}

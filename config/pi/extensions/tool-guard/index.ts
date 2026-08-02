import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { homedir } from "node:os";

// ── YAML helpers (minimal parser for tool-guard.yaml format) ────

interface GuardConfig {
  safe: string[];
  blocked: string[];
}

function parseYaml(text: string): GuardConfig {
  const config: GuardConfig = { safe: [], blocked: [] };
  let section: "safe" | "blocked" | null = null;

  for (const line of text.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;

    if (/^(safe|blocked):/.test(trimmed)) {
      section = trimmed.startsWith("safe") ? "safe" : "blocked";
      continue;
    }

    if (section && trimmed.startsWith("- ")) {
      const pattern = trimmed.slice(2).trim();
      if (pattern) config[section].push(pattern);
    }
  }

  return config;
}

function serializeYaml(config: GuardConfig): string {
  const lines: string[] = [];
  lines.push("safe:");
  for (const p of config.safe) lines.push(`  - ${p}`);
  lines.push("");
  lines.push("blocked:");
  for (const p of config.blocked) lines.push(`  - ${p}`);
  return lines.join("\n") + "\n";
}

// ── Pattern matching (prefix / contains / exact) ──────────

function matchPattern(cmd: string, pattern: string): boolean {
  if (pattern.startsWith("*")) {
    // Contains match — substring appears anywhere
    return cmd.includes(pattern.slice(1));
  }
  if (pattern.startsWith("=")) {
    // Exact match
    return cmd === pattern.slice(1);
  }
  // Prefix match with word boundary
  return cmd === pattern || cmd.startsWith(pattern + " ");
}

function matchesAny(cmd: string, patterns: string[]): boolean {
  return patterns.some((p) => matchPattern(cmd, p));
}

// ── Config loading ────────────────────────────────────────

function loadGuardFile(path: string): GuardConfig | null {
  try {
    if (existsSync(path)) return parseYaml(readFileSync(path, "utf-8"));
  } catch { /* skip */ }
  return null;
}

function loadConfig(projectDir: string): GuardConfig {
  const global = loadGuardFile(join(homedir(), ".pi", "tool-guard.yaml"));
  const project = loadGuardFile(join(projectDir, ".pi", "tool-guard.yaml"));
  return {
    safe: [...(global?.safe ?? []), ...(project?.safe ?? [])],
    blocked: [...(global?.blocked ?? []), ...(project?.blocked ?? [])],
  };
}

// ── Write "always allow" back to YAML ─────────────────────

function appendToGuard(path: string, pattern: string, section: "safe" | "blocked") {
  try {
    mkdirSync(dirname(path), { recursive: true });
    let config: GuardConfig;
    if (existsSync(path)) {
      config = parseYaml(readFileSync(path, "utf-8"));
    } else {
      config = { safe: [], blocked: [] };
    }
    if (!config[section].includes(pattern)) {
      config[section].push(pattern);
    }
    writeFileSync(path, serializeYaml(config), "utf-8");
  } catch { /* best effort */ }
}

// ── Normalization ─────────────────────────────────────────

function normalize(cmd: string): string {
  return cmd.trim().replace(/\s+/g, " ");
}

// ── Extension ─────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  let config: GuardConfig = { safe: [], blocked: [] };
  let projectDir = process.cwd();

  function reloadConfig(cwd?: string) {
    if (cwd) projectDir = cwd;
    config = loadConfig(projectDir);
  }

  pi.on("session_start", (_event, ctx) => {
    reloadConfig(ctx.cwd);
  });

  pi.registerCommand("tool-guard-reload", {
    description: "Reload tool-guard config from YAML",
    handler: async (_args, ctx) => {
      reloadConfig(ctx.cwd);
      ctx.ui.notify(
        `Tool guard: ${config.safe.length} safe, ${config.blocked.length} blocked`,
        "info",
      );
    },
  });

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;

    const raw = event.input?.command;
    if (!raw || typeof raw !== "string") return;

    const cmd = normalize(raw);

    // Always write "always allow" to project-level guard file.
    // Global guard is for defaults managed via dotfiles, not session approvals.
    const guardFile = join(projectDir, ".pi", "tool-guard.yaml");

    // Auto-approve
    if (matchesAny(cmd, config.safe)) return;

    // Auto-block
    if (matchesAny(cmd, config.blocked)) {
      if (!ctx.hasUI) {
        return { block: true, reason: "Blocked command (non-interactive)" };
      }
      ctx.ui.notify(`Auto-blocked: ${cmd.slice(0, 100)}`, "error");
      return { block: true, reason: "Blocked by tool-guard.yaml" };
    }

    // Non-interactive: block unknowns
    if (!ctx.hasUI) {
      return {
        block: true,
        reason: `Command blocked in non-interactive mode: ${cmd.slice(0, 100)}`,
      };
    }

    // ── Prompt user ────────────────────────────────────────
    const label = cmd.length > 100 ? cmd.slice(0, 97) + "..." : cmd;

    const choice = await ctx.ui.select(
      "Allow bash command?",
      [
        "Allow once",
        "Always allow (save to tool-guard.yaml)",
        "Deny",
      ],
      `> ${label}`,
    );

    if (!choice || choice === "Deny") {
      return { block: true, reason: "Denied" };
    }

    if (choice.startsWith("Always")) {
      // Let user edit the pattern before saving
      const edited = await ctx.ui.editor(
        "Edit pattern before saving (Ctrl+G for external editor)",
        cmd,  // Pre-fill with the normalized command
      );
      if (edited && edited.trim()) {
        appendToGuard(guardFile, edited.trim(), "safe");
        reloadConfig();
      }
    }
  });

  pi.registerCommand("tool-guard-stats", {
    description: "Show tool-guard stats",
    handler: async (_args, ctx) => {
      ctx.ui.notify(
        `Tool guard — ${config.safe.length} safe patterns, ${config.blocked.length} blocked`,
        "info",
      );
    },
  });
}

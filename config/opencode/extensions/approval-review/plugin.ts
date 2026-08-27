import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { type Plugin } from "@opencode-ai/plugin";
import { loadVibeguardRedactionConfig, parseConfig } from "./lib/config.js";
import { createEventHook, createApprovalReviewTools, hashProject, resolveOpenCodeConfigPath } from "./lib/runtime.js";
import { ApprovalReviewStore } from "./lib/store.js";
import type { ApprovalReviewConfig } from "./lib/types.js";

const plugin: Plugin = async ({ directory, worktree }) => {
  const root = worktree ?? directory;
  const rawConfig = await readFile(join(homedir(), ".config", "opencode", "approval-review.jsonc"), "utf8");
  const config: ApprovalReviewConfig = parseConfig(rawConfig);
  const redaction = await loadVibeguardRedactionConfig(root);
  if (redaction.status !== "ready") {
    console.error(`[approval-review] redaction unavailable (${redaction.status}: ${redaction.reason}); decisions will not be recorded.`);
  }
  const store = new ApprovalReviewStore(config, redaction.status === "ready" ? redaction.patterns : undefined, hashProject(root));
  await store.initialize();

  return {
    event: createEventHook(store),
    tool: createApprovalReviewTools({
      store,
      configPath: resolveOpenCodeConfigPath(),
      promotablePermissions: config.promotablePermissions,
    }),
  };
};

export default plugin;

import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { tool, type Plugin } from "@opencode-ai/plugin";
import { MemorySessionInjector } from "./lib/context.js";
import { parseConfig } from "./lib/config.js";
import { reviewTranscript } from "./lib/ollama.js";
import { MemoryReviewScheduler } from "./lib/review.js";
import { MemoryStore } from "./lib/store.js";
import type { MemoryTarget } from "./lib/types.js";

const config = parseConfig(await readFile(join(homedir(), ".config", "opencode", "hermes-memory.jsonc"), "utf8"));
const store = new MemoryStore(config.dataPath, {
  userCharLimit: config.userCharLimit,
  globalCharLimit: config.globalCharLimit,
  projectCharLimit: config.projectCharLimit,
});
const scheduler = new MemoryReviewScheduler({
  store,
  reviewEveryTurns: config.reviewEveryTurns,
  minIntervalMs: config.reviewMinIntervalMs,
  minConfidence: config.minConfidence,
  maxTranscriptChars: config.maxTranscriptChars,
});
const injector = new MemorySessionInjector();
const reviewTimers = new Map<string, ReturnType<typeof setTimeout>>();

const targetSchema = tool.schema.enum(["user", "memory", "project"]);

const plugin: Plugin = async ({ directory, worktree, client }) => {
  await store.initialize();
  const projectId = hashProject(worktree ?? directory);
  const review = (transcript: string) => reviewTranscript({ baseUrl: config.ollamaUrl, model: config.ollamaModel, transcript });
  const scheduleReview = (sessionID: string, delay = config.idleDebounceMs) => {
    const previous = reviewTimers.get(sessionID);
    if (previous) clearTimeout(previous);
    reviewTimers.set(sessionID, setTimeout(() => {
      reviewTimers.delete(sessionID);
      void runReview(sessionID);
    }, delay));
  };
  const runReview = async (sessionID: string) => {
    try {
      const staged = await scheduler.reviewIfDue(sessionID, review);
      if (staged) await client.tui.showToast({ body: { title: "Memory Proposals Ready", message: `${staged} proposal${staged === 1 ? "" : "s"} staged for review.`, variant: "success", duration: 5000 } });
      const delay = scheduler.nextReviewDelay(sessionID);
      if (delay !== undefined) scheduleReview(sessionID, delay);
    } catch (error) {
      reportReviewFailure(client, error);
      if (scheduler.nextReviewDelay(sessionID) !== undefined) scheduleReview(sessionID, config.reviewRetryMs);
    }
  };

  return {
    tool: {
      memory_search: tool({
        description: "Search approved Hermes-style memory. Use for durable user, global, or project facts; use ctx_search for session history.",
        args: { query: tool.schema.string().min(1), target: targetSchema.optional() },
        async execute(args) {
          const targets = args.target ? [args.target] : ["user", "memory", "project"] as const;
          const query = args.query.toLowerCase();
          const result = await Promise.all(targets.map(async (target) => ({
            target,
            entries: (await store.read(target, target === "project" ? projectId : undefined)).filter((entry) => entry.toLowerCase().includes(query)),
          })));
          return JSON.stringify(result.filter((item) => item.entries.length));
        },
      }),
      memory_add: tool({
        description: "Propose a durable memory entry. The proposal is staged and requires explicit user approval.",
        args: { target: targetSchema, content: tool.schema.string().min(1).max(500) },
        async execute(args, context) {
          const pending = await store.stage({
            operation: "add",
            target: args.target,
            projectId: args.target === "project" ? projectId : undefined,
            content: args.content,
            sourceSessionIds: [context.sessionID],
            sourceMessageIds: [context.messageID],
            confidence: 1,
          });
          return `Memory proposal ${pending.id} staged. Use memory_review to approve or reject it.`;
        },
      }),
      memory_replace: mutationTool("replace", projectId),
      memory_remove: mutationTool("remove", projectId),
      memory_review: tool({
        description: "List and explicitly approve or reject staged memory proposals.",
        args: { action: tool.schema.enum(["list", "approve", "reject"]), id: tool.schema.string().uuid().optional() },
        async execute(args, context) {
          if (args.action === "list") return JSON.stringify((await store.listPending()).map(reviewSummary));
          if (!args.id) throw new Error("memory_review approve/reject requires an id.");
          if (args.action === "approve") {
            await context.ask({
              permission: "hermes-memory-approval",
              patterns: [args.id],
              always: [],
              metadata: { proposal: (await store.listPending()).find((pending) => pending.id === args.id) },
            });
            return JSON.stringify(reviewSummary(await store.approve(args.id)));
          }
          await context.ask({
            permission: "hermes-memory-approval",
            patterns: [args.id],
            always: [],
            metadata: { proposal: (await store.listPending()).find((pending) => pending.id === args.id) },
          });
          await store.reject(args.id);
          return `Memory proposal ${args.id} rejected.`;
        },
      }),
    },
    "experimental.chat.system.transform": async (input, output) => {
      const sessionID = input.sessionID;
      if (!sessionID) return;
      const context = await injector.load(sessionID, async () => ({
        user: await store.read("user"),
        global: await store.read("memory"),
        project: await store.read("project", projectId),
        pendingCount: (await store.listPending()).length,
      }));
      if (context) output.system.push(context);
    },
    "chat.message": async (input, output) => {
      const text = output.parts.filter((part) => part.type === "text").map((part) => part.text).join("\n").trim();
      if (!text) return;
      await scheduler.recordTurn({ sessionID: input.sessionID, messageID: input.messageID ?? output.message.id, projectId, text });
      scheduleReview(input.sessionID);
    },
    "experimental.session.compacting": async (input) => {
      const timer = reviewTimers.get(input.sessionID);
      if (timer) clearTimeout(timer);
      reviewTimers.delete(input.sessionID);
      await scheduler.flush(input.sessionID, review).catch((error) => {
        reportReviewFailure(client, error);
        scheduleReview(input.sessionID, config.reviewRetryMs);
      });
    },
  };
};

function mutationTool(operation: "replace" | "remove", projectId: string) {
  return tool({
    description: `Propose a memory ${operation}. The change is staged and requires explicit user approval.`,
    args: {
      target: targetSchema,
      previousContent: tool.schema.string().min(1).max(500),
      content: tool.schema.string().min(1).max(500).optional(),
    },
    async execute(args, context) {
      if (operation === "replace" && !args.content) throw new Error("memory_replace requires content.");
      const pending = await store.stage({
        operation,
        target: args.target as MemoryTarget,
        projectId: args.target === "project" ? projectId : undefined,
        content: args.content ?? args.previousContent,
        previousContent: args.previousContent,
        sourceSessionIds: [context.sessionID],
        sourceMessageIds: [context.messageID],
        confidence: 1,
      });
      return `Memory proposal ${pending.id} staged. Use memory_review to approve or reject it.`;
    },
  });
}

function hashProject(directory: string): string {
  return createHash("sha256").update(directory).digest("hex").slice(0, 16);
}

export default plugin;

function reportReviewFailure(client: Parameters<Plugin>[0]["client"], error: unknown): void {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`[hermes-memory] local review failed: ${message}`);
  void client.tui.showToast({
    body: { title: "Memory Review Failed", message: "No memory was written. Review will retry while the session remains active.", variant: "error", duration: 5000 },
  }).catch(() => undefined);
}

function reviewSummary(pending: Awaited<ReturnType<MemoryStore["listPending"]>>[number]) {
  return {
    id: pending.id,
    operation: pending.operation,
    target: pending.target,
    content: pending.content,
    previousContent: pending.previousContent,
    confidence: pending.confidence,
    createdAt: pending.createdAt,
  };
}

import { chmod, lstat, mkdir, readFile, readdir, rename, rm, rmdir, utimes, writeFile } from "node:fs/promises";
import { randomUUID } from "node:crypto";
import { join } from "node:path";
import type { ApprovalRecord, ApprovalReviewConfig, AskedPermission, PermissionReply, RecordAskedResult, ReviewDisposition, RuleApplication } from "./types.js";
import { redact } from "./redact.js";

const ID = /^[A-Za-z0-9_-]+$/;
const REPLIES = new Set<PermissionReply>(["once", "always", "reject"]);

export type LockedApprovalReviewStore = {
  setDisposition(ids: string[], disposition: Exclude<ReviewDisposition, "unreviewed">, capability?: RuleApplication): Promise<void>;
};

export type ApprovalReviewStoreOptions = {
  now?: () => number;
  onStaleLockRecovered?: () => Promise<void> | void;
};

export class ApprovalReviewStore {
  private queue: Promise<void> = Promise.resolve();

  constructor(
    private readonly config: ApprovalReviewConfig,
    private readonly patterns: RegExp[] | undefined,
    private readonly projectId = "unknown",
    private readonly options: ApprovalReviewStoreOptions = {},
  ) {}

  async initialize(): Promise<void> {
    await mkdir(join(this.config.dataPath, "records"), { recursive: true, mode: 0o700 });
    await chmod(this.config.dataPath, 0o700);
    await chmod(join(this.config.dataPath, "records"), 0o700);
  }

  async recordAsked(input: AskedPermission): Promise<RecordAskedResult> {
    this.validateId(input.id);
    if (!this.patterns) return { written: false, reason: "Effective Vibeguard redaction patterns are unavailable." };
    return this.exclusively(async () => {
      const values = [...input.patterns, ...input.always];
      const redactedValues = values.map((value) => redact(value, this.patterns!));
      const command = typeof input.metadata?.command === "string" ? redact(input.metadata.command, this.patterns!) : undefined;
      const record: ApprovalRecord = {
        id: input.id,
        permission: input.permission,
        patterns: redactedValues.slice(0, input.patterns.length),
        always: redactedValues.slice(input.patterns.length),
        ...(command === undefined ? {} : { command }),
        projectId: this.projectId,
        askedAt: new Date().toISOString(),
        disposition: "unreviewed",
        redacted: [...redactedValues, command ?? ""].some((value) => value.includes("[REDACTED]")),
      };
      await this.writeRecord(record);
      return { written: true };
    });
  }

  async recordReplied(id: string, reply: PermissionReply): Promise<void> {
    this.validateId(id);
    if (!REPLIES.has(reply)) return;
    await this.exclusively(async () => {
      const record = await this.load(id);
      if (!record || record.reply !== undefined) return;
      await this.writeRecord({ ...record, reply, repliedAt: new Date().toISOString() });
    });
  }

  async listReviewable(): Promise<ApprovalRecord[]> {
    return this.exclusively(async () => {
      return (await this.loadAll(true))
        .filter((record) => record.reply !== undefined && record.disposition === "unreviewed")
        .sort((a, b) => a.id.localeCompare(b.id));
    });
  }

  async beginReview(): Promise<ApprovalRecord[]> {
    return this.exclusively(async () => {
      const records = await this.loadAll(true);
      for (const record of records) {
        if (record.reply !== undefined && record.disposition === "deferred") {
          await this.writeRecord({ ...record, disposition: "unreviewed", dispositionAt: new Date().toISOString() });
        }
      }
      return (await this.loadAll()).filter((record) => record.reply !== undefined && record.disposition === "unreviewed").sort((a, b) => a.id.localeCompare(b.id));
    });
  }

  async setDisposition(ids: string[], disposition: Exclude<ReviewDisposition, "unreviewed">, capability?: RuleApplication): Promise<void> {
    if (disposition === "rule-applied" && capability?.ruleApplication !== true) throw new Error("rule application capability is required");
    ids.forEach((id) => this.validateId(id));
    await this.exclusively(() => this.setDispositionLocked(ids, disposition, capability));
  }

  async prune(now = new Date()): Promise<void> {
    await this.exclusively(async () => {
      const cutoff = now.getTime() - this.config.retentionDays * 24 * 60 * 60 * 1000;
      for (const record of await this.loadAll(true)) {
        const timestamps = [record.askedAt, record.repliedAt, record.dispositionAt].filter((value): value is string => typeof value === "string");
        if (Math.max(...timestamps.map((value) => Date.parse(value))) < cutoff) await rm(this.path(record.id), { force: true });
      }
    });
  }

  async withLock<T>(work: (locked: LockedApprovalReviewStore) => Promise<T>): Promise<T> {
    return this.fileLock(() => work({ setDisposition: (ids, disposition, capability) => this.setDispositionLocked(ids, disposition, capability) }));
  }

  private async exclusively<T>(work: () => Promise<T>): Promise<T> {
    const previous = this.queue;
    let release!: () => void;
    this.queue = new Promise<void>((resolve) => { release = resolve; });
    await previous;
    try { return await this.fileLock(work); } finally { release(); }
  }

  private async fileLock<T>(work: () => Promise<T>): Promise<T> {
    await this.initialize();
    const lock = join(this.config.dataPath, ".lock");
    const now = this.options.now ?? Date.now;
    const deadline = now() + 5_000;
    while (true) {
      if (now() >= deadline) throw new Error("Timed out waiting for approval review storage lock.");
      try {
        await mkdir(lock, { mode: 0o700 });
        let identity;
        try { identity = await lstat(lock); } catch (error) {
          if ((error as NodeJS.ErrnoException).code === "ENOENT") continue;
          throw error;
        }
        const heartbeat = setInterval(() => { void utimes(lock, new Date(), new Date()).catch(() => undefined); }, 10_000);
        return this.releaseLease(lock, identity, heartbeat, work);
      }
      catch (error) {
        if ((error as NodeJS.ErrnoException).code !== "EEXIST") throw error;
        try {
          if (now() >= deadline) throw new Error("Timed out waiting for approval review storage lock.");
          const observed = await lstat(lock);
          if (now() - observed.mtimeMs > 60_000) {
            if (now() >= deadline) throw new Error("Timed out waiting for approval review storage lock.");
            const current = await lstat(lock);
            if (current.dev !== observed.dev || current.ino !== observed.ino || now() - current.mtimeMs <= 60_000) continue;
            try { await rmdir(lock); } catch (recoveryError) {
              if ((recoveryError as NodeJS.ErrnoException).code === "ENOENT") continue;
              if ((recoveryError as NodeJS.ErrnoException).code !== "ENOTEMPTY") throw recoveryError;
              continue;
            }
            await this.options.onStaleLockRecovered?.();
            continue;
          }
        }
        catch { continue; }
        if (now() >= deadline) throw new Error("Timed out waiting for approval review storage lock.");
        await new Promise((resolve) => setTimeout(resolve, 25));
      }
    }
  }

  private async releaseLease<T>(lock: string, identity: { dev: number; ino: number }, heartbeat: ReturnType<typeof setInterval>, work: () => Promise<T>): Promise<T> {
    try { return await work(); }
    finally {
      clearInterval(heartbeat);
      try {
        const current = await lstat(lock);
        if (current.dev === identity.dev && current.ino === identity.ino) await rmdir(lock);
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
      }
    }
  }

  private async setDispositionLocked(ids: string[], disposition: Exclude<ReviewDisposition, "unreviewed">, capability?: RuleApplication): Promise<void> {
    if (disposition === "rule-applied" && capability?.ruleApplication !== true) throw new Error("rule application capability is required");
    ids.forEach((id) => this.validateId(id));
    for (const id of ids) {
      const record = await this.load(id);
      if (record?.reply !== undefined) await this.writeRecord({ ...record, disposition, dispositionAt: new Date().toISOString() });
    }
  }

  private validateId(id: string): void { if (typeof id !== "string" || !ID.test(id)) throw new Error("Invalid record id"); }
  private path(id: string): string { this.validateId(id); return join(this.config.dataPath, "records", `${id}.json`); }

  private async load(id: string): Promise<ApprovalRecord | undefined> {
    try {
      const value: unknown = JSON.parse(await readFile(this.path(id), "utf8"));
      return isApprovalRecord(value) && value.id === id ? value : undefined;
    } catch { return undefined; }
  }

  private async loadAll(removeInvalid = false): Promise<ApprovalRecord[]> {
    let names: string[];
    try { names = await readdir(join(this.config.dataPath, "records")); } catch (error) { if ((error as NodeJS.ErrnoException).code === "ENOENT") return []; throw error; }
    const files = names.filter((name) => name.endsWith(".json"));
    const records = await Promise.all(files.map(async (name) => {
      const record = await this.load(name.slice(0, -5));
      if (!record && removeInvalid) await rm(join(this.config.dataPath, "records", name), { force: true });
      return record;
    }));
    return records.filter((record): record is ApprovalRecord => record !== undefined);
  }

  private async writeRecord(record: ApprovalRecord): Promise<void> {
    const path = this.path(record.id);
    const temporary = `${path}.${randomUUID()}.tmp`;
    await writeFile(temporary, `${JSON.stringify(record, null, 2)}\n`, { mode: 0o600 });
    await chmod(temporary, 0o600);
    await rename(temporary, path);
  }
}

function isApprovalRecord(value: unknown): value is ApprovalRecord {
  if (!value || typeof value !== "object") return false;
  const record = value as Partial<ApprovalRecord>;
  return typeof record.id === "string" && ID.test(record.id) && typeof record.permission === "string" &&
    Array.isArray(record.patterns) && record.patterns.every((item) => typeof item === "string") &&
    Array.isArray(record.always) && record.always.every((item) => typeof item === "string") &&
    typeof record.projectId === "string" && isIsoTimestamp(record.askedAt) &&
    (record.repliedAt === undefined || isIsoTimestamp(record.repliedAt)) &&
    (record.dispositionAt === undefined || isIsoTimestamp(record.dispositionAt)) &&
    (record.reply === undefined || REPLIES.has(record.reply)) &&
    (record.disposition === "unreviewed" || record.disposition === "rule-applied" || record.disposition === "dismissed" || record.disposition === "deferred") &&
    typeof record.redacted === "boolean";
}

function isIsoTimestamp(value: unknown): value is string {
  return typeof value === "string" && Number.isFinite(Date.parse(value)) && new Date(value).toISOString() === value;
}

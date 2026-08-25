import { appendFile, chmod, mkdir, readFile, rename, rm, stat, writeFile } from "node:fs/promises";
import { createHash, randomUUID } from "node:crypto";
import { dirname, join } from "node:path";
import type { MemoryLimits, MemoryTarget, PendingMutation } from "./types.js";

const ENTRY_SEPARATOR = "\n\n§\n\n";

export class MemoryStore {
  private mutationQueue: Promise<void> = Promise.resolve();

  constructor(
    private readonly root: string,
    private readonly limits: MemoryLimits,
  ) {}

  async initialize(): Promise<void> {
    await mkdir(this.root, { recursive: true, mode: 0o700 });
    await chmod(this.root, 0o700);
  }

  async read(target: MemoryTarget, projectId?: string): Promise<string[]> {
    const content = await this.readText(this.memoryPath(target, projectId));
    return content ? content.split(ENTRY_SEPARATOR).filter(Boolean) : [];
  }

  async stage(input: Omit<PendingMutation, "id" | "createdAt">): Promise<PendingMutation> {
    return this.exclusively(async () => {
      if (input.target === "project" && !this.isProjectId(input.projectId)) {
        throw new Error("Invalid project id.");
      }
      const existing = (await this.listPending()).find((pending) => this.sameProposal(pending, input));
      if (existing) return existing;
      const pending: PendingMutation = { ...input, id: randomUUID(), createdAt: new Date().toISOString() };
      await this.writeAtomic(this.pendingPath(pending.id), `${JSON.stringify(pending, null, 2)}\n`);
      return pending;
    });
  }

  async listPending(): Promise<PendingMutation[]> {
    const { readdir } = await import("node:fs/promises");
    const directory = join(this.root, "pending");
    try {
      const names = (await readdir(directory)).filter((name) => name.endsWith(".json")).sort();
      const pending = await Promise.all(names.map(async (name) => {
        try {
          const value: unknown = JSON.parse(await readFile(join(directory, name), "utf8"));
          return isPendingMutation(value) ? value : undefined;
        } catch {
          return undefined;
        }
      }));
      return pending.filter((item): item is PendingMutation => item !== undefined);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") return [];
      throw error;
    }
  }

  async approve(id: string): Promise<PendingMutation> {
    return this.exclusively(async () => {
      const pending = await this.loadPending(id);
      const path = this.memoryPath(pending.target, pending.projectId);
      const previousText = await this.readText(path);
      const current = previousText ? previousText.split(ENTRY_SEPARATOR).filter(Boolean) : [];
      const next = this.apply(current, pending);
      const content = next.join(ENTRY_SEPARATOR);
      if (content.length > this.limitFor(pending.target)) {
        throw new Error(`Memory capacity exceeded for ${pending.target}; stage a replace or remove operation first.`);
      }
      await this.writeAtomic(path, content ? `${content}\n` : "");
      try {
        await this.appendProvenance(pending);
      } catch (error) {
        await this.writeAtomic(path, previousText ? `${previousText}\n` : "");
        throw error;
      }
      await rm(this.pendingPath(id), { force: true });
      return pending;
    });
  }

  async reject(id: string): Promise<void> {
    await this.exclusively(() => rm(this.pendingPath(id), { force: true }));
  }

  private apply(entries: string[], pending: PendingMutation): string[] {
    if (pending.operation === "add") return entries.includes(pending.content) ? entries : [...entries, pending.content];
    if (!pending.previousContent) throw new Error(`${pending.operation} requires previousContent.`);
    const index = entries.indexOf(pending.previousContent);
    if (index === -1) throw new Error("The memory entry to mutate no longer exists.");
    if (pending.operation === "remove") return entries.filter((_, entryIndex) => entryIndex !== index);
    const copy = [...entries];
    copy[index] = pending.content;
    return [...new Set(copy)];
  }

  private async loadPending(id: string): Promise<PendingMutation> {
    try {
      return JSON.parse(await readFile(this.pendingPath(id), "utf8")) as PendingMutation;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") throw new Error(`Pending memory ${id} was not found.`);
      throw error;
    }
  }

  private memoryPath(target: MemoryTarget, projectId?: string): string {
    if (target === "project") {
      if (!this.isProjectId(projectId)) throw new Error("Invalid project id.");
      return join(this.root, "projects", projectId, "MEMORY.md");
    }
    return join(this.root, "global", target === "user" ? "USER.md" : "MEMORY.md");
  }

  private pendingPath(id: string): string {
    return join(this.root, "pending", `${id}.json`);
  }

  private limitFor(target: MemoryTarget): number {
    return target === "user" ? this.limits.userCharLimit : target === "memory" ? this.limits.globalCharLimit : this.limits.projectCharLimit;
  }

  private async readText(path: string): Promise<string> {
    try {
      return (await readFile(path, "utf8")).trim();
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") return "";
      throw error;
    }
  }

  private async appendProvenance(pending: PendingMutation): Promise<void> {
    const record = { ...pending, contentHash: createHash("sha256").update(pending.content).digest("hex"), approvedAt: new Date().toISOString() };
    const path = join(this.root, "provenance.jsonl");
    await mkdir(dirname(path), { recursive: true, mode: 0o700 });
    await chmod(dirname(path), 0o700);
    await appendFile(path, `${JSON.stringify(record)}\n`, { encoding: "utf8", mode: 0o600 });
    await chmod(path, 0o600);
  }

  private async writeAtomic(path: string, content: string): Promise<void> {
    await mkdir(dirname(path), { recursive: true, mode: 0o700 });
    await chmod(dirname(path), 0o700);
    const temporary = `${path}.${randomUUID()}.tmp`;
    await writeFile(temporary, content, { encoding: "utf8", mode: 0o600 });
    await rename(temporary, path);
  }

  private isProjectId(projectId: string | undefined): projectId is string {
    return typeof projectId === "string" && /^[a-f0-9]{16,64}$/.test(projectId);
  }

  private sameProposal(existing: PendingMutation, next: Omit<PendingMutation, "id" | "createdAt">): boolean {
    return existing.operation === next.operation &&
      existing.target === next.target &&
      existing.content === next.content &&
      existing.previousContent === next.previousContent &&
      existing.projectId === next.projectId;
  }

  private async exclusively<T>(work: () => Promise<T>): Promise<T> {
    const previous = this.mutationQueue;
    let release!: () => void;
    this.mutationQueue = new Promise<void>((resolve) => {
      release = resolve;
    });
    await previous;
    try {
      return await this.withFileLock(work);
    } finally {
      release();
    }
  }

  private async withFileLock<T>(work: () => Promise<T>): Promise<T> {
    const lock = join(this.root, ".lock");
    const deadline = Date.now() + 5_000;
    await this.initialize();
    while (true) {
      try {
        await mkdir(lock, { mode: 0o700 });
        break;
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code !== "EEXIST") throw error;
        try {
          if (Date.now() - (await stat(lock)).mtimeMs > 60_000) {
            await rm(lock, { recursive: true, force: true });
            continue;
          }
        } catch {
          continue;
        }
        if (Date.now() >= deadline) throw new Error("Timed out waiting for Hermes memory storage lock.");
        await new Promise((resolve) => setTimeout(resolve, 25));
      }
    }
    try {
      return await work();
    } finally {
      await rm(lock, { recursive: true, force: true });
    }
  }
}

function isPendingMutation(value: unknown): value is PendingMutation {
  if (!value || typeof value !== "object") return false;
  const pending = value as Partial<PendingMutation>;
  return typeof pending.id === "string" &&
    (pending.operation === "add" || pending.operation === "replace" || pending.operation === "remove") &&
    (pending.target === "user" || pending.target === "memory" || pending.target === "project") &&
    typeof pending.content === "string" &&
    Array.isArray(pending.sourceSessionIds) && pending.sourceSessionIds.every((item) => typeof item === "string") &&
    Array.isArray(pending.sourceMessageIds) && pending.sourceMessageIds.every((item) => typeof item === "string") &&
    typeof pending.confidence === "number" && typeof pending.createdAt === "string";
}

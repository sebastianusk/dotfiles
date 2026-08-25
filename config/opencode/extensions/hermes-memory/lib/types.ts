export type MemoryTarget = "user" | "memory" | "project";
export type MemoryOperation = "add" | "replace" | "remove";

export type PendingMutation = {
  id: string;
  operation: MemoryOperation;
  target: MemoryTarget;
  content: string;
  previousContent?: string;
  projectId?: string;
  sourceSessionIds: string[];
  sourceMessageIds: string[];
  confidence: number;
  createdAt: string;
};

export type MemoryLimits = {
  userCharLimit: number;
  globalCharLimit: number;
  projectCharLimit: number;
};

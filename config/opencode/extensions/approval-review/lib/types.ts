export type PermissionReply = "once" | "always" | "reject";
export type ReviewDisposition = "unreviewed" | "rule-applied" | "dismissed" | "deferred";

export type AskedPermission = {
  id: string;
  permission: string;
  patterns: string[];
  always: string[];
  metadata: { command?: unknown };
};

export type RecordAskedResult = { written: true } | { written: false; reason: string };

export type RuleApplication = { ruleApplication: true };

export type ApprovalRecord = {
  id: string;
  permission: string;
  patterns: string[];
  always: string[];
  command?: string;
  projectId: string;
  askedAt: string;
  repliedAt?: string;
  reply?: PermissionReply;
  disposition: ReviewDisposition;
  dispositionAt?: string;
  redacted: boolean;
};

export type PolicyRule = { permission: string; pattern: string; action: "allow" | "deny" };
export type RuleCandidate = PolicyRule & { evidenceIds: string[]; explanation: string };

export type ValidationResult = {
  valid: boolean;
  reason?: string;
  matchingEvidenceIds: string[];
  conflictingEvidenceIds: string[];
  warnings: string[];
};

export type ApprovalReviewConfig = {
  dataPath: string;
  retentionDays: number;
  promotablePermissions: string[];
};

export type RedactionConfigResult =
  | { status: "ready"; source: string; patterns: RegExp[] }
  | { status: "absent"; reason: string }
  | { status: "disabled"; source: string; reason: string }
  | { status: "invalid"; source: string; reason: string };

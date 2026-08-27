import type { AskedPermission, PermissionReply } from "./types.js";

export type NormalizedPermissionEvent =
  | { kind: "asked"; input: AskedPermission }
  | { kind: "replied"; id: string; reply: PermissionReply };

const replies = new Set<PermissionReply>(["once", "always", "reject"]);

export function normalizePermissionEvent(event: unknown): NormalizedPermissionEvent | undefined {
  if (!isObject(event) || typeof event.type !== "string") return undefined;
  const properties = isObject(event.properties) ? event.properties : event;
  if (event.type === "permission.asked") return asked(properties, false);
  if (event.type === "permission.updated") return asked(properties, true);
  if (event.type === "permission.replied") {
    const id = string(properties.requestID) ?? string(properties.permissionID);
    const reply = properties.reply ?? properties.response;
    return id && isReply(reply) ? { kind: "replied", id, reply } : undefined;
  }
  return undefined;
}

function asked(value: Record<string, unknown>, legacy: boolean): NormalizedPermissionEvent | undefined {
  const id = string(value.id) ?? string(value.permissionID);
  const permission = legacy ? string(value.type) : string(value.permission);
  const patterns = legacy ? strings(value.pattern) : stringArray(value.patterns);
  const always = strings(value.always) ?? [];
  if (!id || !permission || !patterns || !always) return undefined;
  return { kind: "asked", input: { id, permission, patterns, always, metadata: isObject(value.metadata) ? { command: value.metadata.command } : {} } };
}

function isObject(value: unknown): value is Record<string, any> { return typeof value === "object" && value !== null && !Array.isArray(value); }
function string(value: unknown): string | undefined { return typeof value === "string" && value ? value : undefined; }
function strings(value: unknown): string[] | undefined { return typeof value === "string" ? [value] : Array.isArray(value) && value.every((item) => typeof item === "string") ? value : undefined; }
function stringArray(value: unknown): string[] | undefined { return Array.isArray(value) && value.every((item) => typeof item === "string") ? value : undefined; }
function isReply(value: unknown): value is PermissionReply { return typeof value === "string" && replies.has(value as PermissionReply); }

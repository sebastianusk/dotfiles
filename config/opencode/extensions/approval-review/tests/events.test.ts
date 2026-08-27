import { expect, test } from "bun:test";
import { normalizePermissionEvent } from "../lib/events.js";

test("normalizes v2 asked and replied events", () => {
  expect(normalizePermissionEvent({
    type: "permission.asked",
    properties: { id: "v2", permission: "bash", patterns: ["git status"], always: ["git status *"], metadata: { command: "git status" } },
  })).toEqual({
    kind: "asked",
    input: { id: "v2", permission: "bash", patterns: ["git status"], always: ["git status *"], metadata: { command: "git status" } },
  });

  expect(normalizePermissionEvent({ type: "permission.replied", properties: { requestID: "v2", reply: "once" } }))
    .toEqual({ kind: "replied", id: "v2", reply: "once" });
});

test("normalizes legacy updated and replied events", () => {
  expect(normalizePermissionEvent({
    type: "permission.updated",
    properties: { id: "legacy", type: "bash", pattern: "git status", always: ["git status *"], sessionID: "secret", metadata: { command: "git status" } },
  })).toMatchObject({ kind: "asked", input: { id: "legacy", permission: "bash", patterns: ["git status"] } });

  expect(normalizePermissionEvent({ type: "permission.replied", properties: { permissionID: "legacy", response: "reject" } }))
    .toEqual({ kind: "replied", id: "legacy", reply: "reject" });
});

test("rejects malformed events and unrecognized replies", () => {
  expect(normalizePermissionEvent({ type: "permission.replied", properties: { requestID: "x", reply: "later" } })).toBeUndefined();
  expect(normalizePermissionEvent({ type: "permission.asked", properties: { id: "x", permission: "bash", patterns: "git" } })).toBeUndefined();
  expect(normalizePermissionEvent({ type: "other", properties: {} })).toBeUndefined();
});

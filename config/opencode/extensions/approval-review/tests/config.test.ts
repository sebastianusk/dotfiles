import { expect, test } from "bun:test";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { compileVibeguardRedactionConfig, loadVibeguardRedactionConfig, parseConfig } from "../lib/config.js";

test("uses private local defaults and accepts promotion allowlists", () => {
  expect(parseConfig('{"promotablePermissions":["bash"]}')).toMatchObject({
    dataPath: `${homedir()}/.local/share/opencode/approval-review`,
    retentionDays: 90,
    promotablePermissions: ["bash"],
  });
});

test("rejects invalid retention and a blank config path", () => {
  expect(() => parseConfig('{"retentionDays":0}')).toThrow("retentionDays");
  expect(() => parseConfig('{"dataPath":""}')).toThrow("dataPath");
});

test("rejects non-object configuration input", () => {
  expect(() => parseConfig("null")).toThrow("configuration object");
  expect(() => parseConfig("[]")).toThrow("configuration object");
  expect(() => parseConfig('"config"')).toThrow("configuration object");
});

test("parses comment-only JSONC and expands configured paths", () => {
  expect(parseConfig(`{
    // local storage
    "dataPath": "~/.cache/opencode/approval-review"
  }`).dataPath).toBe(`${homedir()}/.cache/opencode/approval-review`);
});

test("rejects non-string permission arrays", () => {
  expect(() => parseConfig('{"promotablePermissions":["bash",1]}')).toThrow("promotablePermissions");
});

test("loads the effective Vibeguard config in documented first-match order", async () => {
  const directory = await mkdtemp(join(tmpdir(), "approval-review-config-"));
  try {
    await writeFile(join(directory, "vibeguard.config.json"), JSON.stringify({
      enabled: true,
      patterns: { regex: [{ pattern: "project-secret" }] },
    }));
    const result = await loadVibeguardRedactionConfig(directory, {});
    expect(result.status).toBe("ready");
    if (result.status === "ready") expect(result.patterns[0].test("project-secret")).toBe(true);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test("uses an environment path before project candidates", async () => {
  const directory = await mkdtemp(join(tmpdir(), "approval-review-config-"));
  try {
    const envPath = join(directory, "custom.json");
    await writeFile(envPath, JSON.stringify({ enabled: true, patterns: { keywords: [{ value: "literal-secret" }] } }));
    await writeFile(join(directory, "vibeguard.config.json"), "not json");
    const result = await loadVibeguardRedactionConfig(directory, { OPENCODE_VIBEGUARD_CONFIG: "custom.json" });
    expect(result.status).toBe("ready");
    if (result.status === "ready") expect(result.patterns[0].test("literal-secret")).toBe(true);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test("translates inline flags and preserves global matching", () => {
  const result = compileVibeguardRedactionConfig({
    enabled: true,
    patterns: { regex: [{ pattern: "(?i)password[:=].*" }, { pattern: "(?m)^token=.*$" }] },
  });
  expect(result.status).toBe("ready");
  if (result.status === "ready") {
    expect(result.patterns[0].flags).toContain("i");
    expect(result.patterns[0].global).toBe(true);
    expect(result.patterns[1].flags).toContain("m");
  }
});

test("reports invalid, disabled, and blank redaction configurations", async () => {
  const directory = await mkdtemp(join(tmpdir(), "approval-review-config-"));
  try {
    const path = join(directory, "vibeguard.config.json");
    await writeFile(path, JSON.stringify({ enabled: false, patterns: { regex: [{ pattern: "secret" }] } }));
    expect((await loadVibeguardRedactionConfig(directory, {})).status).toBe("disabled");
    await writeFile(path, JSON.stringify({ enabled: true, patterns: { regex: [{ pattern: "  " }] } }));
    expect((await loadVibeguardRedactionConfig(directory, {})).status).toBe("invalid");
    await writeFile(path, JSON.stringify({ enabled: true, patterns: {} }));
    expect((await loadVibeguardRedactionConfig(directory, {})).status).toBe("invalid");
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test("does not fall through when a higher-precedence config cannot be read", async () => {
  const directory = await mkdtemp(join(tmpdir(), "approval-review-config-"));
  try {
    await mkdir(join(directory, "vibeguard.config.json"));
    await mkdir(join(directory, ".opencode"));
    await writeFile(join(directory, ".opencode", "vibeguard.config.json"), JSON.stringify({
      enabled: true,
      patterns: { regex: [{ pattern: "fallback-secret" }] },
    }));
    const result = await loadVibeguardRedactionConfig(directory, {});
    expect(result.status).toBe("invalid");
    if (result.status === "invalid") expect(result.source).toBe(join(directory, "vibeguard.config.json"));
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

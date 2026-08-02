/**
 * Plan Tracker Extension
 *
 * Owns plan files (.pi/plans/<name>.md), the session→plan attachment pointer,
 * completion tracking (checkbox count), and the footer 📋.
 *
 * Receives "plan:commit" from plan-mode when the user confirms their plan;
 * writes/updates the plan file, attaches it to the session, and notifies.
 *
 * Commands: /plans, /plan:new, /plan:attach, /todos
 */

import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { AssistantMessage, TextContent } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";
import * as fs from "node:fs";
import * as path from "node:path";
import {
	countCheckboxes,
	extractDoneSteps,
	extractPlanSteps,
	parseExistingSteps,
	parsePlanFile,
	type PlanStep,
	writePlanFile,
} from "./utils.ts";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function isAssistantMessage(m: AgentMessage): m is AssistantMessage {
	return m.role === "assistant" && Array.isArray(m.content);
}

function getTextContent(message: AssistantMessage): string {
	return message.content
		.filter((block): block is TextContent => block.type === "text")
		.map((block) => block.text)
		.join("\n");
}

interface Attachment {
	planName: string;
	path: string;
}

function getAttachment(entries: Array<{ type: string; customType?: string; data?: unknown }>): Attachment | undefined {
	for (let i = entries.length - 1; i >= 0; i--) {
		const e = entries[i];
		if (e.type === "custom" && e.customType === "plan-tracker-attachment" && e.data) {
			const d = e.data as Attachment;
			// sentinel: planName is null -> detached
			return d.planName ? d : undefined;
		}
	}
}

function findLastAssistantMessage(
	entries: Array<{ type: string; message?: unknown }>,
): AssistantMessage | undefined {
	for (let i = entries.length - 1; i >= 0; i--) {
		const e = entries[i];
		if (e.type === "message" && e.message && isAssistantMessage(e.message as AgentMessage)) {
			return e.message as AssistantMessage;
		}
	}
}

function slugify(text: string): string {
	return text
		.toLowerCase()
		.replace(/[^a-z0-9\s-]/g, "")
		.replace(/\s+/g, "-")
		.replace(/-+/g, "-")
		.slice(0, 40)
		.replace(/^-|-$/g, "");
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function planTrackerExtension(pi: ExtensionAPI): void {
	let currentAttachment: Attachment | undefined;
	let currentCtx: ExtensionContext | undefined;

	function updateFooter(ctx: ExtensionContext): void {
		if (currentAttachment && currentAttachment.path) {
			const { completed, total } = countCheckboxes(currentAttachment.path);
			const relPath = path.relative(process.cwd(), currentAttachment.path);
			ctx.ui.setStatus("plan-tracker", `📋 ${relPath} ${completed}/${total}`);
		} else {
			ctx.ui.setStatus("plan-tracker", undefined);
		}
	}

	// ── session_start: restore attachment ──────────────────────────────
	pi.on("session_start", async (_event, ctx) => {
		currentCtx = ctx;
		const att = getAttachment(ctx.sessionManager.getEntries());
		if (att) {
			currentAttachment = att;
		}
		updateFooter(ctx);
	});

	// ── plan:commit — write/update the plan file ──────────────────────
	pi.events.on("plan:commit", async (data: { name?: string; createNew?: boolean } | undefined) => {
		if (!currentCtx) return;
		const ctx = currentCtx;
		const entries = ctx.sessionManager.getEntries();

		// Find the last assistant message
		const lastAssistant = findLastAssistantMessage(entries);
		if (!lastAssistant) {
			ctx.ui.notify("Plan tracker: no assistant message found to capture plan from.", "warn");
			return;
		}

		const text = getTextContent(lastAssistant);
		const steps = extractPlanSteps(text);
		if (steps.length === 0) {
			ctx.ui.notify("Plan tracker: no Plan: section found in the last response.", "warn");
			return;
		}

		const plansDir = path.resolve(process.cwd(), ".pi", "plans");
		const existingAtt = data?.createNew ? undefined : getAttachment(entries);

		let planName: string;
		let filePath: string;
		let created: boolean;

		if (existingAtt) {
			// ── Update existing plan ──────────────────────────────────
			planName = existingAtt.planName;
			filePath = existingAtt.path;

			if (typeof filePath !== "string") {
				ctx.ui.notify("Plan tracker: invalid file path in attachment.", "error");
				return;
			}

			// Preserve checked state for steps whose text matches exactly
			const existingSteps = parseExistingSteps(filePath);
			const checkedTexts = new Set<string>();
			for (const es of existingSteps) {
				if (es.checked) checkedTexts.add(es.text);
			}

			const mergedSteps: PlanStep[] = steps.map((s) => ({
				...s,
				checked: checkedTexts.has(s.text),
			}));

			writePlanFile(filePath, { updated: new Date().toISOString() }, mergedSteps);
			created = false;
		} else {
			// ── Create new plan ───────────────────────────────────────
			// Derive a slug from data.name or the first step's text
			const explicitName = data?.name?.trim();
			const source = explicitName || steps[0].text;
			const slug = slugify(source) || `plan-${Date.now()}`;
			planName = slug;
			filePath = path.join(plansDir, `${planName}.md`);

			writePlanFile(filePath, { updated: new Date().toISOString() }, steps);
			created = true;

			// Attach to session
			pi.appendEntry("plan-tracker-attachment", { planName, path: filePath });
		}

		// Update local state
		currentAttachment = { planName, path: filePath };

		// Notify & update index
		const relPath = path.relative(process.cwd(), filePath);
		ctx.ui.notify(
			created
				? `Plan saved to ${relPath}. Re-run /plan to refine, or proceed.`
				: `Plan updated at ${relPath}.`,
			"info",
		);
		updateFooter(ctx);

		// Inform plan-mode (informational)
		pi.events.emit("plan:committed", { path: filePath, planName, created });
	});

	// ── turn_end: auto-check [DONE:n] + recompute footer ──────────────
	pi.on("turn_end", async (event, ctx) => {
		if (!currentAttachment) {
			updateFooter(ctx);
			return;
		}

		// Auto-check [DONE:n] markers in the last assistant message
		const msg = event.message;
		if (isAssistantMessage(msg)) {
			const text = getTextContent(msg);
			const doneSteps = extractDoneSteps(text);

			if (doneSteps.length > 0) {
				const existing = parseExistingSteps(currentAttachment.path);
				let changed = false;

				for (const dn of doneSteps) {
					const idx = dn - 1; // [DONE:1] -> index 0
					if (idx >= 0 && idx < existing.length && !existing[idx].checked) {
						existing[idx].checked = true;
						changed = true;
					}
				}

				if (changed) {
					writePlanFile(
						currentAttachment.path,
						{ updated: new Date().toISOString() },
						existing,
					);
				}

				// Check if all steps are complete
				const { completed, total } = countCheckboxes(currentAttachment.path);
				if (total > 0 && completed === total && ctx.hasUI) {
					updateFooter(ctx);
					const relPath = path.relative(process.cwd(), currentAttachment.path);
					const choice = await ctx.ui.select(
						`Plan complete!\n${relPath}`,
						["Keep plan file", "Delete plan file"],
					);
					if (choice?.startsWith("Delete")) {
						try {
							fs.unlinkSync(currentAttachment.path);
							ctx.ui.notify(`Deleted plan file: ${relPath}`, "info");
						} catch (err) {
							ctx.ui.notify(`Failed to delete: ${err}`, "error");
						}
					}
					pi.appendEntry("plan-tracker-attachment", { planName: null, path: null });
					currentAttachment = undefined;
				}
			}
		}

		updateFooter(ctx);
	});

	// ── before_agent_start: inject plan file path ────────────────────
	pi.on("before_agent_start", async () => {
		if (!currentAttachment) return;

		const relPath = path.relative(process.cwd(), currentAttachment.path);
		return {
			message: {
				customType: "plan-tracker-context",
				content: `Plan file: ${relPath}
After completing a step, include [DONE:n] in your response.`,
				display: false,
			},
		};
	});

	// ── Commands ──────────────────────────────────────────────────────

	pi.registerCommand("plans", {
		description: "List repo plans and select to attach",
		handler: async (_args, ctx) => {
			const plansDir = path.resolve(process.cwd(), ".pi", "plans");
			if (!ctx.hasUI) {
				ctx.ui.notify(`Plan files are in ${plansDir}`, "info");
				return;
			}

			const files = fs
				.readdirSync(plansDir, { withFileTypes: true })
				.filter((d) => d.isFile() && d.name.endsWith(".md") && d.name !== "README.md")
				.sort((a, b) => a.name.localeCompare(b.name));

			if (files.length === 0) {
				ctx.ui.notify("No plans found. Create one with /plan:new <name>.", "info");
				return;
			}

			const options = files.map((f) => {
				const filePath = path.join(plansDir, f.name);
				const { completed, total } = countCheckboxes(filePath);
				const status = total > 0 && completed === total ? "complete" : "planning";
				const name = f.name.replace(/\.md$/, "");
				return {
					value: name,
					label: `${name} — ${status}`,
				};
			});

			const choice = await ctx.ui.select("Attach a plan:", options.map((o) => o.label));
			if (!choice) return;

			const chosen = options.find((o) => o.label === choice);
			if (!chosen) return;

			const filePath = path.join(plansDir, `${chosen.value}.md`);
			pi.appendEntry("plan-tracker-attachment", { planName: chosen.value, path: filePath });
			currentAttachment = { planName: chosen.value, path: filePath };
			updateFooter(ctx);
			ctx.ui.notify(`Attached plan: ${chosen.value}`, "info");
		},
	});

	pi.registerCommand("plan:new", {
		description: "Create an empty plan and attach it",
		handler: async (args, ctx) => {
			const name = args.trim();
			if (!name) {
				ctx.ui.notify("Usage: /plan:new <name>", "warn");
				return;
			}

			const plansDir = path.resolve(process.cwd(), ".pi", "plans");
			const planName = slugify(name);
			const filePath = path.join(plansDir, `${planName}.md`);

			writePlanFile(filePath, { updated: new Date().toISOString() }, []);
			pi.appendEntry("plan-tracker-attachment", { planName, path: filePath });
			currentAttachment = { planName, path: filePath };
			updateFooter(ctx);

			const relPath = path.relative(process.cwd(), filePath);
			ctx.ui.notify(`Created & attached: ${relPath}`, "info");
		},
	});

	pi.registerCommand("plan:attach", {
		description: "Attach an existing plan by name",
		handler: async (args, ctx) => {
			const name = args.trim();
			if (!name) {
				ctx.ui.notify("Usage: /plan:attach <name>", "warn");
				return;
			}

			const plansDir = path.resolve(process.cwd(), ".pi", "plans");
			const planName = slugify(name);
			const filePath = path.join(plansDir, `${planName}.md`);

			if (!fs.existsSync(filePath)) {
				ctx.ui.notify(`Plan "${planName}" not found. Create it with /plan:new first.`, "warn");
				return;
			}

			pi.appendEntry("plan-tracker-attachment", { planName, path: filePath });
			currentAttachment = { planName, path: filePath };
			updateFooter(ctx);
			ctx.ui.notify(`Attached plan: ${planName}`, "info");
		},
	});

	pi.registerCommand("todos", {
		description: "Print the path of the attached plan",
		handler: async (_args, ctx) => {
			if (!currentAttachment) {
				ctx.ui.notify("No plan attached. Use /plans to attach one or /plan:new to create.", "info");
				return;
			}

			const relPath = path.relative(process.cwd(), currentAttachment.path);
			ctx.ui.notify(`Plan: ${relPath}`, "info");
		},
	});

	pi.registerCommand("plan:detach", {
		description: "Detach the current plan",
		handler: async (_args, ctx) => {
			if (!currentAttachment) {
				ctx.ui.notify("No plan attached.", "info");
				return;
			}
			pi.appendEntry("plan-tracker-attachment", { planName: null, path: null });
			currentAttachment = undefined;
			updateFooter(ctx);
			ctx.ui.notify("Plan detached.", "info");
		},
	});

	pi.registerShortcut(Key.ctrlAlt("d"), {
		description: "Detach current plan",
		handler: async (ctx) => {
			if (!currentAttachment) {
				ctx.ui.notify("No plan attached.", "info");
				return;
			}
			pi.appendEntry("plan-tracker-attachment", { planName: null, path: null });
			currentAttachment = undefined;
			updateFooter(ctx);
			ctx.ui.notify("Plan detached.", "info");
		},
	});
}

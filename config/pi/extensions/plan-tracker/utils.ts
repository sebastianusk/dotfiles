/**
 * Plan tracker utilities: plan-file I/O and the plan-step parser (P1 fix).
 *
 * Parsing fixes vs the old plan-mode parser:
 * - Stops at the next Markdown heading (no bleed into later sections).
 * - Skips fenced code blocks entirely.
 * - Parses the full numbered-line text before stripping formatting
 *   (old regex truncated "1. **Inspect** the code" → "Inspect").
 * - Supports "Plan:", "## Plan", and "### Plan" headers.
 */

import * as fs from "node:fs";
import * as path from "node:path";

// ---------------------------------------------------------------------------
// Plan step parser
// ---------------------------------------------------------------------------

export interface PlanStep {
	text: string;
	checked: boolean;
}

/**
 * Strip only markdown inline formatting — no truncation, no prefix removal.
 * Preserves the full step text for file storage.
 */
export function stripMarkdownInline(text: string): string {
	return (
		text
			// bold / italic (asterisk)
			.replace(/\*{1,2}([^*]+)\*{1,2}/g, "$1")
			// bold / italic (underscore)
			.replace(/_{1,2}([^_]+)_{1,2}/g, "$1")
			// inline code
			.replace(/`([^`]+)`/g, "$1")
			// link text [title](url) — keep the title
			.replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
			// collapse whitespace
			.replace(/\s+/g, " ")
			.trim()
	);
}

/**
 * Extract numbered plan steps from an assistant message.
 *
 * Looks for a "Plan:", "## Plan", or "### Plan" header line, then parses
 * numbered items until the next Markdown heading.  Fenced code blocks and
 * quoted blocks are skipped.
 */
export function extractPlanSteps(message: string): PlanStep[] {
	// Match Plan: (optionally with ## / ### prefix, optionally bold-wrapped)
	const headerRe = /(?:^|\n)(?:(?:#{2,3}\s+)?\*{0,2}Plan:\*{0,2})(?:\s*\n|$)/im;
	const headerMatch = message.match(headerRe);
	if (!headerMatch) return [];

	const startIdx = message.indexOf(headerMatch[0]) + headerMatch[0].length;
	const rest = message.slice(startIdx);

	const items: PlanStep[] = [];
	const lines = rest.split("\n");
	let inFence = false;

	for (const rawLine of lines) {
		const line = rawLine.trim();

		// Skip fenced code-block boundaries
		if (/^```/.test(line)) {
			inFence = !inFence;
			continue;
		}
		if (inFence) continue;

		// Stop at any heading
		if (/^#{1,4}\s/.test(line)) break;

		// Stop at solid horizontal rule
		if (/^(-{3,}|={3,}|\*{3,})$/.test(line)) break;

		// Numbered item
		const numMatch = line.match(/^\s*(\d+)[.)]\s+(.+)/);
		if (!numMatch) continue;

		const rawText = numMatch[2].trim();
		const cleaned = stripMarkdownInline(rawText);
		if (cleaned.length >= 3) {
			items.push({ text: cleaned, checked: false });
		}
	}

	return items;
}

/** Extract [DONE:n] step numbers from the assistant response. */
export function extractDoneSteps(text: string): number[] {
	const steps: number[] = [];
	for (const match of text.matchAll(/\[DONE:(\d+)\]/gi)) {
		const step = Number(match[1]);
		if (Number.isFinite(step) && step > 0) steps.push(step);
	}
	return [...new Set(steps)];
}

// ---------------------------------------------------------------------------
// Plan file I/O
// ---------------------------------------------------------------------------

export interface PlanFrontmatter {
	updated: string; // ISO timestamp
}

interface ParsedFile {
	frontmatter: PlanFrontmatter;
	body: string;
}

/** Parse a plan file into frontmatter and Markdown body. */
export function parsePlanFile(filePath: string): ParsedFile | null {
	if (!fs.existsSync(filePath)) return null;
	const content = fs.readFileSync(filePath, "utf-8");

	const fmMatch = content.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
	if (!fmMatch) {
		return {
			frontmatter: { updated: new Date().toISOString() },
			body: content,
		};
	}

	const fm: Record<string, string> = {};
	for (const line of fmMatch[1].split("\n")) {
		const kv = line.match(/^(\w+):\s*(.+)/);
		if (kv) fm[kv[1]] = kv[2].trim();
	}

	const frontmatter: PlanFrontmatter = {
		updated: fm.updated || new Date().toISOString(),
	};

	return { frontmatter, body: fmMatch[2] };
}

/** Parse existing checkboxes from a plan file body. */
export function parseExistingSteps(filePath: string): PlanStep[] {
	const parsed = parsePlanFile(filePath);
	if (!parsed) return [];

	const steps: PlanStep[] = [];
	for (const rawLine of parsed.body.split("\n")) {
		const match = rawLine.match(/^\s*-\s+\[(x| )\]\s+(.+)/i);
		if (match) {
			steps.push({ text: match[2].trim(), checked: match[1].toLowerCase() === "x" });
		}
	}
	return steps;
}

/** Write a plan file with frontmatter and step list. */
export function writePlanFile(filePath: string, frontmatter: PlanFrontmatter, steps: PlanStep[]): void {
	const fmBlock = [`updated: ${frontmatter.updated}`];
	const stepLines = steps.map((s) => `- [${s.checked ? "x" : " "}] ${s.text}`);

	const content = `---\n${fmBlock.join("\n")}\n---\n\n${stepLines.join("\n")}\n`;
	fs.mkdirSync(path.dirname(filePath), { recursive: true });
	fs.writeFileSync(filePath, content, "utf-8");
}

/** Count checked / total checkboxes in a plan file. */
export function countCheckboxes(filePath: string): { completed: number; total: number } {
	if (!fs.existsSync(filePath)) return { completed: 0, total: 0 };
	const content = fs.readFileSync(filePath, "utf-8");

	const checked = (content.match(/^- \[x\]/gim) || []).length;
	const total = (content.match(/^- \[[ x]\]/gim) || []).length;
	return { completed: checked, total };
}


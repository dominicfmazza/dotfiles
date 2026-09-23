/**
 * Comment Hygiene Extension
 *
 * A comment explains the code. A comment does not explain the change.
 * The commit message and the MR body carry the history.
 *
 * This extension inspects the comment lines that a `write` or an `edit` tool
 * call adds. It blocks a comment that narrates an edit or refers to a past
 * state of the code.
 *
 * Scope: every file type, because the check reads comment markers, not an AST.
 *
 * Mode, from the environment variable `PI_COMMENT_HYGIENE`:
 *   block (default)  Reject the tool call. The agent must rewrite the comment.
 *   warn             Allow the tool call. Show a notice.
 *   off              Disable the check.
 *
 * Escape hatch: put `pi-allow-change-comment` on the comment line.
 *
 * The extension also checks comment shape and comment prose:
 *   length   A comment line stays at 80 characters. A comment block stays
 *            at 2 lines. A longer comment is blocked.
 *   ste      Each new comment block runs through ste-lint.py. A comment
 *            with a nonzero slop score is blocked.
 * Both checks read only the comment text a write or an edit adds. An old
 * comment in the file does not trigger a block.
 *
 * The ste-lint path comes from the environment variable PI_STE_LINT, or
 * from the default install path. A missing script disables the ste check.
 */

import { spawnSync } from "node:child_process";
import { homedir } from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** The max characters in a single comment line. */
const MAX_COMMENT_LINE = 80;

/** The max lines in one comment block. */
const MAX_COMMENT_LINES = 2;

type Mode = "block" | "warn" | "off";

/** A comment line that the check rejects, with the reason. */
export interface Finding {
	/** The comment line, trimmed. */
	line: string;
	/** The name of the pattern that matched. */
	pattern: string;
	/** Plain guidance for the agent. */
	hint: string;
}

/**
 * A file whose content is a record of changes by design.
 * A changelog and release notes describe edits. That is their job.
 */
const PROSE_EXTENSIONS = new Set([".md", ".mdx", ".markdown", ".rst", ".txt", ".adoc"]);

const PROSE_NAMES = [
	"changelog",
	"changes",
	"history",
	"news",
	"releases",
	"release-notes",
	"commit_editmsg",
	"merge_msg",
	"tag_editmsg",
];

/**
 * Comment markers, longest first, so `///` matches before `//`.
 * The check strips a marker from the start of a trimmed line.
 */
const LINE_MARKERS = [
	"<!--",
	"///",
	"##",
	"//",
	"/*",
	"*/",
	"--",
	"#",
	";;",
	";",
	"%",
	"*",
	'"""',
	"'''",
];

/**
 * Each pattern names a comment that describes an edit or a past state.
 * The check runs these against the comment text only, never against code.
 */
const PATTERNS: Array<{ name: string; re: RegExp; hint: string }> = [
	{
		name: "past-state",
		re: /\b(previously|formerly|used to (be|have|call|return|live|work)|no longer|prior to this|before this (change|commit|fix|mr|pr)|as of this (change|commit|fix|mr|pr)|in the old|the old (code|version|behavior|behaviour|way))\b/i,
		hint: "State the current behavior. Drop the past state.",
	},
	{
		name: "without-this",
		re: /\bwithout (this|the (new |added )?\w+[ ,]|these)\b/i,
		hint: "State what the code does. Do not argue against the old code.",
	},
	{
		name: "this-change",
		re: /\bthis (change|commit|patch|edit|fix|mr|pr|revision|diff)\b/i,
		hint: "A comment lives with the code, not with the diff. Remove the reference.",
	},
	{
		name: "now-narration",
		re: /(^|\.\s+|\b(and|so|but)\s+)now\s+(we|it|this|they|the\b|uses?|use|returns?|reads?|sets?|handles?|works?|runs?|calls?|supports?)/i,
		hint: 'Describe the behavior directly. Drop "now".',
	},
	{
		name: "edit-verb",
		re: /(^|\.\s+)(added|removed|deleted|renamed|moved|changed|switched|replaced|refactored|reverted|bumped|dropped|split|merged|introduced|extracted|inlined|migrated|corrected|fixe[sd])\b(?![-\s]*(point|size|width|length|precision|rate|format))/i,
		hint: "The commit message records the edit. Describe the code instead.",
	},
	{
		name: "fix-narration",
		re: /\b(fixe[sd]|fix for|workaround for|patches?)\s+(a\s+|the\s+|an\s+)?(bug|issue|regression|crash|failure|defect|typo|problem|#\d+)\b/i,
		hint: "Explain the constraint that forces the code, not the bug it fixed.",
	},
	{
		name: "past-defect",
		re: /\b(was|were|had been)\s+(broken|missing|wrong|incorrect|buggy|failing|absent|duplicated|unused|hardcoded)\b/i,
		hint: "A reader cannot see the old defect. Describe the current rule.",
	},
	{
		name: "change-direction",
		re: /\b(changed|renamed|moved|switched|bumped|updated)\s+(from|to)\b/i,
		hint: "Name the current value or location. Drop the transition.",
	},
	{
		name: "instead-of-old",
		re: /\b(instead of|rather than)\s+(the\s+)?(old|previous|former|original|legacy)\b/i,
		hint: "Describe the chosen approach. Drop the comparison to the old one.",
	},
	{
		name: "review-chatter",
		re: /\b(per (review|comment|feedback)|as (requested|discussed) (in|by)|addressing (review|feedback)|see (the )?(mr|pr) discussion)\b/i,
		hint: "Review talk belongs in the MR, not in the code.",
	},
];

/** The mode from the environment. An unknown value falls back to block. */
export function resolveMode(raw: string | undefined): Mode {
	const v = (raw ?? "").trim().toLowerCase();
	if (v === "off" || v === "0" || v === "false") return "off";
	if (v === "warn" || v === "warning") return "warn";
	return "block";
}

/** True when the file records changes by design. */
export function isProseFile(filePath: string): boolean {
	const base = path.basename(filePath).toLowerCase();
	const ext = path.extname(base);
	if (PROSE_EXTENSIONS.has(ext)) return true;
	const stem = ext ? base.slice(0, -ext.length) : base;
	if (PROSE_NAMES.includes(stem)) return true;
	return filePath.includes(`${path.sep}.git${path.sep}`);
}

/**
 * The comment text of a line, or null when the line holds no comment.
 * A trailing comment counts, so `code(); // now we retry` is checked.
 */
export function commentTextOf(rawLine: string): string | null {
	const line = rawLine.trim();
	if (line.length === 0) return null;

	for (const marker of LINE_MARKERS) {
		if (line.startsWith(marker)) {
			return stripEnd(line.slice(marker.length));
		}
	}

	// A trailing comment. Only markers that rarely appear inside code.
	const trailing = line.match(/(?:^|\s)(\/\/|#|<!--|\/\*)\s?(.*)$/);
	if (trailing) {
		const before = line.slice(0, trailing.index ?? 0);
		if (isInsideStringOrUrl(before, trailing[1])) return null;
		return stripEnd(trailing[2]);
	}

	return null;
}

/** Remove a closing marker and the surrounding space. */
function stripEnd(text: string): string {
	return text.replace(/(-->|\*\/)\s*$/, "").trim();
}

/**
 * A guard against a false comment marker. A `#` inside a shell variable
 * expansion or a `//` inside a URL is code, not a comment.
 */
function isInsideStringOrUrl(before: string, marker: string): boolean {
	if (marker === "//" && /[a-z][a-z0-9+.-]*:$/i.test(before)) return true;
	const quotes = (before.match(/"/g) ?? []).length + (before.match(/'/g) ?? []).length;
	return quotes % 2 === 1;
}

/**
 * The ste-lint script path. The environment variable wins. The default
 * install path follows. An empty string when neither exists.
 */
export function resolveSteLintPath(): string {
	const env = process.env.PI_STE_LINT?.trim();
	if (env) return env;
	return path.join(
		homedir(),
		".pi/agent/git/github.com/dominicfmazza/pi-ste/skills/ste/ste-lint.py",
	);
}

/**
 * A contiguous run of comment lines, with the 1-based start line in the text.
 * A block groups adjacent comment lines so a 3-line comment reads as one unit.
 */
export interface CommentBlock {
	startLine: number;
	lines: string[];
	text: string;
}

/** Every contiguous comment block in a text. A blank line ends a block. */
export function commentBlocks(text: string): CommentBlock[] {
	const blocks: CommentBlock[] = [];
	const rows = text.split("\n");
	let current: CommentBlock | null = null;

	for (let i = 0; i < rows.length; i++) {
		const comment = commentTextOf(rows[i]);
		if (comment === null) {
			current = null;
			continue;
		}
		if (current === null) {
			current = { startLine: i + 1, lines: [], text: "" };
			blocks.push(current);
		}
		current.lines.push(comment);
	}

	for (const b of blocks) b.text = b.lines.join("\n");
	return blocks;
}

/** A comment line over the length limit, or a block over the line limit. */
export function findLongComments(text: string): Finding[] {
	const findings: Finding[] = [];

	for (const rawLine of text.split("\n")) {
		if (rawLine.includes("pi-allow-change-comment")) continue;
		if (commentTextOf(rawLine) === null) continue;
		const len = rawLine.replace(/\s+$/, "").length;
		if (len > MAX_COMMENT_LINE) {
			findings.push({
				line: rawLine.trim(),
				pattern: "line-too-long",
				hint: `Keep a comment line at ${MAX_COMMENT_LINE} characters. This line has ${len}.`,
			});
		}
	}

	for (const block of commentBlocks(text)) {
		if (block.text.includes("pi-allow-change-comment")) continue;
		if (block.lines.length > MAX_COMMENT_LINES) {
			findings.push({
				line: block.lines[0],
				pattern: "block-too-long",
				hint: `Keep a comment to ${MAX_COMMENT_LINES} lines. This block has ${block.lines.length}.`,
			});
		}
	}

	return findings;
}

/**
 * A comment block whose ste-lint score is nonzero. The script reads the
 * block text on stdin and prints JSON. A missing script returns no finding.
 */
export function findSlopComments(text: string, steLintPath: string): Finding[] {
	if (!steLintPath) return [];
	const findings: Finding[] = [];

	for (const block of commentBlocks(text)) {
		if (block.text.includes("pi-allow-change-comment")) continue;
		if (block.text.trim().length < 4) continue;

		const run = spawnSync("python3", [steLintPath], {
			input: block.text,
			encoding: "utf-8",
			timeout: 5000,
		});
		if (run.status !== 0 || !run.stdout) continue;

		let report: { total?: number; violations?: Record<string, number> };
		try {
			report = JSON.parse(run.stdout);
		} catch {
			continue;
		}
		if (!report.total || report.total < 1) continue;

		const names = Object.entries(report.violations ?? {})
			.filter(([, n]) => n > 0)
			.map(([k]) => k)
			.join(", ");
		findings.push({
			line: block.lines[0],
			pattern: "ste-slop",
			hint: `Rewrite in plain English. ste-lint flags: ${names || "style"}.`,
		});
	}

	return findings;
}

/** Every rejected comment line in a block of text. */
export function findChangeComments(text: string): Finding[] {
	const findings: Finding[] = [];

	for (const rawLine of text.split("\n")) {
		if (rawLine.includes("pi-allow-change-comment")) continue;

		const comment = commentTextOf(rawLine);
		if (comment === null || comment.length < 4) continue;

		for (const p of PATTERNS) {
			if (p.re.test(comment)) {
				findings.push({ line: rawLine.trim(), pattern: p.name, hint: p.hint });
				break;
			}
		}
	}

	return findings;
}

/** The set of comment texts in a block of text, trimmed and non-empty. */
function commentSet(text: string): Set<string> {
	const set = new Set<string>();
	for (const raw of text.split("\n")) {
		const c = commentTextOf(raw);
		if (c !== null && c.length > 0) set.add(c);
	}
	return set;
}

/**
 * The comment lines a write or an edit introduces or changes. A write
 * returns its whole content. An edit returns only the lines whose comment
 * text is absent from the same edit's oldText, so a carried-along comment
 * does not trigger a check.
 */
function addedTextOf(toolName: string, input: Record<string, unknown>): string {
	if (toolName === "write") {
		return typeof input.content === "string" ? input.content : "";
	}

	const edits = input.edits;
	if (!Array.isArray(edits)) return "";

	return edits
		.map((e) => {
			const entry = e as { newText?: unknown; oldText?: unknown };
			const newText = typeof entry.newText === "string" ? entry.newText : "";
			const oldText = typeof entry.oldText === "string" ? entry.oldText : "";
			if (!newText) return "";
			const before = commentSet(oldText);
			return newText
				.split("\n")
				.filter((line) => {
					const c = commentTextOf(line);
					return c === null ? false : !before.has(c);
				})
				.join("\n");
		})
		.join("\n");
}

/** The message shown to the agent or to the user. */
function formatReport(filePath: string, findings: Finding[]): string {
	const lines = [
		`Comment hygiene: ${findings.length} comment issue(s) in ${filePath}.`,
		"",
		"A comment explains the code in plain, short English.",
		"Keep it to 2 lines, 80 characters each. The commit carries history.",
		"",
	];

	for (const f of findings.slice(0, 8)) {
		lines.push(`  ${f.line}`);
		lines.push(`    [${f.pattern}] ${f.hint}`);
	}

	if (findings.length > 8) {
		lines.push(`  ... and ${findings.length - 8} more.`);
	}

	lines.push("");
	lines.push("Rewrite the comment, or delete it. To keep one on purpose,");
	lines.push("add `pi-allow-change-comment` to that line.");

	return lines.join("\n");
}

export default function commentHygieneExtension(pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		const mode = resolveMode(process.env.PI_COMMENT_HYGIENE);
		if (mode === "off") return undefined;

		if (event.toolName !== "write" && event.toolName !== "edit") {
			return undefined;
		}

		const input = event.input as Record<string, unknown>;
		const filePath = typeof input.path === "string" ? input.path : "";
		if (filePath.length === 0 || isProseFile(filePath)) return undefined;

		const added = addedTextOf(event.toolName, input);
		const findings = [
			...findChangeComments(added),
			...findLongComments(added),
			...findSlopComments(added, resolveSteLintPath()),
		];
		if (findings.length === 0) return undefined;

		const report = formatReport(filePath, findings);

		if (mode === "warn") {
			if (ctx.hasUI) {
				ctx.ui.notify(`Comment hygiene: ${findings.length} comment issue(s)`, "warning");
			}
			return undefined;
		}

		return { block: true, reason: report };
	});
}

// The gate blocks the agent edit and write tools so the user writes code.
// Commands: /self-code [on|off]. On by default. Blocks in non-UI mode.

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const GATED_TOOLS = new Set(["edit", "write"]);

const BLOCK_REASON =
	"Code-writing is gated by the user. Do not edit or write files. " +
	"Instead, print the full file content or the exact change in a code block " +
	"so the user can type or paste it by hand.";

export default function (pi: ExtensionAPI) {
	let gateOn = true;

	function preview(event: { toolName: string; input: Record<string, unknown> }): string {
		const path = typeof event.input.path === "string" ? event.input.path : "?";
		if (event.toolName === "write") {
			const content = typeof event.input.content === "string" ? event.input.content : "";
			const lines = content.split("\n").length;
			return `write ${path} (${lines} lines)`;
		}
		return `edit ${path}`;
	}

	function reportState(ctx: ExtensionContext) {
		const state = gateOn ? "on (edits/writes blocked)" : "off (agent may edit)";
		ctx.ui.setStatus("no-offload", gateOn ? "self-code: on" : "self-code: off");
		ctx.ui.notify(`self-code gate is ${state}`, "info");
	}

	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setStatus("no-offload", gateOn ? "self-code: on" : "self-code: off");
	});

	pi.on("tool_call", async (event, ctx) => {
		if (!gateOn) return undefined;
		if (!GATED_TOOLS.has(event.toolName)) return undefined;

		if (!ctx.hasUI) {
			return { block: true, reason: BLOCK_REASON };
		}

		const choice = await ctx.ui.select(
			`self-code gate\n\n  ${preview(event)}\n\nType it yourself, or let the agent apply it?`,
			["Block (I will do it)", "Allow this one", "Turn gate off for session"],
		);

		if (choice === "Allow this one") {
			return undefined;
		}
		if (choice === "Turn gate off for session") {
			gateOn = false;
			reportState(ctx);
			return undefined;
		}
		return { block: true, reason: BLOCK_REASON };
	});

	pi.registerCommand("self-code", {
		description: "Control the self-code gate (blocks agent edit/write)",
		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase();
			if (arg === "on") {
				gateOn = true;
			} else if (arg === "off") {
				gateOn = false;
			} else if (arg !== "") {
				ctx.ui.notify("Usage: /self-code [on|off]", "warn");
				return;
			}
			reportState(ctx);
		},
	});
}

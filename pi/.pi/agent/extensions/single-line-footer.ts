// Footer on one line: cwd (branch) • tokens cost ctx% • statuses ... model.
// The command /footer toggles between this footer and the default footer.

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

function fmt(n: number): string {
	if (n < 1000) return `${n}`;
	if (n < 10000) return `${(n / 1000).toFixed(1)}k`;
	if (n < 1000000) return `${Math.round(n / 1000)}k`;
	return `${(n / 1000000).toFixed(1)}M`;
}

function shortCwd(cwd: string): string {
	const home = process.env.HOME;
	return home && cwd.startsWith(home) ? `~${cwd.slice(home.length)}` : cwd;
}

export default function (pi: ExtensionAPI) {
	let enabled = true;

	const install = (ctx: ExtensionContext) => {
		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsub = footerData.onBranchChange(() => tui.requestRender());
			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					let input = 0;
					let output = 0;
					let cost = 0;
					for (const e of ctx.sessionManager.getEntries()) {
						if (e.type === "message" && e.message.role === "assistant") {
							const m = e.message as AssistantMessage;
							input += m.usage.input;
							output += m.usage.output;
							cost += m.usage.cost.total;
						}
					}

					const branch = footerData.getGitBranch();
					const loc = shortCwd(ctx.cwd) + (branch ? ` (${branch})` : "");

					const pct = ctx.getContextUsage()?.percent;
					let ctxStr = pct == null ? "?%" : `${pct.toFixed(1)}%`;
					if (pct != null && pct > 90) ctxStr = theme.fg("error", ctxStr);
					else if (pct != null && pct > 70) ctxStr = theme.fg("warning", ctxStr);
					else ctxStr = theme.fg("dim", ctxStr);

					const stats = theme.fg("dim", `↑${fmt(input)} ↓${fmt(output)} $${cost.toFixed(3)} `) + ctxStr;

					const statuses = Array.from(footerData.getExtensionStatuses().entries())
						.sort(([a], [b]) => a.localeCompare(b))
						.map(([, t]) => t.replace(/\s+/g, " ").trim())
						.filter(Boolean)
						.join(" ");

					const sep = theme.fg("dim", " • ");
					let left = theme.fg("dim", loc) + sep + stats;
					if (statuses) left += sep + statuses;

					const model = ctx.model;
					let right = model?.id ?? "no-model";
					if (model?.reasoning) right += ` • ${pi.getThinkingLevel()}`;
					right = theme.fg("dim", right);

					// The model stays visible. The left side truncates first.
					const rightW = visibleWidth(right);
					const leftFit = truncateToWidth(left, Math.max(0, width - rightW - 2), theme.fg("dim", "…"));
					const pad = " ".repeat(Math.max(1, width - visibleWidth(leftFit) - rightW));
					return [truncateToWidth(leftFit + pad + right, width)];
				},
			};
		});
	};

	pi.on("session_start", async (_event, ctx) => {
		if (enabled) install(ctx);
	});

	pi.registerCommand("footer", {
		description: "Toggle the single-line footer",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			if (enabled) install(ctx);
			else ctx.ui.setFooter(undefined);
			ctx.ui.notify(enabled ? "Single-line footer on" : "Default footer restored", "info");
		},
	});
}

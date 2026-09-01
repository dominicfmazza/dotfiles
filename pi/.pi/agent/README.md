# pi configuration

Configuration for the [pi coding agent](https://pi.dev). `bootstrap.sh` links
this tree into `~/.pi/agent/`.

## What is here

| Path | What it does |
|---|---|
| `AGENTS.md` | Commit and merge request conventions. Every session reads it. |
| `keybindings.json` | TUI key bindings, with vi-style motions. |
| `package.json` | Registers the `subagent` extension and the prompt directory. |
| `extensions/subagent/` | Dispatch isolated pi subagents in single, parallel, or chain mode. |
| `agents/` | Three review agents: implementer, spec reviewer, quality reviewer. |
| `prompts/` | Four prompt templates: `/commit`, `/mr`, `/implement`, `/implement-and-review`. |

The agents declare no `model`. Each one inherits the model of the parent
session, so they work on any host and any provider.

## What is NOT here

These files hold a credential, a host endpoint, or machine state. The repo is
public, so it carries none of them. `bootstrap.sh` seeds a template instead,
and never overwrites an existing file.

| File | How it gets there |
|---|---|
| `auth.json` | Run `pi` and use `/login`. |
| `models.json` | Seeded from `install/templates/pi/models.json`. |
| `settings.json` | Seeded. pi rewrites it at runtime, so it is a copy, not a link. |
| `~/.config/mcp/mcp.json` | Seeded from `install/templates/pi/mcp.json`. |
| `trust.json`, `models-store.json`, `mcp-cache.json` | pi writes them as needed. |
| `sessions/`, `npm/`, `git/`, `bin/` | pi downloads and caches. |

`install/scan-secrets.sh` fails a commit that adds any of them. The bootstrap
installs that script as a `pre-commit` hook.

## Secrets

Keep every token in `~/.env.json`. mise loads that file into the environment,
so `models.json` can refer to `$PI_PROXY_API_KEY` and hold no literal value.

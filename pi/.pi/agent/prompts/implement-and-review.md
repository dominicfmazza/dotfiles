---
name: implement-and-review
description: Quick implementation flow, implementer then quality review
---

Implement the following task with the `subagent` tool, then review the result.

{{slot}}

Steps:

1. Dispatch the `implementer` agent. Put every piece of context in the prompt.
   The agent runs in an isolated window and cannot read a plan file.
2. Wait for the report. Accept DONE or DONE_WITH_CONCERNS.
3. Record the commit range with `git rev-parse HEAD~1` and `git rev-parse HEAD`.
4. Dispatch the `code-quality-reviewer` agent with that range.
5. Fix every Critical and Important issue before you report done.

This flow skips the spec compliance step. Use `/implement` when the task has a
written specification to check against.

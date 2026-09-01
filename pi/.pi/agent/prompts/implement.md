---
name: implement
description: Subagent-driven implementation flow, implementer then spec review then quality review
---

Implement the following task with the `subagent` tool.

{{slot}}

Steps:

1. Dispatch the `implementer` agent. Put every piece of context in the prompt.
   The agent runs in an isolated window and cannot read a plan file.
2. Wait for the report. Accept DONE or DONE_WITH_CONCERNS.
   Answer any BLOCKED or NEEDS_CONTEXT question, then dispatch again.
3. Record the commit range with `git rev-parse HEAD~1` and `git rev-parse HEAD`.
4. Dispatch the `spec-reviewer` agent. Give it the task text and the commit
   range. It verifies that nothing is missing and nothing is extra.
5. Dispatch the `code-quality-reviewer` agent with the same range.
6. Fix every Critical and Important issue before you report done.

Report the outcome of each step. Do not declare done while a review lists a
Critical or Important issue.

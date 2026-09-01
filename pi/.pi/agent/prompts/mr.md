---
description: Draft a clear merge request title and body
argument-hint: "[ticket-id]"
---
Review the changes on this branch against its target (`git log` and
`git diff` versus the base branch).

Draft a merge request that follows the rules in AGENTS.md.

Title: a valid Conventional Commit. Use the ticket ID ${1:-from the branch
name} as the scope when one exists.

Body: write for clarity with these sections only.

- Summary: one or two sentences. State the change and the reason.
- Changes: a short bullet list of the real changes.
- Impact: what a user or operator sees. Note breaking changes here.

Do not include test output, timing data, coverage numbers, or development
history. Link the ticket ID.

Show me the title and body before you create the MR.

---
description: Stage and commit with a Conventional Commit message
argument-hint: "[ticket-id]"
---
Review the staged diff (`git diff --cached`). If nothing is staged, review the
working tree (`git status` and `git diff`) and stage the related changes.

Write a Conventional Commit message that follows the rules in AGENTS.md:

- `type(scope): subject`, imperative mood, subject max 50 characters.
- Use the ticket ID ${1:-from the branch name} as the scope when one exists.
- Add a body that explains why, wrapped at 72 characters.

Show me the message before you commit.

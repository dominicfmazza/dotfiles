# Global conventions

## Commit messages

Use Conventional Commits for every commit.

Format: `type(scope): subject`

Rules:

- Subject uses the imperative mood. Example: "add", not "added".
- Subject max 50 characters. Do not end with a period.
- Scope holds the ticket ID when one exists. Example: `fix(LSW-123): ...`.
- Body wraps at 72 characters. Explain why, not what.
- A breaking change adds a `!` before the colon: `feat(API)!: drop v1`.
- A breaking change also adds a `BREAKING CHANGE:` footer.

Allowed types and their release impact:

| Type     | Release | Use for                          |
|----------|---------|----------------------------------|
| feat     | minor   | A new capability                 |
| fix      | patch   | A bug fix                        |
| perf     | patch   | A speed or memory improvement    |
| refactor | patch   | A change with no behavior change |
| revert   | patch   | A revert of an earlier commit    |
| build    | patch   | A build system or dependency change |
| test     | patch   | A test change                    |
| docs     | none    | A documentation change           |
| ci       | none    | A CI or pipeline change          |
| style    | none    | Formatting only, no code change  |
| chore    | none    | A maintenance task               |

## Merge requests

The MR title drives the release. Write the title as a valid Conventional
Commit. Use the same type, scope, and subject rules as a commit.

Write the MR body for clarity. A reader must understand the change fast.

Keep the body to these sections:

- Summary: one or two sentences. State the change and the reason.
- Changes: a short bullet list of the real changes.
- Impact: what a user or operator sees. Note breaking changes here.

Do not add:

- Test run output or pass/fail logs.
- Timing data or coverage percentages.
- Step-by-step development history.
- Screenshots of passing pipelines.
- Any content that does not help a reader understand the change.

Link the ticket ID in the body when one exists.

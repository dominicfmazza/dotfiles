# Global conventions

## Code comments

A comment explains the code. A comment does not explain the change.

The commit message and the MR body carry the history. A comment carries
only the facts a reader needs to understand the code as it stands.

Write a comment when the code cannot explain itself. Examples:

- A non-obvious constraint from an external system or a standard.
- A unit, a range, or a boundary that the type does not show.
- A reason for a workaround, with a ticket ID.
- An algorithm choice that a reader would question.

Do not write a comment that:

- Describes an edit. Example: "Add the tag guard."
- Refers to a past state. Examples: "Without this...", "Previously...",
  "This used to...", "Now we...", "Changed to...", "Fixed...".
- Names a bug that the code already fixes.
- Repeats what the next line says.
- Marks a section that a reader can see. Example: "Loop over items."

Test for a bad comment: read it without the diff. If it only makes sense
next to the old code, delete it.

Write a comment in the present tense. Describe the current behavior.

Bad, then good:

```yaml
# The rules mirror publish-int. Without the tag guard, a tag pipeline
# drops publish-int and the pipeline fails.
# -> publish-int supplies CFE_CMAKE_VERSION, so the rules must match.
```

```js
// Fixed the off-by-one here
// -> The API returns an inclusive end index.

// Now uses UTC
// -> Timestamps are UTC. The device clock is local.
```

Apply the same test to a docstring and to a rule file.

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

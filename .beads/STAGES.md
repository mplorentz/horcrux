# Beads labels and workflow (horcrux_app)

Issues use **three status values** (`open`, `in_progress`, `closed`). Workflow position is modeled with **labels** and the **`type`** field — not `type:*` labels.

## Issue `type` (native field)

| Value | Use |
|-------|-----|
| `feature` | New behavior or sizable UI work |
| `bug` | Fixes and regressions |
| `task` | Maintenance, deps, infra, chores |

Set with `bd create -t …` / `bd update <id> --type …` when supported.

## Stage labels (`stage:*`)

Rough order (feature path first; bugs often skip planning):

| Label | Meaning |
|-------|---------|
| `stage:triaged` | Captured / triaged |
| `stage:planning` | Agent building a plan (features) |
| `stage:plan-review` | Plan ready for human |
| `stage:implementing` | Coding (draft UI loop or bug theory loop) |
| `stage:cleanup` | Final implementation, tests, lints |
| `stage:pre-pr-review` | Human quick check before GitHub PR |
| `stage:pr-open` | PR exists |
| `stage:agent-fixing` | CI / Bugbot follow-up handled by agent |
| `stage:pr-review` | Human PR review |
| `stage:merge-ready` | Approved, ready to merge |
| `stage:cleanup-needed` | Post-merge cleanup (worktrees, docs) |

## Blocked labels (`blocked-on:*`)

| Label | Meaning |
|-------|---------|
| `blocked-on:human` | Waiting on you |
| `blocked-on:ci` | Waiting on CI |
| `blocked-on:agent` | Waiting on an agent |

## Custom metadata (recommended)

Issues that map to branches and GitHub PRs should set JSON metadata keys:

- `pr_url` — full PR URL
- `branch` — Git branch name
- `worktree` — absolute path to a checked-out git worktree (may be empty if none yet)

Example:

```bash
bd update <id> --metadata '{"pr_url":"…","branch":"…","worktree":"/path/to/tree"}'
```

Remove old stage / blocked labels when changing stage so only one primary `stage:*` and optional one `blocked-on:*` applies.

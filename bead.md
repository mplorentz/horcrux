# Add .fragua runtime dirs to .gitignore  (horcrux_app-khyj)
Status: in_progress  Assignee: fragua  Priority: 3
Branch: (none)

## Description
## Problem

The fragua workflow engine creates runtime artifacts in the repo root under .fragua/ — run worktrees (.fragua/worktrees/), blobs, the SQLite DB, and daemon state. None of these should ever be committed.

## Plan

Add to .gitignore:
- .fragua/runs/
- .fragua/worktrees/
- .fragua/blobs/
- .fragua/fragua.db*
- .fragua/daemon/

And add negative patterns so the committed project config IS tracked:
- !.fragua/config.yaml
- !.fragua/workflows/

## Acceptance criteria

- .fragua runtime artifacts (worktrees, blobs, db) are ignored by git
- .fragua/config.yaml is still trackable (not ignored)
No comments on horcrux_app-khyj

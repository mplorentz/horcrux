#!/usr/bin/env bash
# bd-ready — list beads issues blocked on you, then open Cursor in the right worktree.
# If metadata.pr_url is set, opens that PR in the default browser first, then Cursor.
#
# Usage:
#   ./scripts/bd-ready.sh              # interactive pick (numbered menu or fzf)
#   ./scripts/bd-ready.sh --list-only  # print table, exit
#
# Runs `bd list` against the nearest ancestor directory containing .beads/ (override with BEADS_REPO).
# Expects metadata.worktree / metadata.pr_url from your migration conventions (see .beads/STAGES.md).

set -euo pipefail

LIST_ONLY=false
# bd list excludes closed issues by default (--all would include them).
LABEL_FILTER=(--label blocked-on:human)

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" &>/dev/null || die "Missing required command: $1"
}

find_bead_repo() {
  local d="${1:-$(pwd -P)}"
  while [[ "$d" != "/" ]]; do
    if [[ -d "$d/.beads" ]]; then
      printf '%s\n' "$d"
      return 0
    fi
    d="$(dirname "$d")"
  done
  return 1
}

usage() {
  sed -n '1,12p' "$0"
}

while [[ "${1:-}" =~ ^(-h|--help)$ ]]; do
  usage
  exit 0
done

if [[ "${1:-}" == "--list-only" ]]; then
  LIST_ONLY=true
  shift || true
fi

REPO="${BEADS_REPO:-}"
if [[ -z "$REPO" ]]; then
  REPO="$(find_bead_repo "$(pwd -P)" || die "No .beads/ found from $(pwd); set BEADS_REPO or cd into the bead repo.")"
fi

CURSOR_CLI="${CURSOR_CLI:-cursor}"
require_cmd bd
require_cmd jq

cd "$REPO"

LIST_JSON="$(bd list --json --flat "${LABEL_FILTER[@]}" 2>/dev/null || true)"
if [[ -z "$LIST_JSON" || "$LIST_JSON" == "null" ]]; then
  LIST_JSON='[]'
fi

COUNT="$(jq 'if type == "array" then length else 0 end' <<<"$LIST_JSON")"
if [[ "$COUNT" -eq 0 ]]; then
  printf 'No active issues with blocked-on:human in %s\n' "$REPO"
  exit 0
fi

print_table() {
  jq -r '
    def stages: [.labels[]? | select(test("^stage:"))] | join(",");
    (.[] | [ .id, stages, (.metadata.worktree // ""), (.title | gsub("\\t";" ")), (.metadata.pr_url // "") ]
      | @tsv)' <<<"$LIST_JSON" |
    awk -F'\t' 'BEGIN { print "ID", "STAGE", "WORKTREE", "TITLE", "PR"; OFS="\t" }
      { $1=$1; print }'
}

if $LIST_ONLY; then
  print_table
  exit 0
fi

pick_id=""
if command -v fzf &>/dev/null; then
  # First column is issue id (hidden from display via --with-nth); preview shows bd show.
  mapfile -t FZF_LINES < <(
    jq -r '.[] | [.id, (.title | gsub("\\t";" ")), ([.labels[]? | select(test("^stage:"))] | join(",")), (.metadata.worktree // ""), (.metadata.pr_url // "")] | @tsv' <<<"$LIST_JSON"
  )
  if [[ ${#FZF_LINES[@]} -eq 1 ]]; then
    IFS=$'\t' read -r pick_id _ <<<"${FZF_LINES[0]}"
  else
    line=$(
      printf '%s\n' "${FZF_LINES[@]}" |
        fzf --with-nth=2.. --delimiter=$'\t' \
          --header='Pick an issue (blocked-on:human). Enter=open Cursor. Ctrl-C=cancel.' \
          --preview='bd --readonly show {1} 2>&1 || true' \
          --preview-window=right:55%:wrap
    ) || exit 0
    IFS=$'\t' read -r pick_id _ <<<"$line"
  fi
else
  printf 'Issues blocked on you (blocked-on:human) in %s:\n\n' "$REPO"
  i=1
  declare -a IDS
  while IFS=$'\t' read -r id title stage wt pr; do
    printf '  %2d) %s  [%s]\n      %s\n' "$i" "$id" "$stage" "$title"
    [[ -n "$wt" ]] && printf '      worktree: %s\n' "$wt"
    [[ -n "$pr" ]] && printf '      pr:       %s\n' "$pr"
    IDS[i]=$id
    ((i++)) || true
  done < <(
    jq -r '.[] | [.id, (.title | gsub("\\t";" ")), ([.labels[]? | select(test("^stage:"))] | join(",")), (.metadata.worktree // ""), (.metadata.pr_url // "")] | @tsv' <<<"$LIST_JSON"
  )
  printf '\nEnter number (1-%d), or q to quit: ' "$((i - 1))"
  read -r choice
  [[ "$choice" == [qQ]* ]] && exit 0
  [[ "$choice" =~ ^[0-9]+$ ]] || die "Invalid choice"
  ((choice >= 1 && choice < i)) || die "Out of range"
  pick_id="${IDS[choice]}"
fi

[[ -n "$pick_id" ]] || die "No issue selected."

ROW="$(jq -c --arg id "$pick_id" '.[] | select(.id == $id)' <<<"$LIST_JSON")"
WT="$(jq -r '.metadata.worktree // empty' <<<"$ROW")"
PR="$(jq -r '.metadata.pr_url // empty' <<<"$ROW")"
BR="$(jq -r '.metadata.branch // empty' <<<"$ROW")"

maybe_open_browser() {
  local url="$1"
  [[ -z "$url" ]] && return 0
  if command -v open &>/dev/null; then
    open "$url" 2>/dev/null || true
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$url" 2>/dev/null || true
  fi
}

open_pr_if_any() {
  [[ -z "$PR" ]] && return 0
  printf 'Opening PR in browser: %s\n' "$PR"
  maybe_open_browser "$PR"
}

command -v "$CURSOR_CLI" &>/dev/null || die "Cursor CLI not found (install shell command from Cursor app, or set CURSOR_CLI)."

open_pr_if_any

if [[ -n "$WT" && -d "$WT" ]]; then
  printf 'Opening Cursor: %s (issue %s)\n' "$WT" "$pick_id"
  "$CURSOR_CLI" "$WT"
  exit 0
fi

printf 'Issue %s has no usable worktree (path missing or unset).\n' "$pick_id" >&2
[[ -n "$WT" ]] && printf 'Recorded path was: %s\n' "$WT" >&2
[[ -n "$BR" ]] && printf 'branch: %s\n' "$BR" >&2
printf 'Opening Cursor: %s (main repo; issue %s)\n' "$REPO" "$pick_id"
"$CURSOR_CLI" "$REPO"

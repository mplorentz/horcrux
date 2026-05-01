#!/usr/bin/env bash
# bd-ready — list actionable beads (PR pipeline / blocked-on:human, excluding blocked-on:ci), sync from GitHub, open Cursor.
#
# Sync (default): for open issues with metadata.pr_url and stage in the PR pipeline, runs
#   gh pr view and updates stage:/blocked-on: labels — CI pending → blocked-on:ci, failure →
#   agent-fixing + blocked-on:agent, success (when was pr-open or agent-fixing) → pr-review +
#   blocked-on:human, merged PR → cleanup-needed.
#
# Usage:
#   ./scripts/bd-ready.sh                # sync + interactive pick (numbered menu or fzf)
#   ./scripts/bd-ready.sh --list-only  # sync + print table, exit
#   ./scripts/bd-ready.sh --no-sync    # skip GitHub sync
#
# Runs `bd list` against the nearest ancestor directory containing .beads/ (override with BEADS_REPO).
# Expects metadata.worktree / metadata.pr_url (see .beads/STAGES.md). Requires `gh` when sync is enabled.

set -euo pipefail

LIST_ONLY=false
NO_SYNC=false
# bd list excludes closed issues by default (--all would include them).
# Include in_progress so claimed issues (bd update --claim) still appear.
# Override with BD_READY_STATUSES if needed (comma-separated bd status values).
BD_READY_STATUSES="${BD_READY_STATUSES:-open,in_progress}"

PR_PIPELINE_LABELS=(
  blocked-on:human
  stage:pr-open
  stage:agent-fixing
  stage:pr-review
  stage:merge-ready
  stage:cleanup-needed
)

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
  sed -n '1,20p' "$0"
}

# Args
while [[ "${1:-}" =~ ^(-h|--help)$ ]]; do
  usage
  exit 0
done

if [[ "${1:-}" == "--list-only" ]]; then
  LIST_ONLY=true
  shift || true
fi

if [[ "${1:-}" == "--no-sync" ]]; then
  NO_SYNC=true
  shift || true
fi

if [[ -n "${BD_READY_NO_SYNC:-}" ]]; then
  NO_SYNC=true
fi

REPO="${BEADS_REPO:-}"
if [[ -z "$REPO" ]]; then
  REPO="$(find_bead_repo "$(pwd -P)" || die "No .beads/ found from $(pwd); set BEADS_REPO or cd into the bead repo.")"
fi

CURSOR_CLI="${CURSOR_CLI:-cursor}"
require_cmd bd
require_cmd jq

cd "$REPO"

# --- GitHub PR → bead label sync ---

gh_pr_classify() {
  local json_file="$1"
  jq -r '
    if (.mergedAt != null) and (.mergedAt != "") then "merged"
    elif (.state | ascii_upcase) != "OPEN" then "closed"
    else
      (.statusCheckRollup // []) as $r |
      if ($r | length) == 0 then "success"
      elif ($r | any(.status != "COMPLETED")) then "pending"
      elif ($r | any(((.conclusion // "") != "") and (.conclusion != "SUCCESS") and (.conclusion != "SKIPPED"))) then "failed"
      else "success"
      end
    end
  ' "$json_file"
}

issue_primary_stage() {
  local row_json="$1"
  jq -r '[.labels[]? | select(test("^stage:"))] | first // empty' <<<"$row_json"
}

labels_desired_from_pr_classify() {
  local row_json="$1"
  local classify="$2"
  local stage_now
  stage_now="$(issue_primary_stage "$row_json")"

  case "$classify" in
  merged)
    printf '%s\n' 'stage:cleanup-needed'
    ;;
  closed)
    printf '%s\n' ''
    ;;
  pending)
    if [[ "$stage_now" == "stage:merge-ready" ]]; then
      printf '%s\n' "$stage_now"
      printf '%s\n' 'blocked-on:ci'
    else
      if [[ -z "$stage_now" || "$stage_now" == "stage:pr-open" ]]; then
        printf '%s\n' 'stage:pr-open'
      else
        printf '%s\n' "$stage_now"
      fi
      printf '%s\n' 'blocked-on:ci'
    fi
    ;;
  failed)
    printf '%s\n' 'stage:agent-fixing'
    printf '%s\n' 'blocked-on:agent'
    ;;
  success)
    if [[ "$stage_now" == "stage:merge-ready" ]]; then
      printf '%s\n' 'stage:merge-ready'
    elif [[ "$stage_now" == "stage:pr-review" ]]; then
      printf '%s\n' 'stage:pr-review'
      printf '%s\n' 'blocked-on:human'
    elif [[ "$stage_now" == "stage:pr-open" || "$stage_now" == "stage:agent-fixing" ]]; then
      printf '%s\n' 'stage:pr-review'
      printf '%s\n' 'blocked-on:human'
    else
      # Unknown stage with PR URL — do not force a stage
      printf '%s\n' ''
    fi
    ;;
  *)
    printf '%s\n' ''
    ;;
  esac
}

normalize_stage_blocked_labels() {
  local desired_stage="$1"
  local desired_blocked="$2"
  local row_json="$3"
  local -a keep
  mapfile -t keep < <(jq -r '.labels[]? | select(test("^stage:") | not) | select(test("^blocked-on:") | not)' <<<"$row_json")
  local -a out=("${keep[@]}")
  [[ -n "$desired_stage" ]] && out+=("$desired_stage")
  [[ -n "$desired_blocked" ]] && out+=("$desired_blocked")
  # Sort for stable compare
  if [[ ${#out[@]} -eq 0 ]]; then
    printf '%s\n' ''
    return
  fi
  printf '%s\n' "${out[@]}" | sort -u | paste -sd'|' -
}

labels_need_update() {
  local row_json="$1"
  local desired_norm="$2"
  local cur_norm
  cur_norm="$(jq -r '
    .labels // [] | sort | join("|")
  ' <<<"$row_json")"
  [[ "$cur_norm" != "$desired_norm" ]]
}

sync_github_pr_stages() {
  if $NO_SYNC; then
    return 0
  fi
  if ! command -v gh &>/dev/null; then
    printf 'bd-ready: skipping PR sync (install gh CLI)\n' >&2
    return 0
  fi
  if ! gh auth status &>/dev/null; then
    printf 'bd-ready: skipping PR sync (gh not authenticated)\n' >&2
    return 0
  fi

  local sync_json
  sync_json="$(
    bd list --json --flat --status "$BD_READY_STATUSES" --limit 0 \
      --has-metadata-key pr_url \
      --label-any stage:pr-open,stage:agent-fixing,stage:pr-review,stage:merge-ready \
      2>/dev/null || true
  )"
  if [[ -z "$sync_json" || "$sync_json" == "null" ]]; then
    sync_json='[]'
  fi

  local count
  count="$(jq 'if type == "array" then length else 0 end' <<<"$sync_json")"
  if [[ "$count" -eq 0 ]]; then
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN

  local idx
  for ((idx = 0; idx < count; idx++)); do
    local -a _desired=()
    local row pr_url id classify desired_stage desired_blocked desired_norm cur_stage
    row="$(jq -c ".[$idx]" <<<"$sync_json")"
    id="$(jq -r '.id' <<<"$row")"
    pr_url="$(jq -r '.metadata.pr_url // empty' <<<"$row")"
    [[ -z "$pr_url" ]] && continue

    if ! gh pr view "$pr_url" --json state,mergedAt,statusCheckRollup >"$tmp" 2>/dev/null; then
      printf 'bd-ready: warn: gh pr view failed for %s (issue %s)\n' "$pr_url" "$id" >&2
      continue
    fi

    classify="$(gh_pr_classify "$tmp")"
    if [[ "$classify" == "closed" ]]; then
      continue
    fi

    mapfile -t _desired < <(labels_desired_from_pr_classify "$row" "$classify")
    if [[ "$classify" == "merged" ]]; then
      desired_stage="${_desired[0]:-}"
      desired_blocked=""
    elif [[ ${#_desired[@]} -ge 2 ]]; then
      desired_stage="${_desired[0]:-}"
      desired_blocked="${_desired[1]:-}"
    elif [[ ${#_desired[@]} -eq 1 ]]; then
      desired_stage="${_desired[0]:-}"
      desired_blocked=""
    else
      desired_stage=""
      desired_blocked=""
    fi

    if [[ -z "$desired_stage" && "$classify" != "closed" ]]; then
      continue
    fi

    desired_norm="$(normalize_stage_blocked_labels "$desired_stage" "$desired_blocked" "$row")"
    if ! labels_need_update "$row" "$desired_norm"; then
      continue
    fi

    cur_stage="$(issue_primary_stage "$row")"
    printf 'bd-ready: %s issue %s (%s → labels: %s' "$classify" "$id" "${cur_stage:-none}" "$desired_stage"
    [[ -n "$desired_blocked" ]] && printf ', %s' "$desired_blocked"
    printf ')\n'

    local -a rm_args=()
    local lbl
    while IFS= read -r lbl; do
      [[ -n "$lbl" ]] && rm_args+=(--remove-label "$lbl")
    done < <(jq -r '.labels[]? | select(test("^stage:") or test("^blocked-on:"))' <<<"$row")

    local -a add_args=()
    [[ -n "$desired_stage" ]] && add_args+=(--add-label "$desired_stage")
    [[ -n "$desired_blocked" ]] && add_args+=(--add-label "$desired_blocked")

    if [[ ${#rm_args[@]} -gt 0 || ${#add_args[@]} -gt 0 ]]; then
      bd update "$id" "${rm_args[@]}" "${add_args[@]}"
    fi
  done
}

sync_github_pr_stages

LIST_JSON="$(
  bd list --json --flat --status "$BD_READY_STATUSES" --limit 0 \
    --label-any "$(IFS=,; echo "${PR_PIPELINE_LABELS[*]}")" \
    --exclude-label blocked-on:ci \
    2>/dev/null || true
)"
if [[ -z "$LIST_JSON" || "$LIST_JSON" == "null" ]]; then
  LIST_JSON='[]'
fi

COUNT="$(jq 'if type == "array" then length else 0 end' <<<"$LIST_JSON")"
if [[ "$COUNT" -eq 0 ]]; then
  printf 'No actionable issues (PR-pipeline labels, excluding blocked-on:ci) in %s\n' "$REPO"
  exit 0
fi

print_table() {
  jq -r '
    (.[] | [
      .id,
      ([.labels[]? | select(test("^stage:"))] | join(",")),
      ([.labels[]? | select(test("^blocked-on:"))] | join(",")),
      (.metadata.worktree // ""),
      (.title | gsub("\\t";" ")),
      (.metadata.pr_url // "")
    ] | @tsv)' <<<"$LIST_JSON" |
    awk -F'\t' 'BEGIN { print "ID", "STAGE", "BLOCKED", "WORKTREE", "TITLE", "PR"; OFS="\t" }
      { $1=$1; print }'
}

if $LIST_ONLY; then
  print_table
  exit 0
fi

pick_id=""
if command -v fzf &>/dev/null; then
  mapfile -t FZF_LINES < <(
    jq -r '.[] | [.id, (.title | gsub("\\t";" ")), ([.labels[]? | select(test("^stage:"))] | join(",")), ([.labels[]? | select(test("^blocked-on:"))] | join(",")), (.metadata.worktree // ""), (.metadata.pr_url // "")] | @tsv' <<<"$LIST_JSON"
  )
  if [[ ${#FZF_LINES[@]} -eq 1 ]]; then
    IFS=$'\t' read -r pick_id _ <<<"${FZF_LINES[0]}"
  else
    line=$(
      printf '%s\n' "${FZF_LINES[@]}" |
        fzf --with-nth=2.. --delimiter=$'\t' \
          --header='Pick an issue (actionable; not waiting on CI). Enter=open Cursor. Ctrl-C=cancel.' \
          --preview='bd --readonly show {1} 2>&1 || true' \
          --preview-window=right:55%:wrap
    ) || exit 0
    IFS=$'\t' read -r pick_id _ <<<"$line"
  fi
else
  printf 'Issues (actionable; not blocked-on:ci) in %s:\n\n' "$REPO"
  i=1
  declare -a IDS
  while IFS=$'\t' read -r id title stage blocked wt pr; do
    printf '  %2d) %s  [%s]' "$i" "$id" "$stage"
    [[ -n "$blocked" ]] && printf ' (%s)' "$blocked"
    printf '\n      %s\n' "$title"
    [[ -n "$wt" ]] && printf '      worktree: %s\n' "$wt"
    [[ -n "$pr" ]] && printf '      pr:       %s\n' "$pr"
    IDS[i]=$id
    ((i++)) || true
  done < <(
    jq -r '.[] | [.id, (.title | gsub("\\t";" ")), ([.labels[]? | select(test("^stage:"))] | join(",")), ([.labels[]? | select(test("^blocked-on:"))] | join(",")), (.metadata.worktree // ""), (.metadata.pr_url // "")] | @tsv' <<<"$LIST_JSON"
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

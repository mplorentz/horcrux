#!/usr/bin/env bash
# Used by `.github/workflows/drift-schema-version.yml` (pull_request only).
# No Dart/Flutter build — only git + jq. If drift schema snapshots under drift_schemas/
# change in meaning, lib/database/app_database.dart must edit schemaVersion
# (and typically add onUpgrade). Parity-only tests do not catch same-version
# table additions — developers can re-dump drift_schema_vN.json while leaving
# schemaVersion at N.
set -euo pipefail

base="${1:?usage: check-drift-schema-version-bump.sh <base_sha>}"
head="${2:-HEAD}"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required for semantic JSON comparison" >&2
  exit 1
fi

semantic_change=false
while IFS= read -r f; do
  [[ -n "${f:-}" ]] || continue
  if [[ "$f" != drift_schemas/*.json ]]; then
    semantic_change=true
    break
  fi
  if [[ ! -f "$f" ]]; then
    semantic_change=true
    break
  fi
  if ! git cat-file -e "$base:$f" 2>/dev/null; then
    semantic_change=true
    break
  fi
  old_json="$(git show "$base:$f" | jq -cS .)"
  new_json="$(jq -cS . <"$f")"
  if [[ "$old_json" != "$new_json" ]]; then
    semantic_change=true
    break
  fi
done < <(git diff --name-only "$base...$head" -- drift_schemas/ || true)

if [[ "$semantic_change" != true ]]; then
  exit 0
fi

if git diff -U0 "$base...$head" -- lib/database/app_database.dart | grep -E '^[+-]' | grep -q 'schemaVersion'; then
  echo "OK: drift_schemas/ changed semantically and app_database.dart touches schemaVersion."
  exit 0
fi

echo "::error::drift_schemas/ changed in a way that updates the serialized drift schema, but lib/database/app_database.dart does not modify the schemaVersion getter." >&2
echo "Bump int get schemaVersion => …, add MigrationStrategy.onUpgrade for existing installs, then:" >&2
echo "  dart run drift_dev schema dump lib/database/app_database.dart drift_schemas/" >&2
exit 1

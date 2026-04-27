#!/bin/bash
# Copy gitignored platform config files from the main worktree into the current worktree.
# Run this after entering a new worktree: scripts/setup-worktree.sh

set -e

main=$(git worktree list | head -1 | awk '{print $1}')

if [ "$main" = "$(pwd)" ]; then
  echo "Already in the main worktree — nothing to copy."
  exit 0
fi

copied=0
missing=0

copy_file() {
  local src="$main/$1"
  local dst="$1"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  ✓ $1"
    ((copied++)) || true
  else
    echo "  ✗ $1 (not found in main worktree)"
    ((missing++)) || true
  fi
}

echo "Copying gitignored config files from main worktree..."
echo "  Main: $main"
echo "  Here: $(pwd)"
echo ""

copy_file "ios/Runner/GoogleService-Info.plist"
copy_file "macos/Runner/GoogleService-Info.plist"
copy_file "android/app/google-services.json"
copy_file "android/key.properties"

echo ""
echo "Done ($copied copied, $missing missing)."

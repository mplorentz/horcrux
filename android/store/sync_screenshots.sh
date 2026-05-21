#!/usr/bin/env bash
# Copies Play Store golden PNGs into android/store/screenshots/.
#
# File names: {screenshot}_{device}.png
#   e.g. 01_vault_list_phone.png, 03_manage_recovery_tablet_10in.png
#
# Run after updating goldens:
#   fvm flutter test test/screens/play_store_screenshots_golden_test.dart --update-goldens
#   android/store/sync_screenshots.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GOLDENS="$ROOT/test/screens/goldens"
STORE="$ROOT/android/store/screenshots"

mkdir -p "$STORE"

shopt -s nullglob
for golden in "$GOLDENS"/{01,02,03}_*.png; do
  name="$(basename "$golden")"
  case "$name" in
    *_phone.png | *_tablet_7in.png | *_tablet_10in.png)
      cp "$golden" "$STORE/$name"
      echo "→ $name"
      ;;
  esac
done

echo "Done. Store screenshots synced to $STORE"

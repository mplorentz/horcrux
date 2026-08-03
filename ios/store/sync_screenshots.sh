#!/usr/bin/env bash
# Copies App Store golden PNGs into ios/store/screenshots/.
#
# File names: {screenshot}_{device}.png
#   e.g. 00_onboarding_iphone_6_9in.png, 03_manage_recovery_ipad_13in.png
#
# Run after updating goldens:
#   fvm flutter test test/screens/app_store_screenshots_golden_test.dart --update-goldens
#   ios/store/sync_screenshots.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GOLDENS="$ROOT/test/screens/goldens"
STORE="$ROOT/ios/store/screenshots"

mkdir -p "$STORE"

shopt -s nullglob
rm -f "$STORE"/{00,01,02,03}_*_iphone_6_9in.png \
      "$STORE"/{00,01,02,03}_*_iphone_6_7in.png \
      "$STORE"/{00,01,02,03}_*_ipad_13in.png

for golden in "$GOLDENS"/{00,01,02,03}_*.png; do
  name="$(basename "$golden")"
  case "$name" in
    *_iphone_6_9in.png | *_iphone_6_7in.png | *_ipad_13in.png)
      cp "$golden" "$STORE/$name"
      echo "→ $name"
      ;;
  esac
done

echo "Done. Store screenshots synced to $STORE"

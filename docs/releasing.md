# Releasing

The release flow uses fastlane. All release notes are read from the `## [Unreleased]` section of [CHANGELOG.md](../CHANGELOG.md) and attached to each channel automatically.

## Flow

```bash
# 1. Set the marketing version (keeps the existing build number — no bump)
bundle exec fastlane set_version version:1.0.1

# 2. Bump the build once and ship to all beta channels:
#    iOS TestFlight, Google Play internal testing, and a GitHub beta pre-release.
bundle exec fastlane ship_beta_all

# ... beta testing ...

# 3. Once the build is approved and released to production:
#    renames [Unreleased] -> [1.0.1] in CHANGELOG.md, commits + pushes,
#    and creates a production GitHub release tagged v1.0.1.
bundle exec fastlane stamp_release
```

## Channels

| Channel | How notes are attached |
|---|---|
| iOS TestFlight | `changelog:` passed inline to `upload_to_testflight` (links stripped for plain-text rendering) |
| Google Play (internal) | Written to `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt` before upload (Play is file-based only; listing copy untouched) |
| GitHub beta | Changelog body on the `v<version>-<build>` pre-release |
| GitHub production | Changelog body on the `v<version>` release (created by `stamp_release`) |

## Prerequisites

- App Store Connect API key (`.env`: `APP_STORE_KEY_ID`, `APP_STORE_ISSUER_ID`, `APP_STORE_KEY_FILEPATH`)
- `GOOGLE_PLAY_JSON_KEY_PATH` (Play service account JSON — not the Firebase `google-services.json`)
- `GITHUB_REPOSITORY` (`owner/repo`) and `GITHUB_TOKEN` (or `GH_TOKEN`)

## Adding a changelog entry

Add a line under `## [Unreleased]` → `### Release Notes` (user-facing) or `### Internal Changes` in [CHANGELOG.md](../CHANGELOG.md), with a link to the PR. Trivial changes (string edits, dep bumps, refactors) can skip the changelog.

# Releasing

The release flow uses fastlane. All release notes are read from the `## [Unreleased]` section of [CHANGELOG.md](../CHANGELOG.md) and attached to each channel automatically.

## Flow

- Make some commits

- Set the marketing version
```bash
# Set the marketing version (keeps the existing build number — no bump)
bundle exec fastlane set_version version:1.0.1
```

- Tag & upload builds to beta channels
```bash
# iOS TestFlight, Google Play internal testing, and a GitHub beta pre-release.
bundle exec fastlane ship_beta_all
```

- Manually submit builds for beta review through TestFlight and Google Play websites

- After build passes beta testing, submit builds for production review.

- Once approved, tag production release on Github

- Update changelog:

```
# renames [Unreleased] -> [1.0.1] in CHANGELOG.md, commits + pushes,
# and creates a production GitHub release tagged v1.0.1.
bundle exec fastlane stamp_release
```

- Click release buttons in App Store Connect and Google Play

- Upload to zap store

```zsp publish```

## Prerequisites

- App Store Connect API key (`.env`: `APP_STORE_KEY_ID`, `APP_STORE_ISSUER_ID`, `APP_STORE_KEY_FILEPATH`)
- `GOOGLE_PLAY_JSON_KEY_PATH` (Play service account JSON — not the Firebase `google-services.json`)
- `GITHUB_REPOSITORY` (`owner/repo`) and `GITHUB_TOKEN` (or `GH_TOKEN`)

## Adding a changelog entry

Add a line under `## [Unreleased]` → `### Release Notes` (user-facing) or `### Internal Changes` in [CHANGELOG.md](../CHANGELOG.md), with a link to the PR. Trivial changes (string edits, dep bumps, refactors) can skip the changelog.

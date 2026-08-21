# Changelog

All notable changes to this project will be documented in this file.

We define "Noteworthy changes" as 1) user-facing features or bugfixes 2) significant technical or architectural changes that contributors will notice. If your Pull Request does not contain any changes of this nature — i.e. minor string/translation changes, patch releases of dependencies, refactors, etc. — then add the `Skip-Changelog` label.

The **Release Notes** section is for changes that are relevant to users and that they should know about. The **Internal Changes** section is for other changes that are not visible to users since the changes may not be relevant to them, e.g. technical improvements, but that developers should still be aware of.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Release Notes
- Fixed: invitation links failed to open when the vault or owner name contained a non-ASCII character, such as an iOS curly apostrophe (`’`). [#299](https://github.com/mplorentz/horcrux/pull/299)
- Fixed: the app now connects to auth-enabled Nostr relays using eager NIP-42 authentication. [#301](https://github.com/mplorentz/horcrux/pull/301)
- Changed: invitation links now use a query-parameter format, while remaining backwards-compatible with the previous path format. [#300](https://github.com/mplorentz/horcrux/pull/300)
- Fixed: duplicate notifications when stewards confirmed their shares — background delivery no longer emits duplicate local notifications across notification types. [#304](https://github.com/mplorentz/horcrux/pull/304)
- Fixed: a steward could appear as "Awaiting New Key" after acknowledging the current key, when a stale older acknowledgement was processed after the newer one and overwrote it. [#307](https://github.com/mplorentz/horcrux/pull/307)

### Internal Changes
- Replaced `CLAUDE.md` with a redirect to `AGENTS.md`. [#306](https://github.com/mplorentz/horcrux/pull/306)
- Added `.fragua` runtime directories to `.gitignore`. [#303](https://github.com/mplorentz/horcrux/pull/303)

## [1.0.0] - 2026-08-05Z

### Release Notes
- Initial public release of Horcrux: backup and recovery of sensitive data using Shamir's Secret Sharing, distributed to friends and family via the Nostr protocol.

### Internal Changes
- First tagged release.

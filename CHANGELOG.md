# Changelog

All notable changes to this project will be documented in this file.

We define "Noteworthy changes" as 1) user-facing features or bugfixes 2) significant technical or architectural changes that contributors will notice. If your Pull Request does not contain any changes of this nature — i.e. minor string/translation changes, patch releases of dependencies, refactors, etc. — then add the `Skip-Changelog` label.

The **Release Notes** section is for changes that are relevant to users and that they should know about. The **Internal Changes** section is for other changes that are not visible to users since the changes may not be relevant to them, e.g. technical improvements, but that developers should still be aware of.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2026-08-26

### Release Notes

- Fixed: duplicate notifications when app is running in the background. [#304](https://github.com/mplorentz/horcrux/pull/304)
- Fixed: a steward could appear as "Awaiting New Key" after acknowledging the current key. [#307](https://github.com/mplorentz/horcrux/pull/307)
- Fixed: invitation links failed to open when the vault or owner name contained a non-ASCII character. [#299](https://github.com/mplorentz/horcrux/pull/299)
- Fixed: compatibility with some relay authentication implementations. [#301](https://github.com/mplorentz/horcrux/pull/301)
- Added: Parsing logic for new invitation link format. [#300](https://github.com/mplorentz/horcrux/pull/300)

## [1.0.0] - 2026-08-05Z

### Release Notes
- Initial public release: Back up your secrets to friends and family.

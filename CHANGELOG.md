# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-07-23

Initial release. A `custom_lint` plugin that detects disposal-based memory
leaks in Flutter `State` classes and offers one-click fixes.

### Added

- **`missing_dispose`** — flags disposable controllers/notifiers
  (`AnimationController`, `TextEditingController`, `ScrollController`,
  `TabController`, `PageController`, `FocusNode`, `ValueNotifier`, and more)
  that are never disposed in `State.dispose()`.
- **`uncancelled_subscription`** — flags `StreamSubscription` fields that are
  never cancelled.
- **`uncancelled_timer`** — flags `Timer` fields that are never cancelled.
- One-click quick-fix for every rule: injects the correct release call
  (`dispose()` / `cancel()`) into `dispose()`, creating the method if absent.
- Example project wired with `expect_lint` assertions that double as the
  integration test.

[Unreleased]: https://github.com/FlutterForge-V1/leak_sentinel/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/FlutterForge-V1/leak_sentinel/releases/tag/v0.1.0

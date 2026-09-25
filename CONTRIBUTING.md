# Contributing to leak_sentinel

Thanks for helping make Flutter apps leak less! This project is part of
[OpenForge](https://github.com/openforge-oss), and community contributions —
especially new leak patterns you've hit in real apps — are the whole point.

## Ground rules

- Be kind. We follow the [Code of Conduct](CODE_OF_CONDUCT.md).
- One logical change per pull request.
- Every rule ships with example coverage. No exceptions — the examples *are* the
  test suite (see below).

## Getting set up

You need the Flutter SDK (which bundles Dart). Then:

```bash
git clone https://github.com/openforge-oss/leak_sentinel
cd leak_sentinel

# Resolve the plugin package
dart pub get

# Resolve the example (a Flutter app that consumes the plugin by path)
cd example && flutter pub get && cd ..
```

## The dev loop

```bash
# 1. Static-check the plugin itself
dart analyze
dart format .
dart test

# 2. Run the plugin against the example to see your rule fire
cd example
dart run custom_lint          # list issues
dart run custom_lint --fix    # try your quick-fix
```

## How the code is organised

```
lib/
  leak_sentinel.dart          # createPlugin() — registers the rules
  src/
    release_rule.dart         # ReleaseRule base + the shared quick-fix + AST helpers
    rules/
      missing_dispose.dart    # each rule ≈ a LintCode + a type set + a release verb
      uncancelled_subscription.dart
      uncancelled_timer.dart
example/
  lib/examples.dart           # BAD + GOOD widgets, annotated with expect_lint
```

Every rule that means "a `State` owns a resource and must release it in
`dispose()`" is just a subclass of `ReleaseRule`:

```dart
class UncancelledTimer extends ReleaseRule {
  const UncancelledTimer()
      : super(code: _code, releaseMethod: 'cancel', resourceTypes: const {'Timer'});

  static const _code = LintCode(
    name: 'uncancelled_timer',
    problemMessage: '…',
    correctionMessage: '…',
    errorSeverity: ErrorSeverity.WARNING,
  );
}
```

Then register it in `lib/leak_sentinel.dart`.

## Testing your change (this is also our CI gate)

We assert lints with inline `// expect_lint: <rule_name>` comments in
`example/lib/examples.dart`. Add a widget that should trigger your rule and mark
the offending line; add a matching "clean" widget that must **not** trigger it.

```dart
// expect_lint: uncancelled_timer
late final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {});
```

Then:

```bash
cd example && dart run custom_lint
```

A green run means every `expect_lint` matched and nothing spurious fired. CI
runs exactly this, so if it's green locally it'll be green on the PR.

## Branches & PR flow

- Cut feature branches from `develop`: `feat/removelistener-rule`, `fix/...`.
- Open your PR against `develop`. `main` is the released, protected branch.
- Fill in the PR template. Green CI + one maintainer approval merges.
- Add a bullet to the `[Unreleased]` section of [CHANGELOG.md](CHANGELOG.md).

## Releasing to pub.dev (maintainers)

Releases are automated via GitHub Actions using pub.dev's OIDC publishing — no
tokens or secrets. The workflow is
[`.github/workflows/publish.yml`](.github/workflows/publish.yml), triggered by a
version tag.

**One-time setup** (done for the initial release): on pub.dev →
`leak_sentinel` → **Admin → Automated publishing**, enable *Publishing from
GitHub Actions* with repository `openforge-oss/leak_sentinel` and tag pattern
`v{{version}}`.

**To cut a release:**

1. Bump `version:` in [`pubspec.yaml`](pubspec.yaml) (follow semver).
2. Move the `[Unreleased]` notes in [`CHANGELOG.md`](CHANGELOG.md) under a new
   version heading with today's date.
3. Land those on `main` via PR.
4. Sanity-check, then tag and push:
   ```bash
   dart pub publish --dry-run    # must report 0 warnings
   git checkout main && git pull
   git tag v0.1.1                 # must match the new pubspec version
   git push origin v0.1.1
   ```
5. The **Publish to pub.dev** workflow validates and publishes automatically —
   watch it under the repo's **Actions** tab.

The very first publish was done manually with `dart pub publish` (automated
publishing can only be configured once a package exists).

## Coding standards

- `dart format` clean (CI enforces `--set-exit-if-changed`).
- `dart analyze` reports **no** issues (CI runs `--fatal-infos`).
- Prefer syntactic (AST) detection over the analyzer element model unless a rule
  genuinely needs resolved types — it keeps us resilient across SDK bumps.

Questions? Open a [discussion or issue](https://github.com/openforge-oss/leak_sentinel/issues).

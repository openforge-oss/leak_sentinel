# 🛡️ leak_sentinel

[![pub package](https://img.shields.io/pub/v/leak_sentinel.svg)](https://pub.dev/packages/leak_sentinel)
[![CI](https://github.com/openforge-oss/leak_sentinel/actions/workflows/ci.yaml/badge.svg)](https://github.com/openforge-oss/leak_sentinel/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![style: custom_lint](https://img.shields.io/badge/style-custom__lint-navy)](https://pub.dev/packages/custom_lint)

> A [`custom_lint`](https://pub.dev/packages/custom_lint) plugin that hunts down
> **disposal-based memory leaks** in Flutter — undisposed controllers,
> uncancelled subscriptions and timers — and fixes them with one click, in your
> IDE and in CI.

Part of [**OpenForge**](https://github.com/openforge-oss) — open-source
solutions to the problems developers hit across frameworks. `leak_sentinel` is
OpenForge's Flutter/Dart tool.

---

## Why this exists

Dart is garbage-collected, so you never `free()` anything. But Flutter is full
of objects that own resources the GC can't reclaim on its own — a
`StreamSubscription` keeps its callback (and everything it captures) alive for
the life of the stream; an `AnimationController` holds a `Ticker` bound to the
`SchedulerBinding`; a periodic `Timer` keeps firing after its widget is gone.

The fix is always the same — release them in `State.dispose()` — and the bug is
always the same: someone forgot. `leak_sentinel` finds the ones you forgot.

## What it catches

| Rule | Flags a `State` field that… | Quick-fix |
|------|------------------------------|-----------|
| `missing_dispose` | is a disposable controller/notifier (`AnimationController`, `TextEditingController`, `ScrollController`, `TabController`, `PageController`, `FocusNode`, `ValueNotifier`, …) never passed to `dispose()` | inserts `field.dispose()` |
| `uncancelled_subscription` | is a `StreamSubscription` never `cancel()`-ed | inserts `field.cancel()` |
| `uncancelled_timer` | is a `Timer` never `cancel()`-ed | inserts `field.cancel()` |

Each rule understands `dispose()` — if you already release the resource
anywhere in that method (including `field?.dispose()`), it stays quiet.

## Quick start

Add the plugin and the `custom_lint` runner as dev dependencies:

```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.8.0
  leak_sentinel: ^0.1.0
```

Enable `custom_lint` in your analyzer config:

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint
```

That's it. Open any file in an IDE with the Dart plugin and leaks show up as
warnings with a 💡 quick-fix. From the terminal:

```bash
dart run custom_lint        # report every leak
dart run custom_lint --fix  # report and auto-fix them
```

## The auto-fix in action

Before — a `State` with two leaks and no `dispose()`:

```dart
class _FixMeState extends State<FixMe> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

After `dart run custom_lint --fix`:

```dart
class _FixMeState extends State<FixMe> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }
}
```

The fix creates `dispose()` if it's missing, picks the correct release verb per
resource type, and always calls `super.dispose()` last.

## Use it in CI

Fail the build on any new leak:

```yaml
# .github/workflows/leaks.yaml
- uses: subosito/flutter-action@v2
  with: { channel: stable }
- run: flutter pub get
- run: dart run custom_lint   # non-zero exit if any leak is found
```

## Configuration

Disable a rule project-wide:

```yaml
# analysis_options.yaml
custom_lint:
  rules:
    - uncancelled_timer: false
```

Silence a single line:

```dart
// ignore: missing_dispose
late final AnimationController _intentionallyKept = AnimationController(vsync: this);
```

## Limitations (read these)

`leak_sentinel` is a **static** tool and deliberately favours zero false
positives over exhaustiveness. In this first release it:

- **needs an explicit type annotation** on the field — `final AnimationController c = …`
  is checked; `final c = AnimationController(…)` (inferred) is not (yet);
- matches a **curated list of known types** by name — a subclass declared with
  its own type name isn't recognised until you add it;
- only inspects classes that **directly `extend State<…>`**.

It is **not** a runtime heap-leak detector. For retention that only shows up at
runtime (closures held by singletons, unbounded caches), pair it with the
Flutter team's [`leak_tracker`](https://pub.dev/packages/leak_tracker) and
DevTools' memory view. Static and runtime detection are complementary, not
substitutes — see [`doc/DESIGN.md`](doc/DESIGN.md) for where the boundary is.

## How it works

Every rule extends a shared `ReleaseRule` base that walks the AST syntactically
(no reliance on the analyzer's shifting element model): find `State` subclasses,
collect the fields whose declared type is an owned resource, subtract the ones
already released in `dispose()`, and report the rest. The fix is a single
`DartFileEdit`. New rules are typically ~15 lines — see
[CONTRIBUTING.md](CONTRIBUTING.md).

## Roadmap

- [ ] Detect inferred-type fields via the resolved element model
- [ ] Recognise user types transitively (any subtype of `ChangeNotifier`, `Sink`, …)
- [ ] `removeListener` rule for `addListener` without a matching removal
- [ ] Flag `BuildContext` captured across an `await`
- [ ] Publish to [pub.dev](https://pub.dev)

## Contributing

Issues and PRs are very welcome — this is exactly the kind of community-driven
fix OpenForge exists for. Start with [CONTRIBUTING.md](CONTRIBUTING.md) and
our [Code of Conduct](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE) © 2026 OpenForge.

## Acknowledgements

Built on [`custom_lint`](https://pub.dev/packages/custom_lint) by Remi Rousselet,
and inspired by the Flutter team's [`leak_tracker`](https://pub.dev/packages/leak_tracker).

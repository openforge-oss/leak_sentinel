# Design notes

## What "memory leak" means in Dart

Dart is garbage-collected, so the classic C/C++ leak (forgetting to `free`)
cannot happen. What *does* happen is **unintended retention**: an object stays
reachable from a GC root long after it is useful. In Flutter the overwhelmingly
common source is a `State` that allocates a resource and never releases it in
`dispose()`:

- **Controllers / notifiers** (`AnimationController`, `TextEditingController`,
  `ScrollController`, `ChangeNotifier`, …) hold listeners and, for animation,
  a `Ticker` registered with the `SchedulerBinding`.
- **`StreamSubscription`** keeps its callback — and everything the closure
  captures — alive for as long as the stream exists.
- **`Timer.periodic`** keeps firing, holding its callback, after the widget is
  gone.

## Why static analysis, and where it stops

Detection splits cleanly into two regimes:

| | Static (this package) | Runtime (`leak_tracker` + DevTools) |
|---|---|---|
| When | Edit-time / CI | While the app runs & tests exercise paths |
| Finds | "Allocated but never released in `dispose()`" | Actual retained objects on the heap |
| Misses | Retention that depends on runtime state | Nothing that is never exercised |
| False positives | Kept near zero by design | N/A (it observes reality) |

General reachability/lifetime analysis is undecidable, so a static tool can
never find *all* leaks. `leak_sentinel` therefore targets the high-confidence,
high-frequency subset and leaves the rest to runtime tooling. The two are
complementary; a healthy project uses both.

## Why syntactic (AST) detection

The analyzer's *element model* (resolved types) is mid-migration
(`Element` → `Element2`), and its API has shifted across recent SDKs. Rules that
lean on it break on SDK bumps. `leak_sentinel`'s rules instead read the AST
directly — the class's `extends` clause and each field's declared type name.

The trade-off is explicit and documented in the README's *Limitations*: we only
see fields with an explicit type annotation, match a curated set of type names,
and inspect classes that directly `extend State<…>`. The roadmap moves selected
rules onto resolved types once the element model settles, behind the same
`ReleaseRule` interface.

## Rule architecture

```
DartLintRule
└── ReleaseRule (abstract)         // "owns a resource; must release it in dispose()"
    ├── MissingDispose             // releaseMethod: dispose
    ├── UncancelledSubscription    // releaseMethod: cancel
    └── UncancelledTimer           // releaseMethod: cancel
```

`ReleaseRule` does all the work: find `State` subclasses → collect fields whose
declared type is in `resourceTypes` → subtract the fields already released in
`dispose()` → report the rest. The shared quick-fix inserts
`field.<releaseMethod>()` into `dispose()`, creating the method (with a trailing
`super.dispose()`) when absent. A new rule is a `LintCode`, a release verb, and
a set of type names.

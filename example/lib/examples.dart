// Demonstrates every leak_sentinel rule.
//
// Run `dart run custom_lint` in this directory to see the warnings, or open
// the file in an IDE with the Dart plugin to see the squiggles and quick-fixes.

// These demo fields exist only to be flagged; they are never read.
// ignore_for_file: unused_field

import 'dart:async';

import 'package:flutter/material.dart';

/// ❌ BAD — every owned resource here leaks.
class LeakyWidget extends StatefulWidget {
  const LeakyWidget({super.key});

  @override
  State<LeakyWidget> createState() => _LeakyWidgetState();
}

class _LeakyWidgetState extends State<LeakyWidget>
    with SingleTickerProviderStateMixin {
  // expect_lint: missing_dispose
  late final AnimationController _controller = AnimationController(vsync: this);

  // expect_lint: missing_dispose
  final TextEditingController _text = TextEditingController();

  // expect_lint: uncancelled_subscription
  late final StreamSubscription<int> _sub =
      Stream<int>.periodic(const Duration(seconds: 1), (i) => i).listen(print);

  // expect_lint: uncancelled_timer
  late final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// ✅ GOOD — the same resources, all released. No warnings expected.
class CleanWidget extends StatefulWidget {
  const CleanWidget({super.key});

  @override
  State<CleanWidget> createState() => _CleanWidgetState();
}

class _CleanWidgetState extends State<CleanWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  final TextEditingController _text = TextEditingController();
  late final StreamSubscription<int> _sub =
      Stream<int>.periodic(const Duration(seconds: 1), (i) => i).listen(print);
  late final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {});

  @override
  void dispose() {
    _controller.dispose();
    _text.dispose();
    _sub.cancel();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

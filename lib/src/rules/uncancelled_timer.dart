import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../release_rule.dart';

/// Reports a [Timer] field of a [State] that is never cancelled.
class UncancelledTimer extends ReleaseRule {
  const UncancelledTimer()
      : super(
          code: _code,
          releaseMethod: 'cancel',
          resourceTypes: const {'Timer'},
        );

  static const _code = LintCode(
    name: 'uncancelled_timer',
    problemMessage:
        "The timer '{0}' is never cancelled. A periodic timer keeps firing "
        'and retains its callback after the widget is gone.',
    correctionMessage: "Call '{0}.cancel()' inside the State's dispose().",
    errorSeverity: ErrorSeverity.WARNING,
  );
}

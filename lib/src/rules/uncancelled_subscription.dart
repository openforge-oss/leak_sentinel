import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../release_rule.dart';

/// Reports a [StreamSubscription] field of a [State] that is never cancelled.
class UncancelledSubscription extends ReleaseRule {
  const UncancelledSubscription()
      : super(
          code: _code,
          releaseMethod: 'cancel',
          resourceTypes: const {'StreamSubscription'},
        );

  static const _code = LintCode(
    name: 'uncancelled_subscription',
    problemMessage:
        "The stream subscription '{0}' is never cancelled. The callback (and "
        'everything it captures) stays alive for the life of the stream.',
    correctionMessage: "Call '{0}.cancel()' inside the State's dispose().",
    errorSeverity: ErrorSeverity.WARNING,
  );
}

import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../release_rule.dart';

/// Flutter controllers and notifiers that own native/observer resources and
/// must be released in `State.dispose()`.
const _disposables = <String>{
  'AnimationController',
  'TabController',
  'PageController',
  'ScrollController',
  'TextEditingController',
  'TransformationController',
  'FocusNode',
  'FocusScopeNode',
  'OverlayEntry',
  'Ticker',
  'ChangeNotifier',
  'ValueNotifier',
  'StreamController',
  'SinkBase',
};

/// Reports a disposable field of a [State] that is never disposed.
class MissingDispose extends ReleaseRule {
  const MissingDispose()
      : super(
          code: _code,
          releaseMethod: 'dispose',
          resourceTypes: _disposables,
        );

  static const _code = LintCode(
    name: 'missing_dispose',
    problemMessage:
        "'{0}' is a disposable resource but is never disposed. It will be "
        'retained after the widget is removed, leaking memory.',
    correctionMessage: "Call '{0}.dispose()' inside the State's dispose().",
    errorSeverity: ErrorSeverity.WARNING,
  );
}

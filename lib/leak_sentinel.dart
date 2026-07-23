import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/missing_dispose.dart';
import 'src/rules/uncancelled_subscription.dart';
import 'src/rules/uncancelled_timer.dart';

/// Entry point discovered by the `custom_lint` runner.
PluginBase createPlugin() => _LeakSentinelPlugin();

class _LeakSentinelPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
        MissingDispose(),
        UncancelledSubscription(),
        UncancelledTimer(),
      ];
}

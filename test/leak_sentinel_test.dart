import 'package:leak_sentinel/src/rules/missing_dispose.dart';
import 'package:leak_sentinel/src/rules/uncancelled_subscription.dart';
import 'package:leak_sentinel/src/rules/uncancelled_timer.dart';
import 'package:test/test.dart';

void main() {
  test('rules expose stable, unique lint codes', () {
    final names = <String>{
      const MissingDispose().code.name,
      const UncancelledSubscription().code.name,
      const UncancelledTimer().code.name,
    };
    expect(names, {
      'missing_dispose',
      'uncancelled_subscription',
      'uncancelled_timer',
    });
  });

  test('each rule targets the correct release method', () {
    expect(const MissingDispose().releaseMethod, 'dispose');
    expect(const UncancelledSubscription().releaseMethod, 'cancel');
    expect(const UncancelledTimer().releaseMethod, 'cancel');
  });
}

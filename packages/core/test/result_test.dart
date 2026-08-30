import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('Success carries data', () {
      const result = Success(42);
      expect(result.isSuccess, isTrue);
      expect(result.value, 42);
    });

    test('Failure carries exception', () {
      final result = Failure<int>(Exception('boom'));
      expect(result.isFailure, isTrue);
    });

    test('when() routes correctly', () {
      const Result<int> result = Success(1);
      final out = result.when(success: (d) => 'ok', failure: (_) => 'fail');
      expect(out, 'ok');
    });
  });
}

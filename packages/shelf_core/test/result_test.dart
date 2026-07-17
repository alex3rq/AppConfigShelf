import 'package:shelf_core/shelf_core.dart';
import 'package:test/test.dart';

void main() {
  test('ok carries value', () {
    const result = Result<int>.ok(42);
    expect(result.isOk, isTrue);
    expect(result.valueOrNull, 42);
    expect(result.failureOrNull, isNull);
  });

  test('err carries failure', () {
    const result = Result<int>.err(ParseFailure('bad'));
    expect(result.isOk, isFalse);
    expect(result.valueOrNull, isNull);
    expect(result.failureOrNull, isA<ParseFailure>());
  });

  test('map transforms ok and passes err through', () {
    expect(const Result<int>.ok(2).map((v) => v * 2).valueOrNull, 4);
    final err = const Result<int>.err(ParseFailure('bad')).map((v) => v * 2);
    expect(err.failureOrNull, isA<ParseFailure>());
  });

  test('fold visits the right branch', () {
    expect(const Result<int>.ok(1).fold((v) => 'ok$v', (f) => 'err'), 'ok1');
    expect(
        const Result<int>.err(ParseFailure('x'))
            .fold((v) => 'ok', (f) => 'err'),
        'err');
  });
}

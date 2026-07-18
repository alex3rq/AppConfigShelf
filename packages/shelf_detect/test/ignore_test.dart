import 'package:shelf_detect/shelf_detect.dart';
import 'package:test/test.dart';

void main() {
  final matcher = IgnoreMatcher([
    'Microsoft Visual C++ *',
    'Windows Software Development Kit*',
    '*driver*',
  ]);

  test('matches patterns case-insensitively', () {
    expect(
        matcher.isIgnored(
            'Microsoft Visual C++ 2015-2022 Redistributable (x64)'),
        isTrue);
    expect(matcher.isIgnored('microsoft visual c++ 2013 x86'), isTrue);
    expect(
        matcher.isIgnored('Windows Software Development Kit - Windows 10'),
        isTrue);
    expect(matcher.isIgnored('Intel Graphics Driver'), isTrue);
  });

  test('does not match real apps', () {
    expect(matcher.isIgnored('Visual Studio Code'), isFalse);
    expect(matcher.isIgnored('7-Zip'), isFalse);
    expect(matcher.isIgnored(null), isFalse);
    expect(matcher.isIgnored(''), isFalse);
  });

  test('empty pattern list ignores nothing', () {
    expect(IgnoreMatcher(const []).isIgnored('Anything'), isFalse);
  });
}

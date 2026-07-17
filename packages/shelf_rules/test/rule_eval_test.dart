import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_rules/shelf_rules.dart';
import 'package:test/test.dart';

BackupRule _rule({List<String> include = const [], List<String> exclude = const []}) =>
    BackupRule(
      path: StoragePath.parse(r'%APPDATA%\App').valueOrNull!,
      include: include,
      exclude: exclude,
    );

void main() {
  test('empty include matches everything', () {
    final m = RuleMatcher(_rule());
    expect(m.matches('settings.json'), isTrue);
    expect(m.matches('deep/nested/file.bin'), isTrue);
  });

  test('include restricts to matches', () {
    final m = RuleMatcher(_rule(include: ['settings.json', 'snippets/**']));
    expect(m.matches('settings.json'), isTrue);
    expect(m.matches('snippets/dart.json'), isTrue);
    expect(m.matches('other.json'), isFalse);
  });

  test('exclude wins over include', () {
    final m = RuleMatcher(
        _rule(include: ['**'], exclude: ['**/Cache*/**', 'logs/**']));
    expect(m.matches('config.ini'), isTrue);
    expect(m.matches('data/CacheStorage/x.bin'), isFalse);
    expect(m.matches('logs/app.log'), isFalse);
  });

  test('case-insensitive like the Windows filesystem', () {
    final m = RuleMatcher(_rule(exclude: ['cache/**']));
    expect(m.matches('Cache/entry.bin'), isFalse);
  });

  test('filter preserves order', () {
    final m = RuleMatcher(_rule(include: ['*.json']));
    expect(m.filter(['b.json', 'x.txt', 'a.json']), ['b.json', 'a.json']);
  });
}

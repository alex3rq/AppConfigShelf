import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_rules/shelf_rules.dart';
import 'package:test/test.dart';

const _validYaml = r'''
id: vscode
name: Visual Studio Code
publisher: Microsoft
aliases: [code, vs-code]
detect:
  - registry: HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\{771FD6B0-FA20-440A-A002-3B3BAC16DC50}_is1
  - path: "%LOCALAPPDATA%\\Programs\\Microsoft VS Code\\Code.exe"
backup:
  - path: "%APPDATA%\\Code\\User"
    include: ["settings.json", "keybindings.json", "snippets/**"]
    exclude: ["workspaceStorage/**", "**/Cache*/**"]
  - path: "%USERPROFILE%\\.vscode\\extensions"
    optional: true
    sizeWarning: true
winget: Microsoft.VisualStudioCode
risk: safe
''';

void main() {
  group('parseAppEntryYaml', () {
    test('parses a fully valid entry', () {
      final outcome = parseAppEntryYaml(_validYaml);
      expect(outcome.issues, isEmpty);
      final entry = outcome.value!;
      expect(entry.id, 'vscode');
      expect(entry.name, 'Visual Studio Code');
      expect(entry.aliases, ['code', 'vs-code']);
      expect(entry.detect, hasLength(2));
      expect(entry.detect[0], isA<RegistryDetection>());
      expect(entry.detect[1], isA<PathDetection>());
      expect(entry.backup, hasLength(2));
      expect(entry.backup[0].exclude, contains('workspaceStorage/**'));
      expect(entry.backup[1].optional, isTrue);
      expect(entry.backup[1].sizeWarning, isTrue);
      expect(entry.wingetId, 'Microsoft.VisualStudioCode');
      expect(entry.risk, RiskTier.safe);
    });

    test('reports invalid YAML as a single error', () {
      final outcome = parseAppEntryYaml('id: [unclosed');
      expect(outcome.value, isNull);
      expect(outcome.hasErrors, isTrue);
    });

    test('accumulates multiple errors instead of failing fast', () {
      final outcome = parseAppEntryYaml('''
id: "Has Spaces"
detect: []
backup: []
''');
      expect(outcome.value, isNull);
      final fields = outcome.issues.map((i) => i.field).toList();
      expect(fields, containsAll(['id', 'name', 'detect', 'backup']));
    });
  });

  group('security constraints', () {
    test('rejects absolute backup path in db entry', () {
      final outcome = parseAppEntryYaml(r'''
id: evil
name: Evil
detect:
  - path: "%APPDATA%\\Evil"
backup:
  - path: "C:\\Windows\\System32"
''');
      expect(outcome.hasErrors, isTrue);
      expect(
          outcome.issues.any((i) => i.field == 'backup[0].path'), isTrue);
    });

    test('rejects .. traversal in backup path', () {
      final outcome = parseAppEntryYaml(r'''
id: evil
name: Evil
detect:
  - path: "%APPDATA%\\Evil"
backup:
  - path: "%APPDATA%\\..\\..\\Windows"
''');
      expect(outcome.hasErrors, isTrue);
    });

    test('rejects registry detection outside allowed hives', () {
      final outcome = parseAppEntryYaml(r'''
id: app
name: App
detect:
  - registry: HKEY_USERS\S-1-5-18\Software\X
backup:
  - path: "%APPDATA%\\App"
''');
      expect(outcome.hasErrors, isTrue);
    });
  });

  group('lenient parts', () {
    test('unknown top-level field is a warning, not an error', () {
      final outcome = parseAppEntryYaml(r'''
id: app
name: App
futureField: whatever
detect:
  - path: "%APPDATA%\\App"
backup:
  - path: "%APPDATA%\\App"
''');
      expect(outcome.hasErrors, isFalse);
      expect(outcome.value, isNotNull);
      expect(
          outcome.issues
              .any((i) => i.severity == IssueSeverity.warning),
          isTrue);
    });

    test('risk defaults to safe when omitted', () {
      final outcome = parseAppEntryYaml(r'''
id: app
name: App
detect:
  - path: "%APPDATA%\\App"
backup:
  - path: "%APPDATA%\\App"
''');
      expect(outcome.value!.risk, RiskTier.safe);
    });
  });

  group('parseCustomItem', () {
    test('allows absolute paths', () {
      final outcome = parseCustomItem({
        'slug': 'my-tools',
        'name': 'My Tools',
        'backup': [
          {'path': r'C:\Tools\config.ini'},
          {'path': r'%USERPROFILE%\.myconfig'},
        ],
      });
      expect(outcome.issues, isEmpty);
      final item = outcome.value!;
      expect(item.backup[0].path, isA<AbsolutePath>());
      expect(item.backup[1].path, isA<TokenizedPath>());
    });

    test('still rejects traversal in absolute paths', () {
      final outcome = parseCustomItem({
        'slug': 'x',
        'name': 'X',
        'backup': [
          {'path': r'C:\Tools\..\Windows'},
        ],
      });
      expect(outcome.hasErrors, isTrue);
    });

    test('requires slug, name, and at least one rule', () {
      final outcome = parseCustomItem({});
      final fields = outcome.issues.map((i) => i.field).toList();
      expect(fields, containsAll(['slug', 'name', 'backup']));
    });
  });
}

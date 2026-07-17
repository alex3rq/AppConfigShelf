import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_detect/shelf_detect.dart';
import 'package:test/test.dart';

import 'fakes.dart';

const _uninstallRoot =
    r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';

AppEntry _entry(
  String id,
  String name, {
  List<String> aliases = const [],
  List<DetectionRule> detect = const [],
}) =>
    AppEntry(
      id: id,
      name: name,
      aliases: aliases,
      detect: detect.isEmpty
          ? [PathDetection(StoragePath.parse('%APPDATA%\\$name').valueOrNull! as TokenizedPath)]
          : detect,
      backup: [
        BackupRule(path: StoragePath.parse('%APPDATA%\\$name').valueOrNull!),
      ],
    );

void main() {
  group('RegistryUninstallDetector', () {
    test('emits evidence per uninstall entry with DisplayName', () {
      final registry = FakeRegistry({
        '$_uninstallRoot\\7zip': {
          'DisplayName': '7-Zip 24.08 (x64)',
          'DisplayVersion': '24.08',
          'Publisher': 'Igor Pavlov',
        },
        '$_uninstallRoot\\KB123': {'ParentDisplayName': 'update'},
      });
      final evidence = RegistryUninstallDetector(registry).detect();
      expect(evidence, hasLength(1));
      expect(evidence.single.displayName, '7-Zip 24.08 (x64)');
      expect(evidence.single.version, '24.08');
      expect(evidence.single.registryKeyPath, contains('7zip'));
    });
  });

  group('PathProbeDetector', () {
    test('emits db-linked evidence when a detect path exists', () {
      final entry = _entry(
        'vscode',
        'Visual Studio Code',
        detect: [
          PathDetection(StoragePath.parse(
                  r'%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe')
              .valueOrNull! as TokenizedPath),
        ],
      );
      final fs = FakeFileSystem(
          [r'C:\Users\test\AppData\Local\Programs\Microsoft VS Code\Code.exe']);
      final evidence = PathProbeDetector(
              [entry], FakeRegistry({}), fs, FakeKnownFolders())
          .detect();
      expect(evidence.single.probedEntryId, 'vscode');
    });

    test('one hit per entry despite multiple matching rules', () {
      final entry = _entry(
        'app',
        'App',
        detect: [
          RegistryDetection(r'HKCU\Software\App'),
          PathDetection(StoragePath.parse(r'%APPDATA%\App').valueOrNull!
              as TokenizedPath),
        ],
      );
      final registry = FakeRegistry({r'HKCU\Software\App': {}});
      final fs = FakeFileSystem([r'C:\Users\test\AppData\Roaming\App']);
      final evidence =
          PathProbeDetector([entry], registry, fs, FakeKnownFolders()).detect();
      expect(evidence, hasLength(1));
    });
  });

  group('EvidenceResolver', () {
    test('registry detect-rule match scores 1.0', () {
      final entry = _entry(
        'vscode',
        'Visual Studio Code',
        detect: [RegistryDetection('$_uninstallRoot\\{VSCODE}_is1')],
      );
      final result = EvidenceResolver([entry]).resolve([
        InstallEvidence(
          source: EvidenceSource.registryUninstall,
          displayName: 'Microsoft Visual Studio Code',
          registryKeyPath: '$_uninstallRoot\\{VSCODE}_is1',
          version: '1.90.0',
        ),
      ]);
      expect(result.detected.single.entryId, 'vscode');
      expect(result.detected.single.confidence, 1.0);
      expect(result.detected.single.version, '1.90.0');
      expect(result.unknown, isEmpty);
    });

    test('name/alias match scores 0.7 and normalizes decorations', () {
      final entry = _entry('7zip', '7-Zip', aliases: ['7zip']);
      final result = EvidenceResolver([entry]).resolve([
        const InstallEvidence(
          source: EvidenceSource.registryUninstall,
          displayName: '7-Zip 24.08 (x64)',
          registryKeyPath: '$_uninstallRoot\\7zip',
        ),
      ]);
      expect(result.detected.single.entryId, '7zip');
      expect(result.detected.single.confidence, 0.7);
    });

    test('strongest evidence wins, details backfilled from weaker', () {
      final entry = _entry(
        'app',
        'My App',
        detect: [RegistryDetection('$_uninstallRoot\\MyApp')],
      );
      final result = EvidenceResolver([entry]).resolve([
        const InstallEvidence(
          source: EvidenceSource.pathProbe,
          probedEntryId: 'app',
          displayName: 'My App',
        ),
        const InstallEvidence(
          source: EvidenceSource.registryUninstall,
          displayName: 'My App',
          registryKeyPath: '$_uninstallRoot\\MyApp',
          version: '2.0',
          installLocation: r'C:\Program Files\MyApp',
        ),
      ]);
      final app = result.detected.single;
      expect(app.confidence, 1.0);
      expect(app.version, '2.0');
      expect(app.installPath, r'C:\Program Files\MyApp');
    });

    test('unmatched registry evidence lands in unknown', () {
      final result = EvidenceResolver([_entry('a', 'A')]).resolve([
        const InstallEvidence(
          source: EvidenceSource.registryUninstall,
          displayName: 'Mystery Tool',
          registryKeyPath: '$_uninstallRoot\\Mystery',
        ),
      ]);
      expect(result.detected, isEmpty);
      expect(result.unknown.single.displayName, 'Mystery Tool');
    });
  });

  group('scanSystem', () {
    test('end to end with fakes', () {
      final entries = [
        _entry(
          'vscode',
          'Visual Studio Code',
          detect: [
            PathDetection(StoragePath.parse(
                    r'%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe')
                .valueOrNull! as TokenizedPath),
          ],
        ),
        _entry('7zip', '7-Zip'),
      ];
      final registry = FakeRegistry({
        '$_uninstallRoot\\7z': {
          'DisplayName': '7-Zip 24.08 (x64)',
          'DisplayVersion': '24.08',
        },
        '$_uninstallRoot\\Ghost': {'DisplayName': 'Ghost App'},
      });
      final fs = FakeFileSystem(
          [r'C:\Users\test\AppData\Local\Programs\Microsoft VS Code\Code.exe']);

      final result = scanSystem(
        entries: entries,
        registry: registry,
        fileSystem: fs,
        knownFolders: FakeKnownFolders(),
      );

      expect(result.detected.map((d) => d.entryId), containsAll(['vscode', '7zip']));
      expect(result.unknown.single.displayName, 'Ghost App');
    });
  });
}

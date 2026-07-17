import 'package:shelf_backup/shelf_backup.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:test/test.dart';

final class FakeIo implements BackupIo {
  FakeIo(this.trees);

  /// root absolute path -> relative file paths (forward slash).
  final Map<String, List<String>> trees;

  @override
  bool exists(String absolutePath) =>
      trees.containsKey(absolutePath) ||
      trees.entries.any((e) => e.value
          .any((rel) => '${e.key}\\${rel.replaceAll('/', r'\')}' == absolutePath));

  @override
  bool isDirectory(String absolutePath) => trees.containsKey(absolutePath);

  @override
  List<FoundFile> listTree(String rootAbsolutePath) => [
        for (final rel in trees[rootAbsolutePath] ?? const <String>[])
          FoundFile(
            absolutePath: '$rootAbsolutePath\\${rel.replaceAll('/', r'\')}',
            relativePath: rel,
            size: 10,
            modified: DateTime.utc(2026),
          ),
      ];

  @override
  Stream<List<int>> openRead(String absolutePath) => Stream.value([1, 2, 3]);
}

final class FakeKnownFolders implements KnownFolderResolver {
  @override
  String resolve(KnownFolder folder) => switch (folder) {
        KnownFolder.appData => r'C:\Users\t\AppData\Roaming',
        KnownFolder.localAppData => r'C:\Users\t\AppData\Local',
        KnownFolder.programData => r'C:\ProgramData',
        KnownFolder.userProfile => r'C:\Users\t',
        KnownFolder.documents => r'C:\Users\t\Documents',
      };
}

AppEntry _vscode() => AppEntry(
      id: 'vscode',
      name: 'VS Code',
      detect: [
        PathDetection(StoragePath.parse(r'%APPDATA%\Code').valueOrNull!
            as TokenizedPath)
      ],
      backup: [
        BackupRule(
          path: StoragePath.parse(r'%APPDATA%\Code\User').valueOrNull!,
          include: ['settings.json', 'snippets/**'],
          exclude: ['**/Cache*/**'],
        ),
      ],
    );

void main() {
  test('plans matched files with archive and target paths', () {
    final io = FakeIo({
      r'C:\Users\t\AppData\Roaming\Code\User': [
        'settings.json',
        'snippets/dart.json',
        'other.txt',
        'snippets/CacheThing/x.json',
      ],
    });
    final plan = planBackup(
        apps: [_vscode()], customItems: [], io: io, knownFolders: FakeKnownFolders());

    expect(plan.entries, hasLength(1));
    final files = plan.entries.single.files;
    expect(files.map((f) => f.storedPath), [
      'apps/vscode/files/APPDATA/Code/User/settings.json',
      'apps/vscode/files/APPDATA/Code/User/snippets/dart.json',
    ]);
    expect(files.first.targetPath, r'%APPDATA%\Code\User\settings.json');
    expect(files.first.absolute, isFalse);
    expect(plan.totalFiles, 2);
    expect(plan.totalSize, 20);
  });

  test('missing rule root produces no files and drops the entry', () {
    final plan = planBackup(
        apps: [_vscode()],
        customItems: [],
        io: FakeIo({}),
        knownFolders: FakeKnownFolders());
    expect(plan.entries, isEmpty);
  });

  test('custom item with absolute path maps under ABS/', () {
    final item = CustomItem(
      slug: 'tools',
      name: 'My Tools',
      backup: [
        BackupRule(
            path: StoragePath.parse(r'C:\Tools', allowAbsolute: true)
                .valueOrNull!),
      ],
    );
    final io = FakeIo({
      r'C:\Tools': ['config.ini', 'sub/data.json'],
    });
    final plan = planBackup(
        apps: [], customItems: [item], io: io, knownFolders: FakeKnownFolders());

    final files = plan.entries.single.files;
    expect(plan.entries.single.source, EntrySource.custom);
    expect(files.map((f) => f.storedPath), [
      'custom/tools/files/ABS/C/Tools/config.ini',
      'custom/tools/files/ABS/C/Tools/sub/data.json',
    ]);
    expect(files.first.targetPath, r'C:\Tools\config.ini');
    expect(files.first.absolute, isTrue);
  });

  test('overlapping rules do not duplicate archive members', () {
    final entry = AppEntry(
      id: 'app',
      name: 'App',
      detect: [
        PathDetection(
            StoragePath.parse(r'%APPDATA%\App').valueOrNull! as TokenizedPath)
      ],
      backup: [
        BackupRule(path: StoragePath.parse(r'%APPDATA%\App').valueOrNull!),
        BackupRule(
            path: StoragePath.parse(r'%APPDATA%\App').valueOrNull!,
            include: ['config.ini']),
      ],
    );
    final io = FakeIo({
      r'C:\Users\t\AppData\Roaming\App': ['config.ini'],
    });
    final plan = planBackup(
        apps: [entry], customItems: [], io: io, knownFolders: FakeKnownFolders());
    expect(plan.entries.single.files, hasLength(1));
  });
}

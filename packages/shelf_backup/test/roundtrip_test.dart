// The product-guarantee gate (docs/plan/09-quality.md): backup a tree,
// wipe it, restore it, and require byte-identical equality. If this test
// fails, the release is broken — no exceptions.
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shelf_backup/shelf_backup.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('acshelf_gate'));
  tearDown(() => temp.deleteSync(recursive: true));

  test('GATE: backup → wipe → restore → byte-identical tree', () async {
    final root = Directory(p.join(temp.path, 'workload'))..createSync();
    final random = Random(42);

    // Representative shapes: nesting, unicode names, spaces, empty file,
    // larger binary blob, deep chain.
    final files = <String, List<int>>{
      'settings.json': '{"theme":"dark","font":11}'.codeUnits,
      'empty.cfg': const [],
      'ñandú öß 配置.ini': 'unicode=yes'.codeUnits,
      'dir with spaces/inner file.txt': 'spaces'.codeUnits,
      'a/b/c/d/e/f/deep.dat': [for (var i = 0; i < 1000; i++) i % 256],
      'blob.bin': [for (var i = 0; i < 300 * 1024; i++) random.nextInt(256)],
    };
    files.forEach((rel, bytes) {
      final file = File(p.join(root.path, rel));
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
    });

    Map<String, String> hashTree(String dir) => {
          for (final f in Directory(dir).listSync(recursive: true).whereType<File>())
            p.relative(f.path, from: dir).replaceAll(r'\', '/'):
                sha256.convert(f.readAsBytesSync()).toString(),
        };
    final before = hashTree(root.path);
    expect(before, hasLength(files.length));

    // Backup.
    final item = CustomItem(
      slug: 'workload',
      name: 'Workload',
      backup: [
        BackupRule(
            path:
                StoragePath.parse(root.path, allowAbsolute: true).valueOrNull!),
      ],
    );
    const io = RealBackupIo();
    final plan = planBackup(
        apps: [], customItems: [item], io: io, knownFolders: _None());
    final packagePath = p.join(temp.path, 'gate.acshelf');
    final backupEvents = await writeBackup(
            plan: plan, outputPath: packagePath, io: io, appVersion: 'gate')
        .toList();
    expect(
        backupEvents.whereType<BackupFinished>().single.manifest.entries.single
            .skipped,
        isEmpty);

    // Wipe.
    root.deleteSync(recursive: true);
    expect(root.existsSync(), isFalse);

    // Restore.
    final package = PackageReader.open(packagePath).valueOrNull!;
    final events = await executeRestore(
      package: package,
      selectedEntryIds: {'workload'},
      knownFolders: _None(),
      io: RealRestoreIo(),
      undoDirectory: p.join(temp.path, 'undo'),
    ).toList();
    final finished = events.whereType<RestoreFinished>().single;
    expect(finished.failedEntries, isEmpty);
    expect(finished.restoredFiles, files.length);

    // Byte-identical.
    final after = hashTree(root.path);
    expect(after, equals(before));
  });
}

final class _None implements KnownFolderResolver {
  @override
  String resolve(KnownFolder folder) => throw UnsupportedError('unused');
}

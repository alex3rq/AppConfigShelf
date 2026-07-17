import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shelf_backup/shelf_backup.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('acshelf_test');
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
  });

  test('round trip: write package, read back, verify manifest and hashes',
      () async {
    // Real tree on disk.
    final root = Directory(p.join(temp.path, 'AppConfig'))..createSync();
    File(p.join(root.path, 'settings.json')).writeAsStringSync('{"a":1}');
    Directory(p.join(root.path, 'sub')).createSync();
    File(p.join(root.path, 'sub', 'data.txt')).writeAsStringSync('hello');

    final item = CustomItem(
      slug: 'cfg',
      name: 'Config',
      backup: [
        BackupRule(
            path: StoragePath.parse(root.path, allowAbsolute: true).valueOrNull!),
      ],
    );
    const io = RealBackupIo();
    final plan = planBackup(
      apps: [],
      customItems: [item],
      io: io,
      knownFolders: _UnusedKnownFolders(),
    );
    expect(plan.totalFiles, 2);

    final outputPath = p.join(temp.path, 'out.acshelf');
    final events = await writeBackup(
      plan: plan,
      outputPath: outputPath,
      io: io,
      appVersion: '0.1.0-test',
    ).toList();

    expect(events.whereType<FileBackedUp>(), hasLength(2));
    final finished = events.whereType<BackupFinished>().single;
    expect(finished.manifest.entries.single.files, hasLength(2));
    expect(finished.manifest.entries.single.skipped, isEmpty);

    // Read the zip back with a plain decoder.
    final archive =
        ZipDecoder().decodeBytes(File(outputPath).readAsBytesSync());
    final names = archive.map((f) => f.name).toSet();
    expect(names, contains('manifest.json'));
    expect(names, contains('logs/scan-report.json'));

    final manifestJson = jsonDecode(utf8.decode(
            archive.firstWhere((f) => f.name == 'manifest.json').content))
        as Map<String, Object?>;
    final reread = PackageManifest.fromJson(manifestJson);
    expect(reread.formatVersion, 1);
    expect(reread.entries.single.source, EntrySource.custom);

    // Every manifest file exists in the archive and its hash matches.
    for (final mf in reread.entries.single.files) {
      final member = archive.firstWhere((f) => f.name == mf.storedPath);
      final digest = sha256.convert(member.content);
      expect(digest.toString(), mf.sha256,
          reason: 'hash mismatch for ${mf.storedPath}');
      expect(member.content.length, mf.size);
    }
  });

  test('unreadable file becomes a skip record, backup continues', () async {
    final root = Directory(p.join(temp.path, 'Data'))..createSync();
    File(p.join(root.path, 'good.txt')).writeAsStringSync('ok');
    final ghostPath = p.join(root.path, 'ghost.txt');
    File(ghostPath).writeAsStringSync('x');

    final item = CustomItem(
      slug: 'd',
      name: 'D',
      backup: [
        BackupRule(
            path: StoragePath.parse(root.path, allowAbsolute: true).valueOrNull!),
      ],
    );
    const io = RealBackupIo();
    final plan = planBackup(
        apps: [],
        customItems: [item],
        io: io,
        knownFolders: _UnusedKnownFolders());

    // Delete one planned file before writing to force a read failure.
    File(ghostPath).deleteSync();

    final events = await writeBackup(
      plan: plan,
      outputPath: p.join(temp.path, 'out.acshelf'),
      io: io,
      appVersion: '0.1.0-test',
    ).toList();

    final finished = events.whereType<BackupFinished>().single;
    final entry = finished.manifest.entries.single;
    expect(entry.files.map((f) => p.basename(f.storedPath)), ['good.txt']);
    expect(entry.skipped, hasLength(1));
    expect(events.whereType<FileSkipped>(), hasLength(1));
  });
}

final class _UnusedKnownFolders implements KnownFolderResolver {
  @override
  String resolve(KnownFolder folder) =>
      throw UnsupportedError('not needed for absolute-path tests');
}

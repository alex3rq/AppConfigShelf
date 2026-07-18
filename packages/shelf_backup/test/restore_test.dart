import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:shelf_backup/shelf_backup.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('acshelf_restore'));
  tearDown(() => temp.deleteSync(recursive: true));

  /// Backs up [sourceDir] as custom item [slug] and returns the package path.
  Future<String> makePackage(String sourceDir, {String slug = 'item'}) async {
    final item = CustomItem(
      slug: slug,
      name: slug,
      backup: [
        BackupRule(
            path:
                StoragePath.parse(sourceDir, allowAbsolute: true).valueOrNull!),
      ],
    );
    const io = RealBackupIo();
    final plan = planBackup(
        apps: [],
        customItems: [item],
        io: io,
        knownFolders: _NoKnownFolders());
    final out = p.join(temp.path, '$slug.acshelf');
    await writeBackup(plan: plan, outputPath: out, io: io, appVersion: 't')
        .drain<void>();
    return out;
  }

  test('restores files to original absolute paths', () async {
    final src = Directory(p.join(temp.path, 'src'))..createSync();
    File(p.join(src.path, 'a.txt')).writeAsStringSync('alpha');
    Directory(p.join(src.path, 'nested')).createSync();
    File(p.join(src.path, 'nested', 'b.txt')).writeAsStringSync('beta');

    final packagePath = await makePackage(src.path);
    src.deleteSync(recursive: true);

    final package = PackageReader.open(packagePath).valueOrNull!;
    final events = await executeRestore(
      package: package,
      selectedEntryIds: {'item'},
      knownFolders: _NoKnownFolders(),
      io: RealRestoreIo(),
      undoDirectory: p.join(temp.path, 'undo'),
    ).toList();

    final finished = events.whereType<RestoreFinished>().single;
    expect(finished.restoredFiles, 2);
    expect(finished.failedEntries, isEmpty);
    expect(finished.undoPath, isNull, reason: 'nothing was displaced');
    expect(File(p.join(src.path, 'a.txt')).readAsStringSync(), 'alpha');
    expect(
        File(p.join(src.path, 'nested', 'b.txt')).readAsStringSync(), 'beta');
  });

  test('selective restore only touches selected entries', () async {
    final srcA = Directory(p.join(temp.path, 'A'))..createSync();
    final srcB = Directory(p.join(temp.path, 'B'))..createSync();
    File(p.join(srcA.path, 'a.txt')).writeAsStringSync('a');
    File(p.join(srcB.path, 'b.txt')).writeAsStringSync('b');

    const io = RealBackupIo();
    final plan = planBackup(
      apps: [],
      customItems: [
        for (final (slug, dir) in [('aa', srcA.path), ('bb', srcB.path)])
          CustomItem(
            slug: slug,
            name: slug,
            backup: [
              BackupRule(
                  path: StoragePath.parse(dir, allowAbsolute: true)
                      .valueOrNull!),
            ],
          ),
      ],
      io: io,
      knownFolders: _NoKnownFolders(),
    );
    final packagePath = p.join(temp.path, 'multi.acshelf');
    await writeBackup(
            plan: plan, outputPath: packagePath, io: io, appVersion: 't')
        .drain<void>();

    srcA.deleteSync(recursive: true);
    srcB.deleteSync(recursive: true);

    final package = PackageReader.open(packagePath).valueOrNull!;
    await executeRestore(
      package: package,
      selectedEntryIds: {'bb'},
      knownFolders: _NoKnownFolders(),
      io: RealRestoreIo(),
      undoDirectory: p.join(temp.path, 'undo'),
    ).drain<void>();

    expect(File(p.join(srcB.path, 'b.txt')).existsSync(), isTrue);
    expect(Directory(srcA.path).existsSync(), isFalse,
        reason: 'unselected entry must not be restored');
  });

  test('overwrite captures displaced file into undo bundle', () async {
    final src = Directory(p.join(temp.path, 'cfg'))..createSync();
    final target = File(p.join(src.path, 'settings.json'))
      ..writeAsStringSync('old-version');

    final packagePath = await makePackage(src.path, slug: 'cfg');
    target.writeAsStringSync('newer-local-change');

    final package = PackageReader.open(packagePath).valueOrNull!;
    final events = await executeRestore(
      package: package,
      selectedEntryIds: {'cfg'},
      knownFolders: _NoKnownFolders(),
      io: RealRestoreIo(),
      undoDirectory: p.join(temp.path, 'undo'),
    ).toList();

    expect(target.readAsStringSync(), 'old-version');
    final undoPath = events.whereType<RestoreFinished>().single.undoPath!;
    final undo = PackageReader.open(undoPath).valueOrNull!;
    final undoFile = undo.manifest.entries.single.files.single;
    expect(utf8.decode(undo.readFile(undoFile.storedPath)!),
        'newer-local-change');
    expect(undoFile.targetPath, target.path);
  });

  test('skipExisting leaves conflicts untouched', () async {
    final src = Directory(p.join(temp.path, 'cfg2'))..createSync();
    final target = File(p.join(src.path, 'x.ini'))..writeAsStringSync('one');
    final packagePath = await makePackage(src.path, slug: 'cfg2');
    target.writeAsStringSync('two');

    final package = PackageReader.open(packagePath).valueOrNull!;
    final events = await executeRestore(
      package: package,
      selectedEntryIds: {'cfg2'},
      knownFolders: _NoKnownFolders(),
      io: RealRestoreIo(),
      undoDirectory: p.join(temp.path, 'undo'),
      conflictMode: ConflictMode.skipExisting,
    ).toList();

    expect(target.readAsStringSync(), 'two');
    final finished = events.whereType<RestoreFinished>().single;
    expect(finished.skippedFiles, 1);
    expect(finished.restoredFiles, 0);
  });

  test('corrupted package halts the entry, reports failure', () async {
    final src = Directory(p.join(temp.path, 'cor'))..createSync();
    File(p.join(src.path, 'f.txt')).writeAsStringSync('data');
    final packagePath = await makePackage(src.path, slug: 'cor');
    src.deleteSync(recursive: true);

    // Corrupt the archived member so its bytes no longer match the manifest
    // hash: rebuild the zip, swapping the file content, keeping the manifest.
    final tamperedPath = p.join(temp.path, 'tampered.acshelf');
    _tamperMember(packagePath, tamperedPath, 'f.txt', 'evil-data');

    final package = PackageReader.open(tamperedPath).valueOrNull!;
    final events = await executeRestore(
      package: package,
      selectedEntryIds: {'cor'},
      knownFolders: _NoKnownFolders(),
      io: RealRestoreIo(),
      undoDirectory: p.join(temp.path, 'undo'),
    ).toList();

    final failed = events.whereType<RestoreEntryFailed>().single;
    expect(failed.reason, contains('hash mismatch'));
    expect(File(p.join(src.path, 'f.txt')).existsSync(), isFalse,
        reason: 'nothing must be written from a corrupted package');
  });

  test('refuses to write through a directory symlink/junction', () async {
    final realTarget = Directory(p.join(temp.path, 'real'))..createSync();
    final src = Directory(p.join(temp.path, 'linked'))..createSync();
    File(p.join(src.path, 'f.txt')).writeAsStringSync('x');
    final packagePath = await makePackage(src.path, slug: 'lnk');
    // Replace the original directory with a link pointing elsewhere —
    // the junction-planting attack restore must refuse.
    src.deleteSync(recursive: true);
    Link(src.path).createSync(realTarget.path);

    final events = await executeRestore(
      package: PackageReader.open(packagePath).valueOrNull!,
      selectedEntryIds: {'lnk'},
      knownFolders: _NoKnownFolders(),
      io: RealRestoreIo(),
      undoDirectory: p.join(temp.path, 'undo'),
    ).toList();

    final failed = events.whereType<RestoreEntryFailed>().single;
    expect(failed.reason, contains('junction/symlink'));
    expect(File(p.join(realTarget.path, 'f.txt')).existsSync(), isFalse,
        reason: 'nothing may be written through the link');
    Link(src.path).deleteSync(); // allow tearDown cleanup
  }, testOn: 'windows');

  test('planRestore gates db entries on detection, customs always restorable',
      () {
    final manifest = PackageManifest(
      createdAt: DateTime.now(),
      appVersion: 't',
      machine: const MachineInfo(hostname: 'h', windowsBuild: 'w'),
      entries: [
        const ManifestEntry(
            source: EntrySource.database, id: 'vscode', name: 'VS Code', files: []),
        const ManifestEntry(
            source: EntrySource.database, id: 'gone', name: 'Gone', files: []),
        const ManifestEntry(
            source: EntrySource.custom, id: 'notes', name: 'Notes', files: []),
      ],
    );
    final plan = planRestore(
      manifest: manifest,
      detectedEntryIds: {'vscode'},
      fileSystem: _NothingExists(),
      knownFolders: _NoKnownFolders(),
    );
    final byId = {for (final c in plan.candidates) c.entry.id: c};
    expect(byId['vscode']!.status, RestoreStatus.restorable);
    expect(byId['gone']!.status, RestoreStatus.appMissing);
    expect(byId['notes']!.status, RestoreStatus.restorable);
    expect(plan.defaultSelection, {'vscode', 'notes'});
  });
}

/// Rebuilds a zip, replacing the content of the member whose name ends with
/// [suffix] — simulates on-disk corruption/tampering.
void _tamperMember(
    String inputPath, String outputPath, String suffix, String newContent) {
  final archive =
      ZipDecoder().decodeBytes(File(inputPath).readAsBytesSync());
  final encoder = ZipFileEncoder()..create(outputPath);
  for (final member in archive) {
    if (member.name.endsWith(suffix)) {
      encoder.addArchiveFile(ArchiveFile.string(member.name, newContent));
    } else {
      encoder.addArchiveFile(
          ArchiveFile.bytes(member.name, member.content));
    }
  }
  encoder.closeSync();
}

final class _NoKnownFolders implements KnownFolderResolver {
  @override
  String resolve(KnownFolder folder) =>
      throw UnsupportedError('absolute-only tests');
}

final class _NothingExists implements FileSystemView {
  @override
  bool exists(String absolutePath) => false;
}

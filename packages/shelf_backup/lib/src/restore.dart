import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:shelf_core/shelf_core.dart';

import 'manifest.dart';
import 'reader.dart';
import 'restore_planner.dart';

/// What to do when a target file already exists.
enum ConflictMode {
  /// Overwrite; the existing file is captured into the undo bundle first.
  overwrite,

  /// Leave existing files untouched, restore only missing ones.
  skipExisting,
}

/// Write-side filesystem operations for restore. Real implementation is
/// [RealRestoreIo]; tests could fake it, though restore tests prefer real
/// temp directories — this is the layer where Windows semantics matter.
abstract interface class RestoreIo {
  bool exists(String absolutePath);
  List<int>? readBytes(String absolutePath);

  /// Writes atomically: temp file in the target directory, then rename over
  /// the destination. Creates parent directories.
  void writeFileAtomic(String absolutePath, List<int> bytes);
}

final class RealRestoreIo implements RestoreIo {
  RealRestoreIo();

  /// Directories already verified free of link components this run.
  final _checkedDirs = <String>{};

  @override
  bool exists(String absolutePath) =>
      FileSystemEntity.typeSync(absolutePath, followLinks: false) !=
      FileSystemEntityType.notFound;

  @override
  List<int>? readBytes(String absolutePath) {
    try {
      return File(absolutePath).readAsBytesSync();
    } on FileSystemException {
      return null;
    }
  }

  @override
  void writeFileAtomic(String absolutePath, List<int> bytes) {
    final file = File(absolutePath);
    _ensureNoLinkComponents(file.parent);
    file.parent.createSync(recursive: true);
    final temp = File('$absolutePath.acshelf-tmp');
    temp.writeAsBytesSync(bytes, flush: true);
    temp.renameSync(absolutePath);
  }

  /// A junction/symlink planted anywhere along the target directory chain
  /// must not redirect restore writes elsewhere (docs/plan/10-security.md).
  /// Checks every existing ancestor for a reparse point. String comparison
  /// of resolved paths is NOT used — 8.3 short names make it unreliable.
  void _ensureNoLinkComponents(Directory parent) {
    var current = parent.absolute;
    final toMark = <String>[];
    while (true) {
      final key = current.path.toLowerCase();
      if (_checkedDirs.contains(key)) break;
      final parentDir = current.parent;
      if (parentDir.path == current.path) break; // drive root
      if (FileSystemEntity.isLinkSync(current.path)) {
        throw FileSystemException(
            'restore target directory chain contains a junction/symlink — refusing to write',
            current.path);
      }
      toMark.add(key);
      current = parentDir;
    }
    _checkedDirs.addAll(toMark);
  }
}

// --- Events -----------------------------------------------------------------

sealed class RestoreEvent {
  const RestoreEvent();
}

final class RestoreEntryStarted extends RestoreEvent {
  const RestoreEntryStarted(this.entryId, this.name, this.fileCount);
  final String entryId;
  final String name;
  final int fileCount;
}

final class FileRestored extends RestoreEvent {
  const FileRestored(this.entryId, this.targetPath);
  final String entryId;
  final String targetPath;
}

final class FileSkippedExisting extends RestoreEvent {
  const FileSkippedExisting(this.entryId, this.targetPath);
  final String entryId;
  final String targetPath;
}

/// The whole entry was halted (conservative policy) — [restoredSoFar] files
/// from it were already written and are covered by the undo bundle.
final class RestoreEntryFailed extends RestoreEvent {
  const RestoreEntryFailed(this.entryId, this.reason, this.restoredSoFar);
  final String entryId;
  final String reason;
  final int restoredSoFar;
}

final class RestoreFinished extends RestoreEvent {
  const RestoreFinished({
    required this.restoredFiles,
    required this.skippedFiles,
    required this.failedEntries,
    this.undoPath,
  });

  final int restoredFiles;
  final int skippedFiles;
  final List<String> failedEntries;

  /// Null when nothing was displaced (no undo bundle written).
  final String? undoPath;
}

// --- Executor ---------------------------------------------------------------

/// Restores the selected entries from an opened package.
///
/// Policy (docs/plan/06-workflows.md): per-file hash verification before
/// every write; staged atomic writes; every displaced file goes into an
/// undo bundle written *before* the first overwrite of that file; an entry
/// halts on its first failure but other entries continue.
Stream<RestoreEvent> executeRestore({
  required PackageReader package,
  required Set<String> selectedEntryIds,
  required KnownFolderResolver knownFolders,
  required RestoreIo io,
  required String undoDirectory,
  ConflictMode conflictMode = ConflictMode.overwrite,
}) async* {
  final selected = [
    for (final entry in package.manifest.entries)
      if (selectedEntryIds.contains(entry.id)) entry,
  ];

  _UndoWriter? undo;
  var restored = 0;
  var skipped = 0;
  final failedEntries = <String>[];

  for (final entry in selected) {
    yield RestoreEntryStarted(entry.id, entry.name, entry.files.length);
    var entryRestored = 0;
    String? failure;

    for (final file in entry.files) {
      final target = resolveTargetPath(file, knownFolders);
      if (target == null) {
        failure = 'invalid target path ${file.targetPath} in manifest';
        break;
      }
      // Database entries may only write tokenized targets; a manifest
      // claiming an absolute target for a db entry is tampered.
      if (entry.source == EntrySource.database && file.absolute) {
        failure = 'absolute target for database entry — refusing';
        break;
      }

      if (io.exists(target)) {
        if (conflictMode == ConflictMode.skipExisting) {
          skipped += 1;
          yield FileSkippedExisting(entry.id, file.targetPath);
          continue;
        }
        final existing = io.readBytes(target);
        if (existing != null) {
          undo ??= _UndoWriter(undoDirectory, package.path);
          undo.add(file, existing);
        }
      }

      final bytes = package.readFile(file.storedPath);
      if (bytes == null) {
        failure = 'missing ${file.storedPath} in package';
        break;
      }
      if (sha256.convert(bytes).toString() != file.sha256) {
        failure = 'hash mismatch for ${file.targetPath} — package corrupted';
        break;
      }
      try {
        io.writeFileAtomic(target, bytes);
      } on Object catch (e) {
        failure = 'write failed for ${file.targetPath}: $e';
        break;
      }
      restored += 1;
      entryRestored += 1;
      yield FileRestored(entry.id, file.targetPath);
    }

    if (failure != null) {
      failedEntries.add(entry.id);
      yield RestoreEntryFailed(entry.id, failure, entryRestored);
    }
  }

  final undoPath = undo?.close();
  yield RestoreFinished(
    restoredFiles: restored,
    skippedFiles: skipped,
    failedEntries: failedEntries,
    undoPath: undoPath,
  );
}

/// Collects displaced files into an `.acshelf-undo` bundle (same container
/// format; undone by restoring the bundle itself).
final class _UndoWriter {
  _UndoWriter(String directory, this.sourcePackage)
      : _path =
            '$directory\\undo-${DateTime.now().millisecondsSinceEpoch}.acshelf-undo' {
    Directory(directory).createSync(recursive: true);
    _encoder.create(_path);
  }

  final String sourcePackage;
  final String _path;
  final _encoder = ZipFileEncoder();
  final _files = <ManifestFile>[];

  void add(ManifestFile displaced, List<int> content) {
    _encoder.addArchiveFile(
        ArchiveFile.bytes(displaced.storedPath, content));
    _files.add(ManifestFile(
      storedPath: displaced.storedPath,
      targetPath: displaced.targetPath,
      absolute: displaced.absolute,
      sha256: sha256.convert(content).toString(),
      size: content.length,
      modifiedAt: DateTime.now(),
    ));
  }

  String close() {
    final manifest = PackageManifest(
      createdAt: DateTime.now(),
      appVersion: 'undo',
      machine: MachineInfo(
          hostname: Platform.localHostname,
          windowsBuild: Platform.operatingSystemVersion),
      entries: [
        ManifestEntry(
          source: EntrySource.custom,
          id: 'undo',
          name: 'Displaced by restore of $sourcePackage',
          files: _files,
        ),
      ],
    );
    _encoder.addArchiveFile(ArchiveFile.string('manifest.json',
        const JsonEncoder.withIndent('  ').convert(manifest.toJson())));
    _encoder.closeSync();
    return _path;
  }
}

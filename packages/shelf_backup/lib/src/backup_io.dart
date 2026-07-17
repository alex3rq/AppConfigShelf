import 'dart:io';

import 'package:path/path.dart' as p;

/// One file found under a backup rule root.
final class FoundFile {
  const FoundFile({
    required this.absolutePath,
    required this.relativePath,
    required this.size,
    required this.modified,
  });

  final String absolutePath;

  /// Forward-slash path relative to the enumerated root.
  final String relativePath;

  final int size;
  final DateTime modified;
}

/// Filesystem access the backup pipeline needs. Tests provide an in-memory
/// implementation; production uses [RealBackupIo].
abstract interface class BackupIo {
  /// Whether [absolutePath] exists (file or directory).
  bool exists(String absolutePath);

  /// Whether [absolutePath] is a directory.
  bool isDirectory(String absolutePath);

  /// Recursively lists files under [rootAbsolutePath]. If the root is a
  /// single file, yields just that file with its basename as relative path.
  /// Files that cannot be statted are silently skipped here; unreadable
  /// files surface later as skip records when their bytes are read.
  List<FoundFile> listTree(String rootAbsolutePath);

  /// Streams file contents.
  Stream<List<int>> openRead(String absolutePath);
}

/// [BackupIo] over dart:io. Symlinks and junctions are not followed during
/// enumeration — a junction inside a config directory must never pull
/// unrelated trees into a backup (docs/plan/10-security.md).
final class RealBackupIo implements BackupIo {
  const RealBackupIo();

  @override
  bool exists(String absolutePath) =>
      FileSystemEntity.typeSync(absolutePath, followLinks: false) !=
      FileSystemEntityType.notFound;

  @override
  bool isDirectory(String absolutePath) =>
      FileSystemEntity.typeSync(absolutePath, followLinks: false) ==
      FileSystemEntityType.directory;

  @override
  List<FoundFile> listTree(String rootAbsolutePath) {
    final type = FileSystemEntity.typeSync(rootAbsolutePath, followLinks: false);
    if (type == FileSystemEntityType.file) {
      final stat = File(rootAbsolutePath).statSync();
      return [
        FoundFile(
          absolutePath: rootAbsolutePath,
          relativePath: p.basename(rootAbsolutePath),
          size: stat.size,
          modified: stat.modified,
        ),
      ];
    }
    if (type != FileSystemEntityType.directory) return const [];

    final files = <FoundFile>[];
    final entities = Directory(rootAbsolutePath)
        .listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is! File) continue;
      final FileStat stat;
      try {
        stat = entity.statSync();
      } on FileSystemException {
        continue;
      }
      files.add(FoundFile(
        absolutePath: entity.path,
        relativePath:
            p.relative(entity.path, from: rootAbsolutePath).replaceAll(r'\', '/'),
        size: stat.size,
        modified: stat.modified,
      ));
    }
    return files;
  }

  @override
  Stream<List<int>> openRead(String absolutePath) => File(absolutePath).openRead();
}

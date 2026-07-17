import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_rules/shelf_rules.dart';

import 'backup_io.dart';

/// One file scheduled for backup.
final class PlannedFile {
  const PlannedFile({
    required this.absolutePath,
    required this.storedPath,
    required this.targetPath,
    required this.absolute,
    required this.size,
    required this.modified,
  });

  final String absolutePath;
  final String storedPath;
  final String targetPath;
  final bool absolute;
  final int size;
  final DateTime modified;
}

/// One entry (app or custom item) in a backup plan.
final class PlannedEntry {
  const PlannedEntry({
    required this.source,
    required this.id,
    required this.name,
    required this.risk,
    required this.files,
  });

  final EntrySource source;
  final String id;
  final String name;
  final RiskTier risk;
  final List<PlannedFile> files;

  int get totalSize => files.fold(0, (sum, f) => sum + f.size);
}

final class BackupPlan {
  const BackupPlan(this.entries);

  final List<PlannedEntry> entries;

  int get totalFiles => entries.fold(0, (sum, e) => sum + e.files.length);
  int get totalSize => entries.fold(0, (sum, e) => sum + e.totalSize);
}

/// Builds the exact file list a backup would capture — also powers dry-run
/// previews. Pure with respect to [io]; nothing is written.
BackupPlan planBackup({
  required List<AppEntry> apps,
  required List<CustomItem> customItems,
  required BackupIo io,
  required KnownFolderResolver knownFolders,
}) {
  final entries = <PlannedEntry>[
    for (final app in apps)
      _planEntry(
        source: EntrySource.database,
        id: app.id,
        name: app.name,
        risk: app.risk,
        rules: app.backup,
        io: io,
        knownFolders: knownFolders,
      ),
    for (final item in customItems)
      _planEntry(
        source: EntrySource.custom,
        id: item.slug,
        name: item.name,
        risk: RiskTier.safe,
        rules: item.backup,
        io: io,
        knownFolders: knownFolders,
      ),
  ];
  // Entries with nothing to back up are dropped from the plan; the UI warns
  // separately when a selected entry produced no files.
  return BackupPlan([for (final e in entries) if (e.files.isNotEmpty) e]);
}

PlannedEntry _planEntry({
  required EntrySource source,
  required String id,
  required String name,
  required RiskTier risk,
  required List<BackupRule> rules,
  required BackupIo io,
  required KnownFolderResolver knownFolders,
}) {
  final prefix = source == EntrySource.database ? 'apps' : 'custom';
  final files = <PlannedFile>[];
  final seenStored = <String>{};

  for (final rule in rules) {
    final (rootAbsolute, rootArchiveDir, rootTarget, isAbsolute) =
        _resolveRoot(rule.path, knownFolders);
    if (!io.exists(rootAbsolute)) continue;

    final matcher = RuleMatcher(rule);
    final rootIsFile = !io.isDirectory(rootAbsolute);
    for (final found in io.listTree(rootAbsolute)) {
      // A single-file root always matches regardless of include globs.
      if (!rootIsFile && !matcher.matches(found.relativePath)) continue;
      final storedPath =
          '$prefix/$id/files/$rootArchiveDir/${found.relativePath}';
      // Overlapping rules must not produce duplicate archive members.
      if (!seenStored.add(storedPath.toLowerCase())) continue;
      files.add(PlannedFile(
        absolutePath: found.absolutePath,
        storedPath: storedPath,
        targetPath: rootIsFile
            ? rootTarget
            : '$rootTarget\\${found.relativePath.replaceAll('/', r'\')}',
        absolute: isAbsolute,
        size: found.size,
        modified: found.modified,
      ));
    }
  }

  return PlannedEntry(
      source: source, id: id, name: name, risk: risk, files: files);
}

/// Maps a rule root to (absolute path, archive directory, target prefix,
/// isAbsolute). Archive directory examples:
/// `%APPDATA%\Code` → `APPDATA/Code`; `C:\Tools` → `ABS/C/Tools`.
(String, String, String, bool) _resolveRoot(
    StoragePath path, KnownFolderResolver knownFolders) {
  switch (path) {
    case TokenizedPath():
      final absolute = knownFolders.expand(path);
      final tokenDir = path.root.token.replaceAll('%', '');
      final archiveDir = path.segments.isEmpty
          ? tokenDir
          : '$tokenDir/${path.segments.join('/')}';
      return (absolute, archiveDir, path.stored, false);
    case AbsolutePath():
      final drive = path.root.replaceAll(':', '').replaceAll(r'\', '');
      final archiveDir = drive.isEmpty
          ? 'ABS/UNC/${path.segments.join('/')}'
          : 'ABS/$drive/${path.segments.join('/')}';
      return (path.stored, archiveDir, path.stored, true);
  }
}

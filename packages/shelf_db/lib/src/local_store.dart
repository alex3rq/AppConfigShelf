import 'dart:convert';
import 'dart:io';

import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_rules/shelf_rules.dart';

/// User-created database entries ("My library"): one JSON file per entry,
/// same shape as compiled db entries, validated through the same parser.
/// Covers both fresh entries (apps the official db doesn't know) and
/// overrides (edited copies of official entries, same id — see
/// [mergeEntries]).
final class LocalEntryStore {
  LocalEntryStore(this.directory);

  final String directory;

  String _pathFor(String id) => '$directory/$id.json';

  /// Loads all valid entries. Unparseable files are skipped and reported in
  /// [LocalEntries.warnings] rather than breaking the whole library.
  LocalEntries load() {
    final dir = Directory(directory);
    if (!dir.existsSync()) return const LocalEntries([], []);
    final entries = <AppEntry>[];
    final warnings = <String>[];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      try {
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is! Map) {
          warnings.add('${file.path}: not a JSON object');
          continue;
        }
        final outcome =
            parseAppEntry(decoded.map((k, v) => MapEntry(k.toString(), v)));
        final entry = outcome.value;
        if (entry == null) {
          warnings.add('${file.path}: ${outcome.issues.join('; ')}');
          continue;
        }
        entries.add(entry);
      } on Object catch (e) {
        warnings.add('${file.path}: $e');
      }
    }
    return LocalEntries(entries, warnings);
  }

  void save(AppEntry entry) {
    Directory(directory).createSync(recursive: true);
    File(_pathFor(entry.id)).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(appEntryToJson(entry)));
  }

  void delete(String id) {
    final file = File(_pathFor(id));
    if (file.existsSync()) file.deleteSync();
  }
}

final class LocalEntries {
  const LocalEntries(this.entries, this.warnings);

  final List<AppEntry> entries;
  final List<String> warnings;
}

/// Result of merging official db entries with the local library.
final class MergedEntries {
  const MergedEntries({
    required this.entries,
    required this.overriddenIds,
    required this.freshLocalIds,
  });

  final List<AppEntry> entries;

  /// Ids where a local entry replaced an official one ("customized" badge;
  /// reset-to-official available).
  final Set<String> overriddenIds;

  /// Ids that exist only locally ("local" badge).
  final Set<String> freshLocalIds;
}

/// Local entries win on id collision: an override is a deliberate user
/// decision and must beat upstream until the user resets it.
MergedEntries mergeEntries(List<AppEntry> official, List<AppEntry> local) {
  final officialIds = {for (final e in official) e.id};
  final localById = {for (final e in local) e.id: e};

  final overridden = <String>{};
  final fresh = <String>{};
  final merged = <AppEntry>[];

  for (final entry in official) {
    final override = localById[entry.id];
    if (override != null) {
      merged.add(override);
      overridden.add(entry.id);
    } else {
      merged.add(entry);
    }
  }
  for (final entry in local) {
    if (!officialIds.contains(entry.id)) {
      merged.add(entry);
      fresh.add(entry.id);
    }
  }

  return MergedEntries(
      entries: merged, overriddenIds: overridden, freshLocalIds: fresh);
}

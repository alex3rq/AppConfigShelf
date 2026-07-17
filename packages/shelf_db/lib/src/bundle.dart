import 'dart:convert';

import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_rules/shelf_rules.dart';

/// Highest db schema version this build understands.
const supportedSchemaVersion = 1;

/// A parsed database bundle (compiled `db.json`).
final class DbBundle {
  const DbBundle({
    required this.schemaVersion,
    required this.contentVersion,
    required this.entries,
  });

  final int schemaVersion;
  final String contentVersion;
  final List<AppEntry> entries;

  /// Parses and validates a compiled bundle. Entries that fail to parse are
  /// dropped (they may use future minor extensions); the bundle fails only
  /// on structural problems or an unsupported schema major.
  static Result<DbBundle> parse(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (e) {
      return Result.err(ParseFailure('bundle is not valid JSON: ${e.message}'));
    }
    if (decoded is! Map<String, Object?>) {
      return Result.err(const ParseFailure('bundle must be a JSON object'));
    }
    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int) {
      return Result.err(const ParseFailure('missing schemaVersion'));
    }
    if (schemaVersion > supportedSchemaVersion) {
      return Result.err(ParseFailure(
          'db schema v$schemaVersion is newer than this app supports '
          '(v$supportedSchemaVersion) — update AppConfigShelf'));
    }
    final rawEntries = decoded['entries'];
    if (rawEntries is! List) {
      return Result.err(const ParseFailure('missing entries list'));
    }
    final entries = <AppEntry>[];
    for (final raw in rawEntries) {
      if (raw is! Map) continue;
      final outcome =
          parseAppEntry(raw.map((k, v) => MapEntry(k.toString(), v)));
      final entry = outcome.value;
      if (entry != null) entries.add(entry);
    }
    return Result.ok(DbBundle(
      schemaVersion: schemaVersion,
      contentVersion: decoded['contentVersion'] as String? ?? 'unknown',
      entries: entries,
    ));
  }
}

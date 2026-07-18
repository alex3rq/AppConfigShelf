import 'package:shelf_core/shelf_core.dart';

import 'config_locator.dart' show normalizeAppName;
import 'evidence.dart';

/// Result of resolving all evidence against the database.
final class ResolutionResult {
  const ResolutionResult({required this.detected, required this.unknown});

  /// Apps matched to a db entry (confidence > 0) — plus, when
  /// [DetectedApp.entryId] is null, nothing; unmatched evidence goes to
  /// [unknown] instead.
  final List<DetectedApp> detected;

  /// Evidence no db entry claims — candidates for the
  /// "contribute an entry" flow.
  final List<InstallEvidence> unknown;
}

/// Merges detector evidence against database entries with confidence
/// scoring. Pure function of its inputs.
///
/// Confidence ladder (strongest evidence wins per entry):
/// - 1.0  uninstall/registry key listed in the entry's detect rules
/// - 0.9  db-driven path probe hit
/// - 0.7  normalized name or alias equality
final class EvidenceResolver {
  EvidenceResolver(List<AppEntry> entries) : _entries = entries {
    for (final entry in entries) {
      for (final rule in entry.detect) {
        if (rule is RegistryDetection) {
          _keyToEntry[_normalizeKey(rule.keyPath)] = entry;
        }
      }
      _nameToEntry[_normalizeName(entry.name)] = entry;
      for (final alias in entry.aliases) {
        _nameToEntry[_normalizeName(alias)] = entry;
      }
    }
  }

  final List<AppEntry> _entries;
  final _keyToEntry = <String, AppEntry>{};
  final _nameToEntry = <String, AppEntry>{};

  ResolutionResult resolve(List<InstallEvidence> allEvidence) {
    // Best match per entry id; evidence that matched nothing.
    final best = <String, DetectedApp>{};
    final unknown = <InstallEvidence>[];

    for (final evidence in allEvidence) {
      final (entry, confidence) = _match(evidence);
      if (entry == null) {
        // Only registry evidence is user-meaningful as "unknown app";
        // a failed probe emits nothing so this is always registry-sourced.
        unknown.add(evidence);
        continue;
      }
      final existing = best[entry.id];
      if (existing == null || confidence > existing.confidence) {
        best[entry.id] = DetectedApp(
          entryId: entry.id,
          displayName: evidence.displayName ?? entry.name,
          confidence: confidence,
          installPath: evidence.installLocation ?? existing?.installPath,
          version: evidence.version ?? existing?.version,
        );
      } else {
        // Keep the higher-confidence match but backfill missing details.
        best[entry.id] = DetectedApp(
          entryId: existing.entryId,
          displayName: existing.displayName,
          confidence: existing.confidence,
          installPath: existing.installPath ?? evidence.installLocation,
          version: existing.version ?? evidence.version,
        );
      }
    }

    final detected = best.values.toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return ResolutionResult(detected: detected, unknown: unknown);
  }

  (AppEntry?, double) _match(InstallEvidence evidence) {
    if (evidence.probedEntryId != null) {
      final entry = _entries.where((e) => e.id == evidence.probedEntryId).firstOrNull;
      return (entry, 0.9);
    }
    if (evidence.registryKeyPath != null) {
      final entry = _keyToEntry[_normalizeKey(evidence.registryKeyPath!)];
      if (entry != null) return (entry, 1.0);
    }
    if (evidence.displayName != null) {
      final entry = _nameToEntry[_normalizeName(evidence.displayName!)];
      if (entry != null) return (entry, 0.7);
    }
    return (null, 0);
  }

  static String _normalizeKey(String keyPath) => keyPath
      .toUpperCase()
      .replaceAll('/', r'\')
      .replaceFirst('HKEY_CURRENT_USER', 'HKCU')
      .replaceFirst('HKEY_LOCAL_MACHINE', 'HKLM');

  static String _normalizeName(String name) => normalizeAppName(name);
}

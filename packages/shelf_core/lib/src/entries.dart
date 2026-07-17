import 'rules.dart';

/// Where a backup-plan entry came from. Flows through to the package
/// manifest so restore knows how to treat it.
enum EntrySource {
  /// Defined by the community database; restore is detection-gated.
  database,

  /// User-defined custom item; always offered at restore.
  custom,
}

/// How risky restoring this entry's data is. Communicated in the UI so a
/// browser profile is not treated like a terminal color scheme.
enum RiskTier { safe, caution, expert }

/// A community-database application entry (db schema v1).
/// Parsing/validation lives in shelf_rules; this is the parsed form.
final class AppEntry {
  const AppEntry({
    required this.id,
    required this.name,
    this.publisher,
    this.aliases = const [],
    required this.detect,
    required this.backup,
    this.wingetId,
    this.risk = RiskTier.safe,
  });

  /// Stable lowercase identifier, unique across the database (e.g. `vscode`).
  final String id;

  final String name;
  final String? publisher;

  /// Alternate names used by the detection resolver's fuzzy matching.
  final List<String> aliases;

  /// OR-semantics: any match counts as detected. Never empty.
  final List<DetectionRule> detect;

  /// Never empty — an entry that backs up nothing is invalid.
  final List<BackupRule> backup;

  /// Winget package id for future reinstall integration.
  final String? wingetId;

  final RiskTier risk;
}

/// A user-defined backup item: any folders/files the user chose that no
/// database entry covers. Uses the same rule model as [AppEntry.backup] so
/// the engines treat both identically. Not detection-gated.
final class CustomItem {
  const CustomItem({
    required this.slug,
    required this.name,
    required this.backup,
  });

  /// Stable identifier within the package (`custom/<slug>/` in the archive).
  final String slug;

  /// User-given display name.
  final String name;

  /// May contain absolute-path rules, unlike database entries.
  final List<BackupRule> backup;
}

/// An application found on the current system by the detection engine,
/// resolved against the database when possible.
final class DetectedApp {
  const DetectedApp({
    this.entryId,
    required this.displayName,
    required this.confidence,
    this.installPath,
    this.version,
  });

  /// Matched database entry id, or null for an unknown app (candidate for
  /// the "contribute an entry" flow).
  final String? entryId;

  final String displayName;

  /// 0.0–1.0 resolver confidence in the [entryId] match.
  final double confidence;

  final String? installPath;
  final String? version;
}

import 'package:shelf_core/shelf_core.dart';

/// `.acshelf` manifest, format v1 (ADR-002). Hand-rolled JSON — the format
/// contract is too important to hide behind codegen.
final class PackageManifest {
  const PackageManifest({
    this.formatVersion = 1,
    required this.createdAt,
    required this.appVersion,
    this.dbSchemaVersion,
    this.dbContentVersion,
    required this.machine,
    required this.entries,
  });

  final int formatVersion;
  final DateTime createdAt;
  final String appVersion;
  final int? dbSchemaVersion;
  final String? dbContentVersion;
  final MachineInfo machine;
  final List<ManifestEntry> entries;

  Map<String, Object?> toJson() => {
        'formatVersion': formatVersion,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'appVersion': appVersion,
        if (dbSchemaVersion != null) 'dbSchemaVersion': dbSchemaVersion,
        if (dbContentVersion != null) 'dbContentVersion': dbContentVersion,
        'machine': machine.toJson(),
        'entries': [for (final e in entries) e.toJson()],
      };

  factory PackageManifest.fromJson(Map<String, Object?> json) =>
      PackageManifest(
        formatVersion: json['formatVersion'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        appVersion: json['appVersion'] as String,
        dbSchemaVersion: json['dbSchemaVersion'] as int?,
        dbContentVersion: json['dbContentVersion'] as String?,
        machine:
            MachineInfo.fromJson(json['machine'] as Map<String, Object?>),
        entries: [
          for (final e in json['entries'] as List<Object?>)
            ManifestEntry.fromJson(e as Map<String, Object?>),
        ],
      );
}

final class MachineInfo {
  const MachineInfo({required this.hostname, required this.windowsBuild});

  final String hostname;
  final String windowsBuild;

  Map<String, Object?> toJson() =>
      {'hostname': hostname, 'windowsBuild': windowsBuild};

  factory MachineInfo.fromJson(Map<String, Object?> json) => MachineInfo(
        hostname: json['hostname'] as String? ?? '',
        windowsBuild: json['windowsBuild'] as String? ?? '',
      );
}

/// One backed-up application or custom item.
final class ManifestEntry {
  const ManifestEntry({
    required this.source,
    required this.id,
    required this.name,
    this.risk = RiskTier.safe,
    required this.files,
    this.skipped = const [],
  });

  final EntrySource source;

  /// Db entry id, or custom item slug.
  final String id;

  final String name;
  final RiskTier risk;
  final List<ManifestFile> files;
  final List<SkippedFile> skipped;

  Map<String, Object?> toJson() => {
        'source': source.name,
        'id': id,
        'name': name,
        'risk': risk.name,
        'files': [for (final f in files) f.toJson()],
        if (skipped.isNotEmpty)
          'skipped': [for (final s in skipped) s.toJson()],
      };

  factory ManifestEntry.fromJson(Map<String, Object?> json) => ManifestEntry(
        source: EntrySource.values.byName(json['source'] as String),
        id: json['id'] as String,
        name: json['name'] as String,
        risk: RiskTier.values.byName(json['risk'] as String? ?? 'safe'),
        files: [
          for (final f in json['files'] as List<Object?>)
            ManifestFile.fromJson(f as Map<String, Object?>),
        ],
        skipped: [
          for (final s in (json['skipped'] as List<Object?>? ?? []))
            SkippedFile.fromJson(s as Map<String, Object?>),
        ],
      );
}

final class ManifestFile {
  const ManifestFile({
    required this.storedPath,
    required this.targetPath,
    this.absolute = false,
    required this.sha256,
    required this.size,
    required this.modifiedAt,
  });

  /// Location inside the archive, forward slashes
  /// (`apps/vscode/files/APPDATA/Code/User/settings.json`).
  final String storedPath;

  /// Tokenized target (`%APPDATA%\Code\User\settings.json`) or, when
  /// [absolute], the original absolute path (custom items only).
  final String targetPath;

  final bool absolute;
  final String sha256;
  final int size;
  final DateTime modifiedAt;

  Map<String, Object?> toJson() => {
        'storedPath': storedPath,
        'targetPath': targetPath,
        if (absolute) 'absolute': true,
        'sha256': sha256,
        'size': size,
        'modifiedAt': modifiedAt.toUtc().toIso8601String(),
      };

  factory ManifestFile.fromJson(Map<String, Object?> json) => ManifestFile(
        storedPath: json['storedPath'] as String,
        targetPath: json['targetPath'] as String,
        absolute: json['absolute'] as bool? ?? false,
        sha256: json['sha256'] as String,
        size: json['size'] as int,
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      );
}

final class SkippedFile {
  const SkippedFile({required this.targetPath, required this.reason});

  final String targetPath;

  /// Machine-readable reason (`fileLocked`, `accessDenied`, `readError`).
  final String reason;

  Map<String, Object?> toJson() =>
      {'targetPath': targetPath, 'reason': reason};

  factory SkippedFile.fromJson(Map<String, Object?> json) => SkippedFile(
        targetPath: json['targetPath'] as String,
        reason: json['reason'] as String,
      );
}

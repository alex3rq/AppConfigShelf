import 'storage_path.dart';

/// One way an application can be detected on a system. A database entry
/// carries a list of these; matching any single rule counts as detected
/// (OR semantics). See docs/plan/07-engines.md.
sealed class DetectionRule {
  const DetectionRule();
}

/// Detected when a registry key exists.
final class RegistryDetection extends DetectionRule {
  const RegistryDetection(this.keyPath);

  /// Full key path including hive, e.g.
  /// `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\{...}`.
  final String keyPath;
}

/// Detected when a file or directory exists at a tokenized path.
final class PathDetection extends DetectionRule {
  const PathDetection(this.path);

  final TokenizedPath path;
}

/// Detected when an MSIX/Store package with this family name is installed.
final class MsixDetection extends DetectionRule {
  const MsixDetection(this.packageFamilyName);

  final String packageFamilyName;
}

/// One backup location with include/exclude filtering.
///
/// Evaluation: excludes always win over includes (safe default — an
/// accidental cache inclusion wastes space, an accidental exclusion is data
/// loss discovered after the reinstall). An empty [include] means everything
/// under [path].
final class BackupRule {
  const BackupRule({
    required this.path,
    this.include = const [],
    this.exclude = const [],
    this.optional = false,
    this.sizeWarning = false,
  });

  /// Root of this rule. Tokenized for database entries; custom items may use
  /// absolute paths.
  final StoragePath path;

  /// Glob patterns relative to [path]. Empty = include everything.
  final List<String> include;

  /// Glob patterns relative to [path]. Wins over [include].
  final List<String> exclude;

  /// Presented unchecked by default in the backup UI (e.g. large extension
  /// directories).
  final bool optional;

  /// UI should compute and surface the size before backup.
  final bool sizeWarning;
}

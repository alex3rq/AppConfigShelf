/// Which detector produced a piece of evidence.
enum EvidenceSource { registryUninstall, pathProbe, msix }

/// One observation that some application is installed. Detectors emit these;
/// the resolver merges them against database entries. Keeping evidence and
/// matching separate lets new detection sources plug in without touching
/// matching logic.
final class InstallEvidence {
  const InstallEvidence({
    required this.source,
    this.displayName,
    this.publisher,
    this.version,
    this.installLocation,
    this.registryKeyPath,
    this.probedEntryId,
  });

  final EvidenceSource source;

  final String? displayName;
  final String? publisher;
  final String? version;
  final String? installLocation;

  /// Full uninstall key path, for [EvidenceSource.registryUninstall].
  final String? registryKeyPath;

  /// Db entry whose detect rule produced this evidence, for
  /// [EvidenceSource.pathProbe] — path probes are always db-driven, so the
  /// match is known at emission time.
  final String? probedEntryId;

  @override
  String toString() =>
      'InstallEvidence(${source.name}, ${displayName ?? probedEntryId})';
}

import 'package:shelf_core/shelf_core.dart';

import 'manifest.dart';

/// Why an entry can or cannot be restored right now.
enum RestoreStatus {
  /// App detected (or custom item) — ready to restore.
  restorable,

  /// Database entry whose app was not detected on this system. Restoring
  /// config for absent software is usually pointless and sometimes harmful,
  /// so these are excluded unless the user overrides per entry.
  appMissing,
}

/// One manifest entry annotated for the restore UI.
final class RestoreCandidate {
  const RestoreCandidate({
    required this.entry,
    required this.status,
    required this.conflictCount,
  });

  final ManifestEntry entry;
  final RestoreStatus status;

  /// How many target files already exist and would be overwritten (all of
  /// them are captured into the undo bundle first).
  final int conflictCount;
}

final class RestorePlan {
  const RestorePlan(this.candidates);

  final List<RestoreCandidate> candidates;

  /// Entries selected by default for a "complete restore": everything
  /// restorable.
  Set<String> get defaultSelection => {
        for (final c in candidates)
          if (c.status == RestoreStatus.restorable) c.entry.id,
      };
}

/// Annotates every manifest entry with detection gating and conflict counts.
/// Selection (complete vs selective) happens on top of this plan — the UI
/// filters by entry id; execution receives the chosen subset.
RestorePlan planRestore({
  required PackageManifest manifest,
  required Set<String> detectedEntryIds,
  required FileSystemView fileSystem,
  required KnownFolderResolver knownFolders,
}) {
  final candidates = <RestoreCandidate>[];
  for (final entry in manifest.entries) {
    final status = switch (entry.source) {
      EntrySource.custom => RestoreStatus.restorable,
      EntrySource.database => detectedEntryIds.contains(entry.id)
          ? RestoreStatus.restorable
          : RestoreStatus.appMissing,
    };
    var conflicts = 0;
    for (final file in entry.files) {
      final target = resolveTargetPath(file, knownFolders);
      if (target != null && fileSystem.exists(target)) conflicts += 1;
    }
    candidates.add(RestoreCandidate(
        entry: entry, status: status, conflictCount: conflicts));
  }
  return RestorePlan(candidates);
}

/// Resolves a manifest file's target to an absolute path, re-validating the
/// stored path as untrusted input (defense in depth — a tampered manifest
/// must not become an arbitrary write). Returns null when invalid.
String? resolveTargetPath(ManifestFile file, KnownFolderResolver knownFolders) {
  final parsed =
      StoragePath.parse(file.targetPath, allowAbsolute: file.absolute);
  return switch (parsed.valueOrNull) {
    TokenizedPath(:final root, :final segments) =>
      segments.isEmpty
          ? knownFolders.resolve(root)
          : '${knownFolders.resolve(root)}\\${segments.join(r'\')}',
    AbsolutePath(:final stored) => stored,
    null => null,
  };
}

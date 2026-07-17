import 'package:shelf_core/shelf_core.dart';

import 'detectors.dart';
import 'evidence.dart';
import 'resolver.dart';

/// Convenience entry point: runs the standard detector set and resolves the
/// evidence in one call. This is what the app's scan feature invokes.
ResolutionResult scanSystem({
  required List<AppEntry> entries,
  required RegistryView registry,
  required FileSystemView fileSystem,
  required KnownFolderResolver knownFolders,
}) {
  final detectors = <Detector>[
    RegistryUninstallDetector(registry),
    PathProbeDetector(entries, registry, fileSystem, knownFolders),
  ];
  final evidence = <InstallEvidence>[
    for (final detector in detectors) ...detector.detect(),
  ];
  return EvidenceResolver(entries).resolve(evidence);
}

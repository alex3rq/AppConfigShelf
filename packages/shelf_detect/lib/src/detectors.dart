import 'package:shelf_core/shelf_core.dart';

import 'evidence.dart';

/// A source of install evidence. Implementations must be side-effect free
/// reads; all I/O goes through the views passed at construction.
abstract interface class Detector {
  List<InstallEvidence> detect();
}

/// Enumerates the Windows Uninstall registry keys — the primary evidence
/// source, covering classic installers (MSI, Inno, NSIS).
final class RegistryUninstallDetector implements Detector {
  RegistryUninstallDetector(this._registry);

  final RegistryView _registry;

  static const _roots = [
    r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    r'HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
    r'HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall',
  ];

  @override
  List<InstallEvidence> detect() {
    final evidence = <InstallEvidence>[];
    for (final root in _roots) {
      for (final subKey in _registry.subKeyNames(root)) {
        final keyPath = '$root\\$subKey';
        final displayName = _registry.stringValue(keyPath, 'DisplayName');
        // Entries without a DisplayName are updates/components, not apps.
        if (displayName == null || displayName.isEmpty) continue;
        // Windows conventions: SystemComponent=1 is hidden from
        // Control Panel; ParentKeyName/ReleaseType mark per-app updates.
        if (_registry.dwordValue(keyPath, 'SystemComponent') == 1) continue;
        if (_registry.stringValue(keyPath, 'ParentKeyName') != null) continue;
        if (_registry.stringValue(keyPath, 'ReleaseType') != null) continue;
        evidence.add(InstallEvidence(
          source: EvidenceSource.registryUninstall,
          displayName: displayName,
          publisher: _registry.stringValue(keyPath, 'Publisher'),
          version: _registry.stringValue(keyPath, 'DisplayVersion'),
          installLocation: _registry.stringValue(keyPath, 'InstallLocation'),
          registryKeyPath: keyPath,
        ));
      }
    }
    return evidence;
  }
}

/// Probes the db entries' explicit detect rules (registry keys and tokenized
/// paths). Db-driven, so each hit already knows its entry id.
final class PathProbeDetector implements Detector {
  PathProbeDetector(this._entries, this._registry, this._fileSystem, this._folders);

  final List<AppEntry> _entries;
  final RegistryView _registry;
  final FileSystemView _fileSystem;
  final KnownFolderResolver _folders;

  @override
  List<InstallEvidence> detect() {
    final evidence = <InstallEvidence>[];
    for (final entry in _entries) {
      for (final rule in entry.detect) {
        final hit = switch (rule) {
          RegistryDetection(:final keyPath) => _registry.keyExists(keyPath),
          PathDetection(:final path) => _fileSystem.exists(_folders.expand(path)),
          MsixDetection() => false, // MSIX detector arrives post-M1.
        };
        if (hit) {
          evidence.add(InstallEvidence(
            source: EvidenceSource.pathProbe,
            probedEntryId: entry.id,
            displayName: entry.name,
          ));
          break; // OR semantics: one hit per entry is enough.
        }
      }
    }
    return evidence;
  }
}

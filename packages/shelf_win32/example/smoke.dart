// Manual smoke test against the live machine: verifies known-folder
// resolution and registry enumeration end-to-end through shelf_detect.
// Run: dart run example/smoke.dart
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_detect/shelf_detect.dart';
import 'package:shelf_win32/shelf_win32.dart';

void main() {
  final folders = WindowsKnownFolderResolver();
  print('Known folders:');
  for (final folder in KnownFolder.values) {
    print('  ${folder.token} -> ${folders.resolve(folder)}');
  }

  const registry = WindowsRegistryView();
  final result = scanSystem(
    entries: const [],
    registry: registry,
    fileSystem: const RealFileSystem(),
    knownFolders: folders,
  );
  print('\nUninstall entries found: ${result.unknown.length}');
  for (final e in result.unknown.take(10)) {
    print('  ${e.displayName}  [${e.version ?? '-'}]  (${e.publisher ?? '-'})');
  }
}

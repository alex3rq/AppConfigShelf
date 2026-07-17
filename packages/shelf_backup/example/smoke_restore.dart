// Live smoke: selective restore of the custom entry from the M2 smoke
// package. Deletes the synthetic folder, restores only 'smoke' (the aimp
// entry stays untouched), verifies content.
// Run: dart run example/smoke_restore.dart <dir-containing-smoke.acshelf>
import 'dart:io';

import 'package:shelf_backup/shelf_backup.dart';
import 'package:shelf_win32/shelf_win32.dart';

Future<void> main(List<String> args) async {
  final dir = args.first;
  final packagePath = '$dir\\smoke.acshelf';
  final customRoot = Directory('$dir\\smoke-custom');

  if (customRoot.existsSync()) customRoot.deleteSync(recursive: true);
  print('Deleted ${customRoot.path}');

  final opened = PackageReader.open(packagePath);
  final package = opened.valueOrNull;
  if (package == null) {
    print('FAIL: ${opened.failureOrNull}');
    exitCode = 1;
    return;
  }
  print('Opened package: ${package.manifest.entries.length} entries');

  await for (final event in executeRestore(
    package: package,
    selectedEntryIds: {'smoke'}, // selective: leave aimp alone
    knownFolders: WindowsKnownFolderResolver(),
    io: const RealRestoreIo(),
    undoDirectory: '$dir\\undo',
  )) {
    if (event case RestoreFinished(:final restoredFiles, :final failedEntries)) {
      print('Restored $restoredFiles files, failures: $failedEntries');
    }
  }

  final config = File('${customRoot.path}\\config.ini').readAsStringSync();
  final notes = File('${customRoot.path}\\sub\\notes.txt').readAsStringSync();
  print(config == '[a]\nb=1' && notes == 'hello'
      ? 'CONTENT VERIFIED'
      : 'CONTENT MISMATCH');
}

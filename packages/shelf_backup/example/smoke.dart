// Live smoke test: backs up the AIMP config (read-only against real user
// data) plus a synthetic custom folder, writing the package to a temp
// location passed as the first argument.
// Run: dart run example/smoke.dart <output-dir>
import 'dart:io';

import 'package:shelf_backup/shelf_backup.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_win32/shelf_win32.dart';

Future<void> main(List<String> args) async {
  final outDir = args.isNotEmpty ? args.first : Directory.systemTemp.path;

  // Synthetic custom-item tree.
  final customRoot = Directory('$outDir\\smoke-custom')..createSync(recursive: true);
  File('${customRoot.path}\\config.ini').writeAsStringSync('[a]\nb=1');
  Directory('${customRoot.path}\\sub').createSync();
  File('${customRoot.path}\\sub\\notes.txt').writeAsStringSync('hello');

  final apps = <AppEntry>[
    AppEntry(
      id: 'aimp',
      name: 'AIMP',
      detect: [
        PathDetection(
            StoragePath.parse(r'%APPDATA%\AIMP').valueOrNull! as TokenizedPath)
      ],
      backup: [
        BackupRule(
          path: StoragePath.parse(r'%APPDATA%\AIMP').valueOrNull!,
          exclude: ['Cache/**', 'Backups/**'],
        ),
      ],
    ),
  ];
  final customItems = [
    CustomItem(
      slug: 'smoke',
      name: 'Smoke Custom',
      backup: [
        BackupRule(
            path: StoragePath.parse(customRoot.path, allowAbsolute: true)
                .valueOrNull!),
      ],
    ),
  ];

  const io = RealBackupIo();
  final plan = planBackup(
    apps: apps,
    customItems: customItems,
    io: io,
    knownFolders: WindowsKnownFolderResolver(),
  );
  print('Plan: ${plan.totalFiles} files, ${plan.totalSize} bytes, '
      '${plan.entries.length} entries');

  final outputPath = '$outDir\\smoke.acshelf';
  await for (final event in writeBackup(
      plan: plan, outputPath: outputPath, io: io, appVersion: 'smoke')) {
    if (event case BackupFinished(:final manifest)) {
      for (final entry in manifest.entries) {
        print('  ${entry.source.name}/${entry.id}: ${entry.files.length} files, '
            '${entry.skipped.length} skipped');
      }
      print('Wrote $outputPath '
          '(${File(outputPath).lengthSync()} bytes)');
    }
  }
}

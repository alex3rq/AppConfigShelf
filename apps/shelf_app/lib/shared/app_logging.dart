import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_win32/shelf_win32.dart';

/// File logging: JSON lines, one file per app run, 7-file retention, under
/// %LOCALAPPDATA%\AppConfigShelf\logs. Usernames in paths are the user's
/// own logs — nothing ships anywhere (no telemetry, by policy).
final class AppLogging {
  AppLogging._(this._sink, this.logDirectory);

  final IOSink _sink;
  final String logDirectory;

  static AppLogging init() {
    final localAppData =
        WindowsKnownFolderResolver().resolve(KnownFolder.localAppData);
    final dir = Directory('$localAppData\\AppConfigShelf\\logs')
      ..createSync(recursive: true);

    // Retention: keep the 6 most recent, this run makes 7.
    final existing = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jsonl'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // names sort by timestamp
    for (final old in existing.skip(6)) {
      try {
        old.deleteSync();
      } on FileSystemException {
        // Another instance may hold it; retention retries next run.
      }
    }

    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final file = File('${dir.path}\\run-$stamp.jsonl');
    final sink = file.openWrite();

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      sink.writeln(jsonEncode({
        't': record.time.toUtc().toIso8601String(),
        'lvl': record.level.name,
        'log': record.loggerName,
        'msg': record.message,
        if (record.error != null) 'err': record.error.toString(),
        if (record.stackTrace != null) 'st': record.stackTrace.toString(),
      }));
      if (kDebugMode) {
        debugPrint('[${record.level.name}] ${record.message}');
      }
    });

    return AppLogging._(sink, dir.path);
  }

  /// Writes an uncaught-error crash report the user can attach to an issue.
  void writeCrashReport(Object error, StackTrace stack) {
    final log = Logger('crash');
    log.severe('uncaught error', error, stack);
    try {
      File('$logDirectory\\last-crash.txt').writeAsStringSync(
        'AppConfigShelf crash report\n'
        'time: ${DateTime.now().toUtc().toIso8601String()}\n'
        'error: $error\n\n$stack\n',
      );
    } on FileSystemException {
      // Crash reporting must never crash.
    }
  }

  Future<void> dispose() => _sink.close();
}

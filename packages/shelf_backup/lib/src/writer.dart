import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';

import 'backup_io.dart';
import 'events.dart';
import 'manifest.dart';
import 'planner.dart';

/// Writes a [BackupPlan] to an `.acshelf` package (ADR-002).
///
/// Best-effort policy: an unreadable file becomes a skip record and the
/// backup continues. The manifest is written last, so a crash mid-write
/// leaves a zip without a manifest — unambiguously invalid, never a
/// silently-partial "valid" package.
Stream<BackupEvent> writeBackup({
  required BackupPlan plan,
  required String outputPath,
  required BackupIo io,
  required String appVersion,
  int? dbSchemaVersion,
  String? dbContentVersion,
}) async* {
  final encoder = ZipFileEncoder()..create(outputPath);
  final manifestEntries = <ManifestEntry>[];
  final log = StringBuffer();

  try {
    for (final entry in plan.entries) {
      yield EntryStarted(entry.id, entry.name, entry.files.length);
      log.writeln('entry ${entry.id} (${entry.files.length} files)');

      final files = <ManifestFile>[];
      final skipped = <SkippedFile>[];
      var done = 0;

      for (final planned in entry.files) {
        try {
          // Pass 1: hash. Pass 2 (inside addFile): stream into the zip.
          // Two reads, but hashing must complete before we can decide the
          // manifest row, and memory stays flat either way.
          final digest =
              await sha256.bind(io.openRead(planned.absolutePath)).first;
          await encoder.addFile(File(planned.absolutePath), planned.storedPath);
          files.add(ManifestFile(
            storedPath: planned.storedPath,
            targetPath: planned.targetPath,
            absolute: planned.absolute,
            sha256: digest.toString(),
            size: planned.size,
            modifiedAt: planned.modified,
          ));
          done += 1;
          yield FileBackedUp(
              entry.id, planned.targetPath, done, entry.files.length);
        } on FileSystemException catch (e) {
          final reason = switch (e.osError?.errorCode) {
            5 => 'accessDenied', // ERROR_ACCESS_DENIED
            32 || 33 => 'fileLocked', // SHARING/LOCK_VIOLATION
            _ => 'readError',
          };
          skipped.add(SkippedFile(targetPath: planned.targetPath, reason: reason));
          log.writeln('  skip ${planned.targetPath}: $reason (${e.message})');
          yield FileSkipped(entry.id, planned.targetPath, reason);
        }
      }

      manifestEntries.add(ManifestEntry(
        source: entry.source,
        id: entry.id,
        name: entry.name,
        risk: entry.risk,
        files: files,
        skipped: skipped,
      ));
    }

    final manifest = PackageManifest(
      createdAt: DateTime.now(),
      appVersion: appVersion,
      dbSchemaVersion: dbSchemaVersion,
      dbContentVersion: dbContentVersion,
      machine: MachineInfo(
        hostname: Platform.localHostname,
        windowsBuild: Platform.operatingSystemVersion,
      ),
      entries: manifestEntries,
    );

    encoder.addArchiveFile(ArchiveFile.string(
        'logs/scan-report.json',
        jsonEncode({'log': log.toString()})));
    encoder.addArchiveFile(ArchiveFile.string(
        'manifest.json',
        const JsonEncoder.withIndent('  ').convert(manifest.toJson())));
    await encoder.close();

    yield BackupFinished(manifest, outputPath);
  } catch (_) {
    await encoder.close();
    rethrow;
  }
}

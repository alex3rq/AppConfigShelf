import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_backup/shelf_backup.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_win32/shelf_win32.dart';

import '../../shared/format.dart';
import '../home/history_store.dart';
import 'custom_items_store.dart';

final customItemsProvider =
    NotifierProvider<CustomItemsNotifier, List<CustomItem>>(
        CustomItemsNotifier.new);

class CustomItemsNotifier extends Notifier<List<CustomItem>> {
  final _store = CustomItemsStore();

  @override
  List<CustomItem> build() => _store.load();

  void add(CustomItem item) {
    state = [...state, item];
    _store.save(state);
  }

  void remove(String slug) {
    state = [for (final i in state) if (i.slug != slug) i];
    _store.save(state);
  }
}

/// Live progress of a running backup.
sealed class BackupRunState {
  const BackupRunState();
}

final class BackupIdle extends BackupRunState {
  const BackupIdle();
}

final class BackupRunning extends BackupRunState {
  const BackupRunning(this.currentEntry, this.filesDone, this.filesTotal);
  final String currentEntry;
  final int filesDone;
  final int filesTotal;
}

final class BackupDone extends BackupRunState {
  const BackupDone(this.manifest, this.outputPath);
  final PackageManifest manifest;
  final String outputPath;
}

final class BackupFailed extends BackupRunState {
  const BackupFailed(this.error);
  final Object error;
}

final backupRunProvider =
    NotifierProvider<BackupRunNotifier, BackupRunState>(BackupRunNotifier.new);

class BackupRunNotifier extends Notifier<BackupRunState> {
  @override
  BackupRunState build() => const BackupIdle();

  Future<void> run({
    required List<AppEntry> apps,
    required List<CustomItem> customItems,
    required String outputPath,
  }) async {
    state = const BackupRunning('Planning…', 0, 0);
    try {
      const io = RealBackupIo();
      final plan = planBackup(
        apps: apps,
        customItems: customItems,
        io: io,
        knownFolders: WindowsKnownFolderResolver(),
      );
      final total = plan.totalFiles;
      var done = 0;
      await for (final event in writeBackup(
        plan: plan,
        outputPath: outputPath,
        io: io,
        appVersion: '0.1.0',
      )) {
        switch (event) {
          case EntryStarted(:final name):
            state = BackupRunning(name, done, total);
          case FileBackedUp():
            done += 1;
            state = BackupRunning(event.entryId, done, total);
          case FileSkipped():
            break; // Reported in the final manifest.
          case BackupFinished(:final manifest, :final outputPath):
            state = BackupDone(manifest, outputPath);
            _recordHistory(manifest, outputPath,
                apps: apps.length, customItems: customItems.length);
        }
      }
    } catch (e) {
      state = BackupFailed(e);
    }
  }

  void reset() => state = const BackupIdle();

  void _recordHistory(PackageManifest manifest, String outputPath,
      {required int apps, required int customItems}) {
    int? size;
    try {
      size = File(outputPath).lengthSync();
    } on FileSystemException {
      // Size is cosmetic; the timeline row works without it.
    }
    ref.read(historyProvider.notifier).record(HistoryEvent(
          kind: HistoryKind.backup,
          path: outputPath,
          timestamp: DateTime.now(),
          summary: [
            '$apps apps',
            if (customItems > 0) '$customItems custom items',
            if (size != null) formatBytes(size),
          ].join(' · '),
        ));
  }
}

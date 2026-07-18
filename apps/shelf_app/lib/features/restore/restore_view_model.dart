import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_backup/shelf_backup.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_detect/shelf_detect.dart';
import 'package:shelf_win32/shelf_win32.dart';

import '../database/db_providers.dart';

sealed class RestoreUiState {
  const RestoreUiState();
}

final class RestoreIdle extends RestoreUiState {
  const RestoreIdle();
}

final class RestoreLoadFailed extends RestoreUiState {
  const RestoreLoadFailed(this.message);
  final String message;
}

/// Package opened, plan built — user is choosing complete vs selective.
final class RestoreSelecting extends RestoreUiState {
  const RestoreSelecting(this.package, this.plan, this.selected);
  final PackageReader package;
  final RestorePlan plan;
  final Set<String> selected;
}

final class RestoreRunning extends RestoreUiState {
  const RestoreRunning(this.currentEntry, this.filesDone);
  final String currentEntry;
  final int filesDone;
}

final class RestoreComplete extends RestoreUiState {
  const RestoreComplete(this.finished, this.entryFailures);
  final RestoreFinished finished;
  final List<RestoreEntryFailed> entryFailures;
}

final restoreProvider =
    NotifierProvider<RestoreNotifier, RestoreUiState>(RestoreNotifier.new);

class RestoreNotifier extends Notifier<RestoreUiState> {
  @override
  RestoreUiState build() => const RestoreIdle();

  Future<void> openPackage(String path) async {
    final opened = PackageReader.open(path);
    final package = opened.valueOrNull;
    if (package == null) {
      state = RestoreLoadFailed(opened.failureOrNull!.message);
      return;
    }

    // Detection gating: scan with the current database.
    final entries = await ref.read(dbEntriesProvider.future);
    final folders = WindowsKnownFolderResolver();
    final scan = scanSystem(
      entries: entries,
      registry: const WindowsRegistryView(),
      fileSystem: const RealFileSystem(),
      knownFolders: folders,
    );
    final plan = planRestore(
      manifest: package.manifest,
      detectedEntryIds: {
        for (final d in scan.detected)
          if (d.entryId != null) d.entryId!,
      },
      fileSystem: const RealFileSystem(),
      knownFolders: folders,
      knownEntryIds: {for (final e in entries) e.id},
    );
    state = RestoreSelecting(package, plan, plan.defaultSelection);
  }

  void toggle(String entryId, bool selected) {
    if (state case RestoreSelecting(:final package, :final plan, selected: final current)) {
      final next = {...current};
      selected ? next.add(entryId) : next.remove(entryId);
      state = RestoreSelecting(package, plan, next);
    }
  }

  void selectAllRestorable() {
    if (state case RestoreSelecting(:final package, :final plan)) {
      state = RestoreSelecting(package, plan, plan.defaultSelection);
    }
  }

  Future<void> run({required ConflictMode conflictMode}) async {
    if (state case RestoreSelecting(:final package, :final selected)) {
      var done = 0;
      state = const RestoreRunning('Starting…', 0);
      final failures = <RestoreEntryFailed>[];
      final folders = WindowsKnownFolderResolver();
      final undoDir =
          '${folders.resolve(KnownFolder.appData)}\\AppConfigShelf\\undo';
      try {
        await for (final event in executeRestore(
          package: package,
          selectedEntryIds: selected,
          knownFolders: folders,
          io: RealRestoreIo(),
          undoDirectory: undoDir,
          conflictMode: conflictMode,
        )) {
          switch (event) {
            case RestoreEntryStarted(:final name):
              state = RestoreRunning(name, done);
            case FileRestored():
              done += 1;
              state = RestoreRunning(event.entryId, done);
            case FileSkippedExisting():
              break;
            case RestoreEntryFailed():
              failures.add(event);
            case RestoreFinished():
              state = RestoreComplete(event, failures);
          }
        }
      } catch (e) {
        state = RestoreLoadFailed('Restore failed: $e');
      }
    }
  }

  void reset() => state = const RestoreIdle();
}

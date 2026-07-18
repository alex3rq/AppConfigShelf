import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_db/shelf_db.dart';
import 'package:shelf_win32/shelf_win32.dart';

final dbManagerProvider = Provider<DbManager>((ref) {
  final appData = WindowsKnownFolderResolver().resolve(KnownFolder.appData);
  return DbManager(cacheDir: '$appData\\AppConfigShelf\\db');
});

/// The official database: cached signed update if present, else the bundled
/// fallback asset. Invalidate after a successful update check to reload.
final dbBundleProvider = FutureProvider<DbBundle>((ref) async {
  final bundledJson = await rootBundle.loadString('assets/db.json');
  return ref.watch(dbManagerProvider).loadBest(bundledJson: bundledJson);
});

/// "My library": user-created entries and overrides of official entries.
final localEntriesProvider =
    NotifierProvider<LocalEntriesNotifier, LocalEntries>(
        LocalEntriesNotifier.new);

class LocalEntriesNotifier extends Notifier<LocalEntries> {
  late final LocalEntryStore _store = LocalEntryStore(
      '${WindowsKnownFolderResolver().resolve(KnownFolder.appData)}'
      r'\AppConfigShelf\local-entries');

  @override
  LocalEntries build() => _store.load();

  void save(AppEntry entry) {
    _store.save(entry);
    state = _store.load();
  }

  void delete(String id) {
    _store.delete(id);
    state = _store.load();
  }
}

/// Official + local library merged; local overrides win. This is what scan,
/// backup, and restore consume.
final mergedDbProvider = FutureProvider<MergedEntries>((ref) async {
  final bundle = await ref.watch(dbBundleProvider.future);
  final local = ref.watch(localEntriesProvider);
  return mergeEntries(bundle.entries, local.entries);
});

/// Convenience view of the merged entries list.
final dbEntriesProvider = FutureProvider<List<AppEntry>>(
    (ref) async => (await ref.watch(mergedDbProvider.future)).entries);

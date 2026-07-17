import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_db/shelf_db.dart';
import 'package:shelf_win32/shelf_win32.dart';

final dbManagerProvider = Provider<DbManager>((ref) {
  final appData = WindowsKnownFolderResolver().resolve(KnownFolder.appData);
  return DbManager(cacheDir: '$appData\\AppConfigShelf\\db');
});

/// The active database: cached signed update if present, else the bundled
/// fallback asset. Invalidate after a successful update check to reload.
final dbBundleProvider = FutureProvider<DbBundle>((ref) async {
  final bundledJson = await rootBundle.loadString('assets/db.json');
  return ref.watch(dbManagerProvider).loadBest(bundledJson: bundledJson);
});

/// Convenience view of the entries list.
final dbEntriesProvider = FutureProvider<List<AppEntry>>(
    (ref) async => (await ref.watch(dbBundleProvider.future)).entries);

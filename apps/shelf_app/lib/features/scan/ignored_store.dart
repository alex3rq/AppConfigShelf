import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_win32/shelf_win32.dart';

/// Per-user hidden apps: exact display names the user chose to hide from
/// the "not in database yet" list. Persisted at
/// %APPDATA%\AppConfigShelf\ignored.json.
final class IgnoredStore {
  IgnoredStore({String? overridePath})
      : _path = overridePath ??
            '${WindowsKnownFolderResolver().resolve(KnownFolder.appData)}'
                r'\AppConfigShelf\ignored.json';

  final String _path;

  Set<String> load() {
    final file = File(_path);
    if (!file.existsSync()) return {};
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! List) return {};
      return {for (final e in decoded) if (e is String) e};
    } on FormatException {
      return {};
    }
  }

  void save(Set<String> names) {
    final file = File(_path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(names.toList()..sort()));
  }
}

final ignoredNamesProvider =
    NotifierProvider<IgnoredNamesNotifier, Set<String>>(
        IgnoredNamesNotifier.new);

class IgnoredNamesNotifier extends Notifier<Set<String>> {
  final _store = IgnoredStore();

  @override
  Set<String> build() => _store.load();

  void hide(String displayName) {
    state = {...state, displayName};
    _store.save(state);
  }

  void unhide(String displayName) {
    state = {...state}..remove(displayName);
    _store.save(state);
  }
}

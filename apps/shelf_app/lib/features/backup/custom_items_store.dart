import 'dart:convert';
import 'dart:io';

import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_rules/shelf_rules.dart';
import 'package:shelf_win32/shelf_win32.dart';

/// Persists the user's custom backup items to
/// `%APPDATA%\AppConfigShelf\custom_items.json` so they are pre-listed on
/// every backup. (Simple JSON for now; migrates to the drift catalog when
/// backup history lands.)
final class CustomItemsStore {
  CustomItemsStore({String? overridePath})
      : _path = overridePath ??
            '${WindowsKnownFolderResolver().resolve(KnownFolder.appData)}'
                r'\AppConfigShelf\custom_items.json';

  final String _path;

  List<CustomItem> load() {
    final file = File(_path);
    if (!file.existsSync()) return const [];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! List) return const [];
      final items = <CustomItem>[];
      for (final raw in decoded) {
        if (raw is! Map) continue;
        final parsed =
            parseCustomItem(raw.map((k, v) => MapEntry(k.toString(), v)));
        if (parsed.value != null) items.add(parsed.value!);
      }
      return items;
    } on FormatException {
      return const [];
    }
  }

  void save(List<CustomItem> items) {
    final file = File(_path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(const JsonEncoder.withIndent('  ')
        .convert([for (final i in items) customItemToJson(i)]));
  }
}

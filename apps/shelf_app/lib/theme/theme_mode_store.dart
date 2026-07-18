import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart' show KnownFolder;
import 'package:shelf_win32/shelf_win32.dart';

/// Persists app settings (currently just theme mode) to
/// `%APPDATA%\AppConfigShelf\settings.json`. Defaults to dark.
final class SettingsStore {
  SettingsStore({String? overridePath})
      : _path = overridePath ??
            '${WindowsKnownFolderResolver().resolve(KnownFolder.appData)}'
                r'\AppConfigShelf\settings.json';

  final String _path;

  ThemeMode loadThemeMode() {
    final file = File(_path);
    if (!file.existsSync()) return ThemeMode.dark;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) return ThemeMode.dark;
      return switch (decoded['themeMode']) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
    } on FormatException {
      return ThemeMode.dark;
    }
  }

  void saveThemeMode(ThemeMode mode) {
    final file = File(_path);
    file.parent.createSync(recursive: true);
    Map<String, Object?> existing = {};
    if (file.existsSync()) {
      try {
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is Map) {
          existing = decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } on FormatException {
        // Corrupt settings file: rewrite from scratch.
      }
    }
    existing['themeMode'] = mode.name;
    file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(existing));
  }
}

final settingsStoreProvider = Provider<SettingsStore>((ref) => SettingsStore());

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

final class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(settingsStoreProvider).loadThemeMode();

  void set(ThemeMode mode) {
    state = mode;
    ref.read(settingsStoreProvider).saveThemeMode(mode);
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart' show KnownFolder;
import 'package:shelf_win32/shelf_win32.dart';

/// Persists app settings (currently just theme mode) to
/// `%APPDATA%\AppConfigShelf\settings.json`. Defaults to following the
/// Windows setting.
final class SettingsStore {
  SettingsStore({String? overridePath})
      : _path = overridePath ??
            '${WindowsKnownFolderResolver().resolve(KnownFolder.appData)}'
                r'\AppConfigShelf\settings.json';

  final String _path;

  ThemeMode loadThemeMode() {
    final file = File(_path);
    if (!file.existsSync()) return ThemeMode.system;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) return ThemeMode.system;
      return switch (decoded['themeMode']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } on FormatException {
      return ThemeMode.system;
    }
  }

  void saveThemeMode(ThemeMode mode) => _merge('themeMode', mode.name);

  /// Saved language code ('en' | 'es') or null to follow Windows.
  String? loadLocale() {
    final file = File(_path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) return null;
      return switch (decoded['locale']) {
        'en' => 'en',
        'es' => 'es',
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }

  void saveLocale(String? code) => _merge('locale', code);

  void _merge(String key, Object? value) {
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
    if (value == null) {
      existing.remove(key);
    } else {
      existing[key] = value;
    }
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

/// App locale override; null = follow the Windows display language.
final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

final class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.read(settingsStoreProvider).loadLocale();
    return code == null ? null : Locale(code);
  }

  void set(Locale? locale) {
    state = locale;
    ref.read(settingsStoreProvider).saveLocale(locale?.languageCode);
  }
}

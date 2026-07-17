import 'package:shelf_core/shelf_core.dart';
import 'package:win32_registry/win32_registry.dart';

/// [RegistryView] backed by the live Windows registry (read-only opens).
final class WindowsRegistryView implements RegistryView {
  const WindowsRegistryView();

  /// Splits `HKLM\Sub\Key` (or long hive names) into (hive root, subpath).
  /// Returns null for unknown hives — engines only ever pass HKCU/HKLM,
  /// which the shelf_rules parser guarantees for db-sourced key paths.
  (PredefinedRegistryKey, String)? _split(String keyPath) {
    final separator = keyPath.indexOf(r'\');
    final hive =
        (separator == -1 ? keyPath : keyPath.substring(0, separator))
            .toUpperCase();
    final rest = separator == -1 ? '' : keyPath.substring(separator + 1);
    final root = switch (hive) {
      'HKCU' || 'HKEY_CURRENT_USER' => CURRENT_USER,
      'HKLM' || 'HKEY_LOCAL_MACHINE' => LOCAL_MACHINE,
      _ => null,
    };
    return root == null ? null : (root, rest);
  }

  T? _withKey<T>(String keyPath, T? Function(BaseRegistryKey key) action) {
    final split = _split(keyPath);
    if (split == null) return null;
    final (root, rest) = split;
    final BaseRegistryKey key;
    try {
      key = rest.isEmpty ? root : root.open(rest);
    } on Object {
      return null; // Key missing or access denied — both read as "absent".
    }
    try {
      return action(key);
    } on Object {
      return null;
    } finally {
      if (key is RegistryKey) key.close();
    }
  }

  @override
  bool keyExists(String keyPath) => _withKey(keyPath, (_) => true) ?? false;

  @override
  List<String> subKeyNames(String keyPath) =>
      _withKey(keyPath, (key) => key.keys) ?? const [];

  @override
  String? stringValue(String keyPath, String valueName) =>
      _withKey(keyPath, (key) => key.getString(valueName));
}

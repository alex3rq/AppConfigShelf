import 'storage_path.dart';

/// Read-only view of the Windows registry. Engines depend on this interface;
/// shelf_win32 provides the real implementation, tests provide fakes.
///
/// Key paths use the storage format from db entries: `HIVE\Sub\Key` with
/// short (`HKCU`) or long (`HKEY_CURRENT_USER`) hive names.
abstract interface class RegistryView {
  /// Whether [keyPath] exists.
  bool keyExists(String keyPath);

  /// Names of the direct subkeys of [keyPath]. Empty if the key does not
  /// exist or has none.
  List<String> subKeyNames(String keyPath);

  /// A string (REG_SZ/REG_EXPAND_SZ) value, or null when the key or value
  /// is missing or has another type.
  String? stringValue(String keyPath, String valueName);
}

/// Read-only view of the filesystem, path arguments already resolved to
/// absolute Windows paths.
abstract interface class FileSystemView {
  bool exists(String absolutePath);
}

/// Resolves [KnownFolder] tokens to absolute paths for the current user.
/// The real implementation uses the Known Folders API — never environment
/// variables, which can lie under elevation.
abstract interface class KnownFolderResolver {
  /// Absolute path without trailing separator, e.g.
  /// `C:\Users\alex\AppData\Roaming`.
  String resolve(KnownFolder folder);
}

extension ExpandTokenizedPath on KnownFolderResolver {
  /// Expands a tokenized path to an absolute path.
  String expand(TokenizedPath path) {
    final root = resolve(path.root);
    return path.segments.isEmpty ? root : '$root\\${path.segments.join(r'\')}';
  }
}

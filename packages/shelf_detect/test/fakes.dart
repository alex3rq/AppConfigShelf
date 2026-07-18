import 'package:shelf_core/shelf_core.dart';

/// In-memory registry: keys mapped to {valueName: value}.
final class FakeRegistry implements RegistryView {
  FakeRegistry(this._keys);

  /// Original-case key paths, matched case-insensitively like the real
  /// registry.
  final Map<String, Map<String, String>> _keys;

  String? _find(String keyPath) {
    final wanted = keyPath.toUpperCase();
    for (final k in _keys.keys) {
      if (k.toUpperCase() == wanted) return k;
    }
    return null;
  }

  @override
  bool keyExists(String keyPath) => _find(keyPath) != null;

  @override
  List<String> subKeyNames(String keyPath) {
    final prefix = '${keyPath.toUpperCase()}\\';
    return [
      for (final k in _keys.keys)
        if (k.toUpperCase().startsWith(prefix) &&
            !k.substring(prefix.length).contains(r'\'))
          k.substring(prefix.length),
    ];
  }

  @override
  String? stringValue(String keyPath, String valueName) {
    final key = _find(keyPath);
    return key == null ? null : _keys[key]?[valueName];
  }
}

final class FakeFileSystem implements FileSystemView {
  FakeFileSystem(Iterable<String> existing) : _existing = existing.toList();

  /// Original-case paths, matched case-insensitively like NTFS.
  final List<String> _existing;

  @override
  bool exists(String absolutePath) {
    final wanted = absolutePath.toUpperCase();
    return _existing.any((p) => p.toUpperCase() == wanted);
  }

  @override
  List<String> subdirectoryNames(String absolutePath) {
    final prefix = '${absolutePath.toUpperCase()}\\';
    final names = <String>{};
    for (final path in _existing) {
      if (path.toUpperCase().startsWith(prefix)) {
        names.add(path.substring(prefix.length).split(r'\').first);
      }
    }
    return names.toList();
  }
}

final class FakeKnownFolders implements KnownFolderResolver {
  static const _roots = {
    KnownFolder.appData: r'C:\Users\test\AppData\Roaming',
    KnownFolder.localAppData: r'C:\Users\test\AppData\Local',
    KnownFolder.programData: r'C:\ProgramData',
    KnownFolder.userProfile: r'C:\Users\test',
    KnownFolder.documents: r'C:\Users\test\Documents',
  };

  @override
  String resolve(KnownFolder folder) => _roots[folder]!;
}

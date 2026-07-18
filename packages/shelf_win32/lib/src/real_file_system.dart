import 'dart:io';

import 'package:shelf_core/shelf_core.dart';

/// [FileSystemView] over the real filesystem.
final class RealFileSystem implements FileSystemView {
  const RealFileSystem();

  @override
  bool exists(String absolutePath) =>
      FileSystemEntity.typeSync(absolutePath) != FileSystemEntityType.notFound;

  @override
  List<String> subdirectoryNames(String absolutePath) {
    try {
      return [
        for (final entity in Directory(absolutePath).listSync(followLinks: false))
          if (entity is Directory)
            entity.path.split(Platform.pathSeparator).last,
      ];
    } on FileSystemException {
      return const [];
    }
  }
}

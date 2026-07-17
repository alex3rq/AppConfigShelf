import 'dart:io';

import 'package:shelf_core/shelf_core.dart';

/// [FileSystemView] over the real filesystem.
final class RealFileSystem implements FileSystemView {
  const RealFileSystem();

  @override
  bool exists(String absolutePath) =>
      FileSystemEntity.typeSync(absolutePath) != FileSystemEntityType.notFound;
}

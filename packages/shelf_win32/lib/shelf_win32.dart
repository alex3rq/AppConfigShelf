/// Windows infrastructure: registry access, known-folder resolution,
/// filesystem checks. The only package allowed to touch win32 APIs;
/// everything is exposed through the view interfaces defined in shelf_core
/// so engines stay testable on any platform.
/// See docs/plan/03-windows-native.md.
library;

export 'src/known_folders.dart';
export 'src/real_file_system.dart';
export 'src/registry.dart';

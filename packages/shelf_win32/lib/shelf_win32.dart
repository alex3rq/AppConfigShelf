/// Windows infrastructure: registry access, known-folder resolution, process
/// detection. The only package allowed to touch win32 APIs; everything is
/// exposed through interfaces defined in shelf_core so engines stay testable
/// on any platform. See docs/plan/03-windows-native.md.
///
/// Implemented in milestone M1.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected NavigationPane index. Lives in a provider so pages (e.g. Home's
/// action cards) can navigate the shell.
final shellIndexProvider = StateProvider<int>((ref) => 0);

/// Pane order, kept in one place for cross-page navigation.
abstract final class ShellTab {
  static const home = 0;
  static const applications = 1;
  static const backup = 2;
  static const restore = 3;
  static const library = 4;

  /// Footer items count into the pane's selection index: the db-status
  /// PaneItemAction is 5, Settings is 6.
  static const settings = 6;
}

import 'package:fluent_ui/fluent_ui.dart';

/// Design tokens from the Figma redesign (frame "00 Foundations").
///
/// Two palettes (light/dark) plus a shared type ramp and spacing scale.
/// Widgets read the active palette via [ShelfTokens.of].
final class ShelfPalette {
  const ShelfPalette({
    required this.mica,
    required this.content,
    required this.card,
    required this.stroke,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.success,
    required this.caution,
    required this.danger,
    required this.expert,
  });

  final Color mica;
  final Color content;
  final Color card;
  final Color stroke;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color success;
  final Color caution;
  final Color danger;
  final Color expert;

  static const light = ShelfPalette(
    mica: Color(0xFFF2F4F4),
    content: Color(0xFFFFFFFF),
    card: Color(0xFFF6F8F8),
    stroke: Color(0xFFE3E7E7),
    textPrimary: Color(0xFF1A1F1F),
    textSecondary: Color(0xFF5C6666),
    accent: Color(0xFF0E7A7A),
    success: Color(0xFF107C10),
    caution: Color(0xFF9A5B00),
    danger: Color(0xFFC42B1C),
    expert: Color(0xFF6B4FBB),
  );

  static const dark = ShelfPalette(
    mica: Color(0xFF1E2121),
    content: Color(0xFF262B2B),
    card: Color(0xFF2F3434),
    stroke: Color(0xFF304343),
    textPrimary: Color(0xFFF3F6F6),
    textSecondary: Color(0xFFA6B1B1),
    accent: Color(0xFF4FC3C3),
    success: Color(0xFF6CCB5F),
    caution: Color(0xFFF2C063),
    danger: Color(0xFFFF8AB0),
    expert: Color(0xFFB490F0),
  );
}

/// Spacing scale: 4-8-12-16-24-32. Radius: 4 for controls, 8 for cards.
final class ShelfSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double controlRadius = 4;
  static const double cardRadius = 8;
}

final class ShelfType {
  static const display = TextStyle(fontSize: 34, fontWeight: FontWeight.w600);
  static const title = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  static const subtitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static const bodyStrong = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static const mono = TextStyle(
    fontSize: 12,
    fontFamily: 'Cascadia Mono',
    fontFamilyFallback: ['Consolas', 'monospace'],
  );
}

/// Resolves the active palette from the ambient Fluent brightness.
final class ShelfTokens {
  static ShelfPalette of(BuildContext context) =>
      FluentTheme.of(context).brightness == Brightness.dark
          ? ShelfPalette.dark
          : ShelfPalette.light;
}

FluentThemeData shelfLightTheme() {
  const p = ShelfPalette.light;
  return FluentThemeData(
    accentColor: Colors.teal,
    scaffoldBackgroundColor: p.mica,
    micaBackgroundColor: p.mica,
    cardColor: p.content,
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: p.mica,
    ),
  );
}

FluentThemeData shelfDarkTheme() {
  const p = ShelfPalette.dark;
  return FluentThemeData(
    brightness: Brightness.dark,
    accentColor: Colors.teal,
    scaffoldBackgroundColor: p.mica,
    micaBackgroundColor: p.mica,
    cardColor: p.content,
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: p.mica,
    ),
  );
}

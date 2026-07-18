import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/shelf_theme.dart';

/// Rounded content card per the design tokens (radius 8, stroke border).
/// [tinted] paints the accent-tinted variant used for the primary action
/// card on Home and selected choice cards.
class ShelfCard extends StatelessWidget {
  const ShelfCard({
    super.key,
    required this.child,
    this.tinted = false,
    this.padding = const EdgeInsets.all(ShelfSpacing.lg),
    this.onPressed,
  });

  final Widget child;
  final bool tinted;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tinted ? p.accent.withValues(alpha: 0.08) : p.content,
        borderRadius: BorderRadius.circular(ShelfSpacing.cardRadius),
        border: Border.all(color: tinted ? p.accent : p.stroke),
      ),
      child: child,
    );
    if (onPressed == null) return card;
    return HoverButton(
      onPressed: onPressed,
      builder: (context, states) => FocusBorder(
        focused: states.isFocused,
        child: card,
      ),
    );
  }
}

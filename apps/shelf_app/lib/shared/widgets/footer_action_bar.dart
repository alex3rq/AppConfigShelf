import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/shelf_theme.dart';

/// Bottom bar for wizard pages: summary on the left, note + primary action
/// on the right, separated from the content by a top stroke.
class FooterActionBar extends StatelessWidget {
  const FooterActionBar({
    super.key,
    this.summary,
    this.note,
    this.action,
  });

  /// Left side, e.g. "14 apps · 3 custom items · est. 842 MB" plus warnings.
  final Widget? summary;

  /// Right-side muted text, e.g. "Writes one .acshelf file …".
  final Widget? note;

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ShelfSpacing.xl, vertical: ShelfSpacing.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.stroke)),
      ),
      child: Row(
        children: [
          if (summary != null)
            Expanded(
                child: DefaultTextStyle.merge(
                    style: ShelfType.body.copyWith(color: p.textPrimary),
                    child: summary!))
          else
            const Spacer(),
          if (note != null) ...[
            DefaultTextStyle.merge(
                style: ShelfType.caption.copyWith(color: p.textSecondary),
                child: note!),
            const SizedBox(width: ShelfSpacing.lg),
          ],
          ?action,
        ],
      ),
    );
  }
}

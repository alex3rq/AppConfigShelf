import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/shelf_theme.dart';

/// Page title (24 SB) + caption subtitle, with optional trailing actions —
/// the header pattern every redesigned screen shares.
class ShelfPageHeader extends StatelessWidget {
  const ShelfPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          ShelfSpacing.xl, ShelfSpacing.xl, ShelfSpacing.xl, ShelfSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        ShelfType.title.copyWith(color: p.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: ShelfSpacing.xs),
                  Text(subtitle!,
                      style: ShelfType.caption
                          .copyWith(color: p.textSecondary)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

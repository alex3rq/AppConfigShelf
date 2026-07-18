import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/shelf_theme.dart';

/// "1 Select — 2 Back up — 3 Done" step indicator for the wizard pages.
/// [current] is zero-based.
class WizardSteps extends StatelessWidget {
  const WizardSteps({super.key, required this.labels, required this.current});

  final List<String> labels;
  final int current;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: ShelfSpacing.sm),
              child: Text('—',
                  style:
                      ShelfType.caption.copyWith(color: p.textSecondary)),
            ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: i == current ? p.accent.withValues(alpha: 0.16) : null,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${i + 1} ${labels[i]}',
              style: ShelfType.caption.copyWith(
                color: i == current ? p.accent : p.textSecondary,
                fontWeight:
                    i == current ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

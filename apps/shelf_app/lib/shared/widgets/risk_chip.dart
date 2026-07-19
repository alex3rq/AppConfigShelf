import 'package:fluent_ui/fluent_ui.dart';
import 'package:shelf_core/shelf_core.dart';

import '../../l10n/gen/app_localizations.dart';

import '../../theme/shelf_theme.dart';

/// Pill chip for an entry's [RiskTier]: Safe / Caution / Expert.
class RiskChip extends StatelessWidget {
  const RiskChip({super.key, required this.risk});

  final RiskTier risk;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    final s = S.of(context);
    final (label, color) = switch (risk) {
      RiskTier.safe => (s.chipSafe, p.success),
      RiskTier.caution => (s.chipCaution, p.caution),
      RiskTier.expert => (s.chipExpert, p.expert),
    };
    return ShelfChip(label: label, color: color);
  }
}

/// Base pill chip: 12px label on a translucent tint of [color].
class ShelfChip extends StatelessWidget {
  const ShelfChip({super.key, required this.label, this.color});

  final String label;

  /// Chip tint; defaults to the secondary text color (neutral chip).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    final c = color ?? p.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: ShelfType.caption.copyWith(
              color: Color.lerp(
                  c, p.textPrimary, 0.15)!, // keep AA on tinted bg
              fontWeight: FontWeight.w600)),
    );
  }
}

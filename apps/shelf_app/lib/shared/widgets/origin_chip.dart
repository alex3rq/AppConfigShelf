import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/shelf_theme.dart';
import 'risk_chip.dart';

enum ChipOrigin { local, customized, official }

/// Pill chip for where an entry comes from: local / customized / official.
class OriginChip extends StatelessWidget {
  const OriginChip({super.key, required this.origin});

  final ChipOrigin origin;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    final (label, color) = switch (origin) {
      ChipOrigin.local => ('local', p.accent),
      ChipOrigin.customized => ('customized', p.caution),
      ChipOrigin.official => ('official', p.textSecondary),
    };
    return ShelfChip(label: label, color: color);
  }
}

import 'package:fluent_ui/fluent_ui.dart';

import '../../l10n/gen/app_localizations.dart';
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
    final s = S.of(context);
    final (label, color) = switch (origin) {
      ChipOrigin.local => (s.chipLocal, p.accent),
      ChipOrigin.customized => (s.chipCustomized, p.caution),
      ChipOrigin.official => (s.chipOfficial, p.textSecondary),
    };
    return ShelfChip(label: label, color: color);
  }
}

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/shelf_card.dart';
import '../../theme/shelf_theme.dart';
import '../../theme/theme_mode_store.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: ListView(
        children: [
          ShelfPageHeader(title: s.settingsTitle, subtitle: s.settingsSubtitle),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: ShelfSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShelfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                          icon: FluentIcons.color,
                          title: s.appearanceSection),
                      const SizedBox(height: ShelfSpacing.md),
                      InfoLabel(
                        label: s.themeLabel,
                        child: ComboBox<ThemeMode>(
                          value: themeMode,
                          items: [
                            ComboBoxItem(
                                value: ThemeMode.system,
                                child: Text(s.themeSystem)),
                            ComboBoxItem(
                                value: ThemeMode.dark,
                                child: Text(s.themeDark)),
                            ComboBoxItem(
                                value: ThemeMode.light,
                                child: Text(s.themeLight)),
                          ],
                          onChanged: (m) => m == null
                              ? null
                              : ref.read(themeModeProvider.notifier).set(m),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ShelfSpacing.lg),
                ShelfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                          icon: FluentIcons.locale_language,
                          title: s.languageSection),
                      const SizedBox(height: ShelfSpacing.md),
                      InfoLabel(
                        label: s.languageLabel,
                        child: ComboBox<String>(
                          value: locale?.languageCode ?? 'system',
                          items: [
                            ComboBoxItem(
                                value: 'system',
                                child: Text(s.languageSystem)),
                            ComboBoxItem(
                                value: 'en', child: Text(s.langEnglish)),
                            ComboBoxItem(
                                value: 'es', child: Text(s.langSpanish)),
                          ],
                          onChanged: (v) => ref
                              .read(localeProvider.notifier)
                              .set(v == null || v == 'system'
                                  ? null
                                  : Locale(v)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon tile + subtitle-weight title for a settings card.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: p.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(ShelfSpacing.controlRadius),
          ),
          child: Icon(icon, size: 14, color: p.accent),
        ),
        const SizedBox(width: ShelfSpacing.md),
        Text(title,
            style: ShelfType.subtitle.copyWith(color: p.textPrimary)),
      ],
    );
  }
}

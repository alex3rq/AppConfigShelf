import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'features/backup/backup_page.dart';
import 'features/database/database_page.dart';
import 'features/database/db_providers.dart';
import 'features/home/history_store.dart';
import 'features/home/home_page.dart';
import 'features/restore/restore_page.dart';
import 'features/scan/scan_page.dart';
import 'features/settings/settings_page.dart';
import 'l10n/gen/app_localizations.dart';
import 'shared/app_logging.dart';
import 'shell_index.dart';
import 'theme/shelf_theme.dart';
import 'theme/theme_mode_store.dart';

void main() {
  final logging = AppLogging.init();
  final log = Logger('app');

  FlutterError.onError = (details) {
    logging.writeCrashReport(details.exception, details.stack ?? StackTrace.empty);
    FlutterError.presentError(details);
  };

  runZonedGuarded(() {
    log.info('AppConfigShelf starting');
    runApp(const ProviderScope(child: ShelfApp()));
  }, (error, stack) {
    logging.writeCrashReport(error, stack);
  });
}

class ShelfApp extends ConsumerWidget {
  const ShelfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluentApp(
      title: 'AppConfigShelf',
      themeMode: ref.watch(themeModeProvider),
      theme: shelfLightTheme(),
      darkTheme: shelfDarkTheme(),
      locale: ref.watch(localeProvider),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    final s = S.of(context);
    return NavigationView(
      pane: NavigationPane(
        selected: index,
        onChanged: (i) => ref.read(shellIndexProvider.notifier).state = i,
        displayMode: PaneDisplayMode.auto,
        size: const NavigationPaneSize(openWidth: 220),
        header: const _PaneHeader(),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: Text(s.navHome),
            body: const HomePage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.grid_view_medium),
            title: Text(s.navApplications),
            body: const ScanPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.save),
            title: Text(s.navBackup),
            body: const BackupPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.history),
            title: Text(s.navRestore),
            body: const RestorePage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.library),
            title: Text(s.navLibrary),
            body: const DatabasePage(),
          ),
        ],
        footerItems: [
          PaneItemAction(
            icon: const Icon(FluentIcons.info),
            title: const _PaneStatusFooter(),
            onTap: () => ref.read(shellIndexProvider.notifier).state =
                ShellTab.library,
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: Text(s.navSettings),
            body: const SettingsPage(),
          ),
        ],
      ),
    );
  }
}

class _PaneHeader extends StatelessWidget {
  const _PaneHeader();

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShelfSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(ShelfSpacing.controlRadius),
            ),
            child: Icon(FluentIcons.archive, size: 13, color: p.accent),
          ),
          const SizedBox(width: ShelfSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AppConfigShelf',
                  style: ShelfType.bodyStrong
                      .copyWith(color: p.textPrimary, height: 1.1)),
              Text(S.of(context).appTagline,
                  style: ShelfType.caption
                      .copyWith(color: p.textSecondary, height: 1.1)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact db-version / last-backup status line rendered as the title of a
/// pane footer item, so it works in both expanded and compact pane modes.
class _PaneStatusFooter extends ConsumerWidget {
  const _PaneStatusFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final p = ShelfTokens.of(context);
    final bundle = ref.watch(dbBundleProvider).valueOrNull;
    final lastBackup = ref
        .watch(historyProvider)
        .where((e) => e.kind == HistoryKind.backup)
        .firstOrNull;

    String relative(DateTime t) {
      final days = DateTime.now().difference(t).inDays;
      if (days < 1) return s.relativeToday;
      if (days == 1) return s.relativeYesterday;
      return s.relativeDaysAgoShort(days);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bundle == null
              ? s.statusDbLoading
              : s.statusDb(bundle.contentVersion, bundle.entries.length),
          style: ShelfType.caption
              .copyWith(color: p.textSecondary, height: 1.1),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          lastBackup == null
              ? s.statusNoBackups
              : s.statusLastBackup(relative(lastBackup.timestamp)),
          style: ShelfType.caption
              .copyWith(color: p.textSecondary, height: 1.1),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'features/backup/backup_page.dart';
import 'features/database/database_page.dart';
import 'features/restore/restore_page.dart';
import 'features/scan/scan_page.dart';
import 'shared/app_logging.dart';

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

class ShelfApp extends StatelessWidget {
  const ShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'AppConfigShelf',
      themeMode: ThemeMode.system,
      theme: FluentThemeData(accentColor: Colors.teal),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.teal,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      pane: NavigationPane(
        selected: _index,
        onChanged: (i) => setState(() => _index = i),
        displayMode: PaneDisplayMode.compact,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.search),
            title: const Text('Applications'),
            body: const ScanPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.save),
            title: const Text('Backup'),
            body: const BackupPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.history),
            title: const Text('Restore'),
            body: const RestorePage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.database),
            title: const Text('Database'),
            body: const DatabasePage(),
          ),
        ],
      ),
    );
  }
}

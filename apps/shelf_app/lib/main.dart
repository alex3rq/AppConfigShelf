import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/scan/scan_page.dart';

void main() {
  runApp(const ProviderScope(child: ShelfApp()));
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
      home: const ScanPage(),
    );
  }
}

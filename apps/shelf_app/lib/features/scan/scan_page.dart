import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_detect/shelf_detect.dart';

import 'scan_view_model.dart';

class ScanPage extends ConsumerWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanProvider);
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Installed applications'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.search),
              label: const Text('Scan system'),
              onPressed: scan.isLoading
                  ? null
                  : () => ref.read(scanProvider.notifier).scan(),
            ),
          ],
        ),
      ),
      content: switch (scan) {
        AsyncData(value: null) => const Center(
            child: Text('Run a scan to detect installed applications.')),
        AsyncData(:final value?) => _ResultList(result: value),
        AsyncError(:final error) =>
          Center(child: Text('Scan failed: $error')),
        _ => const Center(child: ProgressRing()),
      },
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.result});

  final ResolutionResult result;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        Text('Recognized (${result.detected.length})',
            style: theme.typography.subtitle),
        const SizedBox(height: 8),
        for (final app in result.detected)
          ListTile(
            leading: const Icon(FluentIcons.check_mark),
            title: Text(app.displayName),
            subtitle: Text(
                '${app.entryId}  ·  v${app.version ?? '?'}  ·  confidence ${(app.confidence * 100).round()}%'),
          ),
        const SizedBox(height: 16),
        Text('Not in database yet (${result.unknown.length})',
            style: theme.typography.subtitle),
        const SizedBox(height: 8),
        for (final evidence in result.unknown)
          ListTile(
            leading: const Icon(FluentIcons.unknown),
            title: Text(evidence.displayName ?? '(unnamed)'),
            subtitle: Text([
              if (evidence.publisher != null) evidence.publisher!,
              if (evidence.version != null) 'v${evidence.version}',
            ].join('  ·  ')),
          ),
      ],
    );
  }
}

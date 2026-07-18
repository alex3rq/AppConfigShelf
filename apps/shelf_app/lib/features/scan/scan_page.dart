import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_detect/shelf_detect.dart';

import '../database/db_providers.dart';
import 'config_finder_dialog.dart';
import 'ignored_store.dart';
import 'scan_view_model.dart';

/// The official ignore patterns from the current db bundle, compiled once.
final _ignoreMatcherProvider = FutureProvider<IgnoreMatcher>((ref) async {
  final bundle = await ref.watch(dbBundleProvider.future);
  return IgnoreMatcher(bundle.ignorePatterns);
});

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

class _ResultList extends ConsumerWidget {
  const _ResultList({required this.result});

  final ResolutionResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final merged = ref.watch(mergedDbProvider).valueOrNull;
    final ignoreMatcher = ref.watch(_ignoreMatcherProvider).valueOrNull;
    final hiddenNames = ref.watch(ignoredNamesProvider);
    String badge(String? entryId) {
      if (entryId == null || merged == null) return '';
      if (merged.freshLocalIds.contains(entryId)) return '  ·  local';
      if (merged.overriddenIds.contains(entryId)) return '  ·  customized';
      return '';
    }

    // Split unknowns: visible / officially ignored / hidden by user.
    final visible = <InstallEvidence>[];
    final officialIgnored = <InstallEvidence>[];
    final userHidden = <InstallEvidence>[];
    for (final evidence in result.unknown) {
      final name = evidence.displayName;
      if (name != null && hiddenNames.contains(name)) {
        userHidden.add(evidence);
      } else if (ignoreMatcher?.isIgnored(name) ?? false) {
        officialIgnored.add(evidence);
      } else {
        visible.add(evidence);
      }
    }
    final hiddenCount = officialIgnored.length + userHidden.length;

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
                '${app.entryId}  ·  v${app.version ?? '?'}  ·  confidence ${(app.confidence * 100).round()}%'
                '${badge(app.entryId)}'),
          ),
        const SizedBox(height: 16),
        Text('Not in database yet (${visible.length})',
            style: theme.typography.subtitle),
        const SizedBox(height: 8),
        for (final evidence in visible)
          ListTile(
            leading: const Icon(FluentIcons.unknown),
            title: Text(evidence.displayName ?? '(unnamed)'),
            subtitle: Text([
              if (evidence.publisher != null) evidence.publisher!,
              if (evidence.version != null) 'v${evidence.version}',
            ].join('  ·  ')),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Button(
                onPressed: () =>
                    showConfigFinderDialog(context, ref, evidence),
                child: const Text('Find config…'),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(FluentIcons.hide3),
                onPressed: evidence.displayName == null
                    ? null
                    : () => ref
                        .read(ignoredNamesProvider.notifier)
                        .hide(evidence.displayName!),
              ),
            ]),
          ),
        if (hiddenCount > 0) ...[
          const SizedBox(height: 16),
          Expander(
            header: Text('Hidden ($hiddenCount)'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final evidence in userHidden)
                  ListTile(
                    leading: const Icon(FluentIcons.hide3, size: 14),
                    title: Text(evidence.displayName ?? '(unnamed)'),
                    subtitle: const Text('hidden by you'),
                    trailing: Button(
                      onPressed: () => ref
                          .read(ignoredNamesProvider.notifier)
                          .unhide(evidence.displayName!),
                      child: const Text('Unhide'),
                    ),
                  ),
                for (final evidence in officialIgnored)
                  ListTile(
                    leading: const Icon(FluentIcons.system, size: 14),
                    title: Text(evidence.displayName ?? '(unnamed)'),
                    subtitle: const Text(
                        'system component — matched a database ignore rule'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

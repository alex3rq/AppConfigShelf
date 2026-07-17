import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_db/shelf_db.dart';

import 'db_providers.dart';

final _updateStateProvider =
    StateProvider<UpdateOutcome?>((ref) => null);
final _checkingProvider = StateProvider<bool>((ref) => false);

class DatabasePage extends ConsumerWidget {
  const DatabasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(dbBundleProvider);
    final updateState = ref.watch(_updateStateProvider);
    final checking = ref.watch(_checkingProvider);
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Database'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.sync),
              label: const Text('Check for updates'),
              onPressed: checking ? null : () => _check(ref),
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: switch (bundle) {
          AsyncData(:final value) => ListView(children: [
              Text('Application database', style: theme.typography.subtitle),
              const SizedBox(height: 8),
              Text('Content version: ${value.contentVersion}'),
              Text('Schema version: ${value.schemaVersion}'),
              Text('${value.entries.length} applications'),
              const SizedBox(height: 12),
              if (checking) const ProgressBar(),
              if (updateState != null) _outcomeBar(updateState),
              const SizedBox(height: 12),
              Text(
                'Entries are community-maintained (CC-BY-SA-4.0, with Winapp2 '
                'attribution). Updates are downloaded from GitHub releases and '
                'verified against a pinned signing key before use.',
                style: theme.typography.caption,
              ),
            ]),
          AsyncError(:final error) =>
            Center(child: Text('Failed to load database: $error')),
          _ => const Center(child: ProgressRing()),
        },
      ),
    );
  }

  Widget _outcomeBar(UpdateOutcome outcome) => switch (outcome) {
        UpToDate(:final currentVersion) => InfoBar(
            title: const Text('Up to date'),
            content: Text('Version $currentVersion is current.'),
            severity: InfoBarSeverity.success,
          ),
        Updated(:final newVersion) => InfoBar(
            title: const Text('Database updated'),
            content: Text('Now using version $newVersion.'),
            severity: InfoBarSeverity.success,
          ),
        UpdateFailed(:final failure) => InfoBar(
            title: const Text('Update check failed'),
            content: Text(failure.message),
            severity: InfoBarSeverity.warning,
          ),
      };

  Future<void> _check(WidgetRef ref) async {
    ref.read(_checkingProvider.notifier).state = true;
    ref.read(_updateStateProvider.notifier).state = null;
    try {
      final current =
          (await ref.read(dbBundleProvider.future)).contentVersion;
      final outcome = await ref
          .read(dbManagerProvider)
          .checkForUpdate(currentVersion: current);
      ref.read(_updateStateProvider.notifier).state = outcome;
      if (outcome is Updated) {
        ref.invalidate(dbBundleProvider);
      }
    } finally {
      ref.read(_checkingProvider.notifier).state = false;
    }
  }
}

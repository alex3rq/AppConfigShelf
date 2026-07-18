import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_db/shelf_db.dart';

import 'db_providers.dart';
import 'entry_draft.dart';
import 'entry_editor_dialog.dart';

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
              const SizedBox(height: 20),
              const _MyLibrarySection(),
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

/// "My library": user-created entries and customized (overridden) official
/// entries, all editable. Official entries can be customized from here too.
class _MyLibrarySection extends ConsumerWidget {
  const _MyLibrarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final local = ref.watch(localEntriesProvider);
    final merged = ref.watch(mergedDbProvider).valueOrNull;
    final bundle = ref.watch(dbBundleProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My library (${local.entries.length})',
            style: theme.typography.subtitle),
        const SizedBox(height: 4),
        Text(
          'Your own entries and customized versions of official ones. These '
          'take precedence over the official database.',
          style: theme.typography.caption,
        ),
        const SizedBox(height: 8),
        for (final warning in local.warnings)
          InfoBar(
            title: const Text('Skipped invalid entry file'),
            content: Text(warning),
            severity: InfoBarSeverity.warning,
          ),
        if (local.entries.isEmpty)
          const Text(
              'Empty. Use "Find config…" on the Applications tab to add apps '
              'the database doesn\'t know, or edit any official entry below.'),
        for (final entry in local.entries)
          ListTile(
            leading: Icon(
                merged?.overriddenIds.contains(entry.id) ?? false
                    ? FluentIcons.edit
                    : FluentIcons.single_bookmark,
                size: 16),
            title: Text(entry.name),
            subtitle: Text([
              entry.id,
              if (merged?.overriddenIds.contains(entry.id) ?? false)
                'customized official entry'
              else
                'local entry',
              entry.backup.map((r) => r.path.stored).join(', '),
            ].join('  ·  ')),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(FluentIcons.edit),
                onPressed: () => _edit(context, ref, entry),
              ),
              IconButton(
                icon: const Icon(FluentIcons.copy),
                onPressed: () => _copyDraft(context, entry),
              ),
              IconButton(
                icon: Icon(
                    merged?.overriddenIds.contains(entry.id) ?? false
                        ? FluentIcons.undo
                        : FluentIcons.delete),
                onPressed: () =>
                    ref.read(localEntriesProvider.notifier).delete(entry.id),
              ),
            ]),
          ),
        const SizedBox(height: 16),
        Text('Official entries (${bundle?.entries.length ?? 0})',
            style: theme.typography.subtitle),
        const SizedBox(height: 4),
        Text('Editing an official entry saves a customized copy to My library.',
            style: theme.typography.caption),
        const SizedBox(height: 8),
        if (bundle != null)
          for (final entry in bundle.entries)
            ListTile(
              leading: const Icon(FluentIcons.app_icon_default, size: 16),
              title: Text(entry.name),
              subtitle: Text(
                  '${entry.id}  ·  ${entry.backup.map((r) => r.path.stored).join(', ')}'),
              trailing: IconButton(
                icon: const Icon(FluentIcons.edit),
                onPressed: () => _edit(context, ref, entry),
              ),
            ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, AppEntry entry) async {
    final edited = await showEntryEditorDialog(context, entry);
    if (edited == null) return;
    ref.read(localEntriesProvider.notifier).save(edited);
  }

  Future<void> _copyDraft(BuildContext context, AppEntry entry) async {
    await Clipboard.setData(ClipboardData(text: buildYamlDraft(entry)));
    if (!context.mounted) return;
    await displayInfoBar(context, builder: (context, close) {
      return InfoBar(
        title: const Text('YAML draft copied'),
        content: const Text(
            'Paste into a new file under apps/ in AppConfigShelf-DB and open '
            'a pull request.'),
        severity: InfoBarSeverity.success,
        onClose: close,
      );
    });
  }
}

import 'package:file_selector/file_selector.dart' as fs;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_backup/shelf_backup.dart';
import 'package:shelf_core/shelf_core.dart';

import 'restore_view_model.dart';

class RestorePage extends ConsumerStatefulWidget {
  const RestorePage({super.key});

  @override
  ConsumerState<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends ConsumerState<RestorePage> {
  ConflictMode _conflictMode = ConflictMode.overwrite;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restoreProvider);
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Restore'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.open_file),
              label: const Text('Open backup…'),
              onPressed: state is RestoreRunning ? null : _openPackage,
            ),
          ],
        ),
      ),
      content: switch (state) {
        RestoreIdle() => const Center(
            child:
                Text('Open an .acshelf backup package to begin restoring.')),
        RestoreLoadFailed(:final message) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(message),
              const SizedBox(height: 8),
              Button(
                  onPressed: () => ref.read(restoreProvider.notifier).reset(),
                  child: const Text('Back')),
            ]),
          ),
        RestoreSelecting() => _Selection(
            state: state,
            conflictMode: _conflictMode,
            onConflictModeChanged: (m) => setState(() => _conflictMode = m),
            onRun: () => ref
                .read(restoreProvider.notifier)
                .run(conflictMode: _conflictMode),
          ),
        RestoreRunning(:final currentEntry, :final filesDone) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const ProgressRing(),
              const SizedBox(height: 12),
              Text('$currentEntry — $filesDone files restored'),
            ]),
          ),
        RestoreComplete() => _Report(state: state),
      },
    );
  }

  Future<void> _openPackage() async {
    final file = await fs.openFile(acceptedTypeGroups: const [
      fs.XTypeGroup(label: 'AppConfigShelf backup', extensions: ['acshelf']),
    ]);
    if (file == null) return;
    await ref.read(restoreProvider.notifier).openPackage(file.path);
  }
}

class _Selection extends ConsumerWidget {
  const _Selection({
    required this.state,
    required this.conflictMode,
    required this.onConflictModeChanged,
    required this.onRun,
  });

  final RestoreSelecting state;
  final ConflictMode conflictMode;
  final ValueChanged<ConflictMode> onConflictModeChanged;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final manifest = state.package.manifest;
    final apps = [
      for (final c in state.plan.candidates)
        if (c.entry.source == EntrySource.database) c
    ];
    final customs = [
      for (final c in state.plan.candidates)
        if (c.entry.source == EntrySource.custom) c
    ];

    Widget candidateRow(RestoreCandidate c) {
      final gated = c.status == RestoreStatus.appMissing;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Checkbox(
          checked: state.selected.contains(c.entry.id),
          onChanged: gated
              ? null
              : (v) =>
                  ref.read(restoreProvider.notifier).toggle(c.entry.id, v!),
          content: Text.rich(TextSpan(children: [
            TextSpan(text: c.entry.name),
            TextSpan(
              text: [
                '  ${c.entry.files.length} files',
                if (gated) '  · app not installed',
                if (c.conflictCount > 0)
                  '  · ${c.conflictCount} existing will be replaced',
              ].join(),
              style: TextStyle(color: theme.inactiveColor),
            ),
          ])),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        Text(
            'Backup from ${manifest.machine.hostname} · '
            '${manifest.createdAt.toLocal().toString().substring(0, 16)} · '
            'app v${manifest.appVersion}',
            style: theme.typography.caption),
        const SizedBox(height: 12),
        Row(children: [
          Button(
            onPressed: () =>
                ref.read(restoreProvider.notifier).selectAllRestorable(),
            child: const Text('Select all restorable'),
          ),
          const SizedBox(width: 16),
          ComboBox<ConflictMode>(
            value: conflictMode,
            items: const [
              ComboBoxItem(
                  value: ConflictMode.overwrite,
                  child: Text('Replace existing (undo bundle kept)')),
              ComboBoxItem(
                  value: ConflictMode.skipExisting,
                  child: Text('Keep existing, restore missing only')),
            ],
            onChanged: (m) => onConflictModeChanged(m!),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: state.selected.isEmpty ? null : onRun,
            child: Text('Restore ${state.selected.length} entries'),
          ),
        ]),
        const SizedBox(height: 16),
        if (apps.isNotEmpty) ...[
          Text('Applications', style: theme.typography.subtitle),
          for (final c in apps) candidateRow(c),
          const SizedBox(height: 12),
        ],
        if (customs.isNotEmpty) ...[
          Text('Custom items', style: theme.typography.subtitle),
          for (final c in customs) candidateRow(c),
        ],
      ],
    );
  }
}

class _Report extends ConsumerWidget {
  const _Report({required this.state});

  final RestoreComplete state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final f = state.finished;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        Text(
            f.failedEntries.isEmpty
                ? 'Restore complete'
                : 'Restore finished with problems',
            style: theme.typography.subtitle),
        const SizedBox(height: 4),
        Text('${f.restoredFiles} files restored'
            '${f.skippedFiles > 0 ? ' · ${f.skippedFiles} kept as-is' : ''}'),
        if (f.undoPath != null) ...[
          const SizedBox(height: 8),
          InfoBar(
            title: const Text('Undo available'),
            content: Text(
                'Files that were replaced are saved in ${f.undoPath}. '
                'Open it like any backup to roll back.'),
            severity: InfoBarSeverity.info,
          ),
        ],
        for (final failure in state.entryFailures) ...[
          const SizedBox(height: 8),
          InfoBar(
            title: Text('${failure.entryId} halted'),
            content: Text(failure.reason),
            severity: InfoBarSeverity.warning,
          ),
        ],
        const SizedBox(height: 12),
        Button(
          onPressed: () => ref.read(restoreProvider.notifier).reset(),
          child: const Text('Restore another backup'),
        ),
      ],
    );
  }
}

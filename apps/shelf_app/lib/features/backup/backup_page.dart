import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';

import '../../shared/format.dart';
import '../../shared/widgets/footer_action_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/shelf_card.dart';
import '../../shared/widgets/wizard_steps.dart';
import '../../shell_index.dart';
import '../../theme/shelf_theme.dart';
import '../database/db_providers.dart';
import '../scan/scan_view_model.dart';
import 'add_custom_item.dart';
import 'backup_view_model.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  String _filter = '';
  String? _outputPath;

  Set<String> get _selectedApps => ref.read(backupSelectionProvider);

  void _updateSelection(void Function(Set<String>) mutate) {
    final next = {...ref.read(backupSelectionProvider)};
    mutate(next);
    ref.read(backupSelectionProvider.notifier).state = next;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(backupSelectionProvider);
    final scan = ref.watch(scanProvider).valueOrNull;
    final dbEntries = ref.watch(dbEntriesProvider).valueOrNull ?? const [];
    final customItems = ref.watch(customItemsProvider);
    final run = ref.watch(backupRunProvider);

    final detectedIds = {
      for (final d in scan?.detected ?? const <DetectedApp>[])
        if (d.entryId != null) d.entryId!,
    };
    final detectedEntries =
        [for (final e in dbEntries) if (detectedIds.contains(e.id)) e];

    final step = switch (run) {
      BackupIdle() => 0,
      BackupRunning() => 1,
      BackupDone() || BackupFailed() => 2,
    };

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShelfPageHeader(
            title: 'Back up',
            subtitle: run is BackupRunning
                ? 'Writing your backup — you can keep using this PC.'
                : 'Choose what travels with you. Nothing is written until you confirm.',
            trailing: WizardSteps(
              labels: const ['Select', 'Back up', 'Done'],
              current: step,
            ),
          ),
          Expanded(
            child: switch (run) {
              BackupRunning() =>
                _Progress(run: run, outputPath: _outputPath),
              BackupDone() => _Report(run: run, onBack: () {
                  ref.read(backupRunProvider.notifier).reset();
                }),
              BackupFailed(:final error) => _Failed(
                  error: error,
                  onBack: () =>
                      ref.read(backupRunProvider.notifier).reset()),
              BackupIdle() => _buildSelection(detectedEntries, customItems),
            },
          ),
          if (run is BackupIdle)
            _SelectionFooter(
              selectedApps: [
                for (final e in detectedEntries)
                  if (_selectedApps.contains(e.id)) e
              ],
              customItems: customItems,
              onStart: () => _startBackup(detectedEntries, customItems),
            ),
        ],
      ),
    );
  }

  Widget _buildSelection(
      List<AppEntry> detectedEntries, List<CustomItem> customItems) {
    final p = ShelfTokens.of(context);
    final filtered = [
      for (final e in detectedEntries)
        if (_filter.isEmpty ||
            e.name.toLowerCase().contains(_filter.toLowerCase()))
          e
    ];
    final allSelected = detectedEntries.isNotEmpty &&
        detectedEntries.every((e) => _selectedApps.contains(e.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          ShelfSpacing.xl, 0, ShelfSpacing.xl, ShelfSpacing.xl),
      children: [
        Row(
          children: [
            Checkbox(
              checked: allSelected,
              onChanged: detectedEntries.isEmpty
                  ? null
                  : (v) => _updateSelection((s) {
                        if (v ?? false) {
                          s.addAll([for (final e in detectedEntries) e.id]);
                        } else {
                          s.clear();
                        }
                      }),
              content: Text(
                'Detected applications — ${_selectedApps.length} of '
                '${detectedEntries.length} selected',
                style: ShelfType.bodyStrong.copyWith(color: p.textPrimary),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 200,
              child: TextBox(
                placeholder: 'Filter apps',
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: ShelfSpacing.sm),
        if (detectedEntries.isEmpty)
          ShelfCard(
            child: Text('Run a scan first (Applications tab).',
                style: ShelfType.body.copyWith(color: p.textSecondary)),
          )
        else
          ShelfCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, entry) in filtered.indexed)
                  _SelectRow(
                    first: i == 0,
                    checked: _selectedApps.contains(entry.id),
                    onChanged: (v) => _updateSelection(
                        (s) => v ? s.add(entry.id) : s.remove(entry.id)),
                    name: entry.name,
                    detail: entry.id,
                    trailing: RiskChip(risk: entry.risk),
                  ),
              ],
            ),
          ),
        const SizedBox(height: ShelfSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text('Custom items — restored to their original paths',
                  style: ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
            ),
            Button(
              onPressed: () => addCustomItemFlow(context, ref),
              child: const Text('Add folder…'),
            ),
          ],
        ),
        const SizedBox(height: ShelfSpacing.sm),
        if (customItems.isEmpty)
          ShelfCard(
            child: Text(
                'Add any folder or file to back up, even if no app is '
                'detected. Custom items are always restored to their '
                'original location.',
                style: ShelfType.caption.copyWith(color: p.textSecondary)),
          )
        else
          ShelfCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, item) in customItems.indexed)
                  _SelectRow(
                    first: i == 0,
                    checked: true,
                    name: item.name,
                    detail:
                        item.backup.map((r) => r.path.stored).join(', '),
                    trailing: HyperlinkButton(
                      onPressed: () => ref
                          .read(customItemsProvider.notifier)
                          .remove(item.slug),
                      child: const Text('Remove'),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _startBackup(
      List<AppEntry> detectedEntries, List<CustomItem> customItems) async {
    final location = await fs.getSaveLocation(
      suggestedName:
          'backup-${DateTime.now().toIso8601String().substring(0, 10)}.acshelf',
      acceptedTypeGroups: const [
        fs.XTypeGroup(label: 'AppConfigShelf backup', extensions: ['acshelf']),
      ],
    );
    if (location == null) return;
    setState(() => _outputPath = location.path);

    final apps =
        [for (final e in detectedEntries) if (_selectedApps.contains(e.id)) e];
    await ref.read(backupRunProvider.notifier).run(
          apps: apps,
          customItems: customItems,
          outputPath: location.path,
        );
  }
}

/// Checkbox row inside a ShelfCard list.
class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.name,
    required this.detail,
    required this.checked,
    this.onChanged,
    this.trailing,
    this.first = false,
  });

  final String name;
  final String detail;
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final Widget? trailing;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ShelfSpacing.lg, vertical: ShelfSpacing.md),
      decoration: first
          ? null
          : BoxDecoration(border: Border(top: BorderSide(color: p.stroke))),
      child: Row(
        children: [
          Checkbox(
            checked: checked,
            onChanged:
                onChanged == null ? null : (v) => onChanged!(v ?? false),
          ),
          const SizedBox(width: ShelfSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style:
                        ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(detail,
                      style:
                          ShelfType.mono.copyWith(color: p.textSecondary)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _SelectionFooter extends StatelessWidget {
  const _SelectionFooter({
    required this.selectedApps,
    required this.customItems,
    required this.onStart,
  });

  final List<AppEntry> selectedApps;
  final List<CustomItem> customItems;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    final cautionCount = selectedApps
        .where((e) => e.risk != RiskTier.safe)
        .length;
    return FooterActionBar(
      summary: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${selectedApps.length} apps · ${customItems.length} custom items',
            style: ShelfType.bodyStrong.copyWith(color: p.textPrimary),
          ),
          if (cautionCount > 0)
            Text(
              '$cautionCount caution/expert ${cautionCount == 1 ? 'item' : 'items'} selected — review before restoring on another PC',
              style: ShelfType.caption.copyWith(color: p.caution),
            ),
        ],
      ),
      note: const Text(
          'Writes one .acshelf file · nothing on this PC is changed'),
      action: FilledButton(
        onPressed: selectedApps.isEmpty && customItems.isEmpty
            ? null
            : onStart,
        child: const Text('Back up selection'),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.run, required this.outputPath});

  final BackupRunning run;
  final String? outputPath;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Center(
      child: ShelfCard(
        padding: const EdgeInsets.all(ShelfSpacing.xl),
        child: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProgressRing(),
              const SizedBox(height: ShelfSpacing.lg),
              Text('Backing up ${run.currentEntry}…',
                  style: ShelfType.subtitle.copyWith(color: p.textPrimary)),
              const SizedBox(height: ShelfSpacing.sm),
              Text('${run.filesDone} of ${run.filesTotal} files',
                  style: ShelfType.caption.copyWith(color: p.textSecondary)),
              const SizedBox(height: ShelfSpacing.md),
              ProgressBar(
                  value: run.filesTotal == 0
                      ? null
                      : run.filesDone * 100 / run.filesTotal),
              if (outputPath != null) ...[
                const SizedBox(height: ShelfSpacing.md),
                Text('→ $outputPath',
                    style: ShelfType.mono.copyWith(color: p.textSecondary)),
              ],
              const SizedBox(height: ShelfSpacing.sm),
              Text(
                  'Files locked by running apps are skipped safely and '
                  'listed in the report.',
                  style: ShelfType.caption.copyWith(color: p.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.error, required this.onBack});

  final Object error;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Backup failed: $error',
              style: ShelfType.body.copyWith(color: p.danger)),
          const SizedBox(height: ShelfSpacing.sm),
          Button(onPressed: onBack, child: const Text('Back')),
        ],
      ),
    );
  }
}

class _Report extends ConsumerWidget {
  const _Report({required this.run, required this.onBack});

  final BackupDone run;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ShelfTokens.of(context);
    final entries = run.manifest.entries;
    final totalFiles = entries.fold(0, (sum, e) => sum + e.files.length);
    final totalBytes = entries.fold(
        0, (sum, e) => sum + e.files.fold(0, (s, f) => s + f.size));
    final skipped = [
      for (final e in entries)
        for (final s in e.skipped) s
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          ShelfSpacing.xl, 0, ShelfSpacing.xl, ShelfSpacing.xl),
      children: [
        const SizedBox(height: ShelfSpacing.lg),
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: p.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(FluentIcons.check_mark, size: 24, color: p.success),
          ),
        ),
        const SizedBox(height: ShelfSpacing.md),
        Center(
          child: Text('Backup complete',
              style: ShelfType.title.copyWith(color: p.textPrimary)),
        ),
        const SizedBox(height: ShelfSpacing.xs),
        Center(
          child: Text(
              '${entries.length} entries · $totalFiles files · '
              '${formatBytes(totalBytes)}',
              style: ShelfType.caption.copyWith(color: p.textSecondary)),
        ),
        const SizedBox(height: ShelfSpacing.lg),
        ShelfCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(ShelfSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saved to',
                              style: ShelfType.caption
                                  .copyWith(color: p.textSecondary)),
                          const SizedBox(height: 2),
                          Text(run.outputPath,
                              style: ShelfType.mono
                                  .copyWith(color: p.textPrimary)),
                        ],
                      ),
                    ),
                    Button(
                      onPressed: () => _openFolder(run.outputPath),
                      child: const Text('Open folder'),
                    ),
                  ],
                ),
              ),
              for (final entry in entries)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ShelfSpacing.lg,
                      vertical: ShelfSpacing.md),
                  decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: p.stroke))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                            entry.source == EntrySource.custom
                                ? '${entry.name} (custom)'
                                : entry.name,
                            style: ShelfType.bodyStrong
                                .copyWith(color: p.textPrimary)),
                      ),
                      Text(
                          '${entry.files.length} files · '
                          '${formatBytes(entry.files.fold(0, (s, f) => s + f.size))}',
                          style: ShelfType.caption
                              .copyWith(color: p.textSecondary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (skipped.isNotEmpty) ...[
          const SizedBox(height: ShelfSpacing.lg),
          ShelfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${skipped.length} ${skipped.length == 1 ? 'file' : 'files'} skipped',
                    style: ShelfType.bodyStrong.copyWith(color: p.caution)),
                const SizedBox(height: ShelfSpacing.sm),
                for (final skip in skipped)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('${skip.targetPath} — ${skip.reason}',
                        style: ShelfType.mono.copyWith(color: p.caution)),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: ShelfSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(onPressed: onBack, child: const Text('New backup')),
            const SizedBox(width: ShelfSpacing.sm),
            Button(
              onPressed: () {
                onBack();
                ref.read(shellIndexProvider.notifier).state = ShellTab.home;
              },
              child: const Text('Go home'),
            ),
          ],
        ),
      ],
    );
  }

  void _openFolder(String path) {
    Process.run('explorer.exe', ['/select,', path]);
  }
}

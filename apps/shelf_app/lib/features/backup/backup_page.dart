import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';

import '../../l10n/gen/app_localizations.dart';
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
            title: S.of(context).backupTitle,
            subtitle: run is BackupRunning
                ? S.of(context).backupSubtitleRunning
                : S.of(context).backupSubtitle,
            trailing: WizardSteps(
              labels: [
                S.of(context).stepSelect,
                S.of(context).stepBackUp,
                S.of(context).stepDone,
              ],
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
    final scan = ref.watch(scanProvider);
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
                S.of(context).detectedAppsSelected(
                    _selectedApps.length, detectedEntries.length),
                style: ShelfType.bodyStrong.copyWith(color: p.textPrimary),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 200,
              child: TextBox(
                placeholder: S.of(context).filterApps,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: ShelfSpacing.sm),
        if (detectedEntries.isEmpty)
          ShelfCard(
            padding: const EdgeInsets.all(ShelfSpacing.xl),
            child: scan.isLoading
                ? Column(
                    children: [
                      const ProgressRing(),
                      const SizedBox(height: ShelfSpacing.md),
                      Text(S.of(context).homeScanning),
                    ],
                  )
                : Column(
                    children: [
                      Icon(FluentIcons.search, size: 24, color: p.textSecondary),
                      const SizedBox(height: ShelfSpacing.md),
                      Text(S.of(context).backupScanCtaTitle,
                          style: ShelfType.subtitle
                              .copyWith(color: p.textPrimary)),
                      const SizedBox(height: ShelfSpacing.xs),
                      Text(S.of(context).backupScanCtaBody,
                          style: ShelfType.caption
                              .copyWith(color: p.textSecondary)),
                      const SizedBox(height: ShelfSpacing.md),
                      FilledButton(
                        onPressed: () {
                          ref.read(scanProvider.notifier).scan();
                          ref.read(shellIndexProvider.notifier).state =
                              ShellTab.applications;
                        },
                        child: Text(S.of(context).scanApplications),
                      ),
                    ],
                  ),
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
              child: Text(S.of(context).customItemsSection,
                  style: ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
            ),
            Button(
              onPressed: () => addCustomItemFlow(context, ref),
              child: Text(S.of(context).addFolderAction),
            ),
          ],
        ),
        const SizedBox(height: ShelfSpacing.sm),
        if (customItems.isEmpty)
          ShelfCard(
            child: Text(S.of(context).customItemsEmpty,
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
                      child: Text(S.of(context).remove),
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
            S.of(context).footerSummary(
                selectedApps.length, customItems.length),
            style: ShelfType.bodyStrong.copyWith(color: p.textPrimary),
          ),
          if (cautionCount > 0)
            Text(
              S.of(context).cautionSelected(cautionCount),
              style: ShelfType.caption.copyWith(color: p.caution),
            ),
        ],
      ),
      note: Text(S.of(context).footerNote),
      action: FilledButton(
        onPressed: selectedApps.isEmpty && customItems.isEmpty
            ? null
            : onStart,
        child: Text(S.of(context).backUpSelection),
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
              Text(S.of(context).backingUpEntry(run.currentEntry),
                  style: ShelfType.subtitle.copyWith(color: p.textPrimary)),
              const SizedBox(height: ShelfSpacing.sm),
              Text(
                  S.of(context).filesProgress(run.filesDone, run.filesTotal),
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
              Text(S.of(context).lockedFilesNote,
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
          Text(S.of(context).backupFailed('$error'),
              style: ShelfType.body.copyWith(color: p.danger)),
          const SizedBox(height: ShelfSpacing.sm),
          Button(onPressed: onBack, child: Text(S.of(context).back)),
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
          child: Text(S.of(context).backupComplete,
              style: ShelfType.title.copyWith(color: p.textPrimary)),
        ),
        const SizedBox(height: ShelfSpacing.xs),
        Center(
          child: Text(
              S.of(context).reportTotals(
                  entries.length, totalFiles, formatBytes(totalBytes)),
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
                          Text(S.of(context).savedTo,
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
                      child: Text(S.of(context).openFolder),
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
                                ? S.of(context).customSuffix(entry.name)
                                : entry.name,
                            style: ShelfType.bodyStrong
                                .copyWith(color: p.textPrimary)),
                      ),
                      Text(
                          S.of(context).filesAndSize(
                              entry.files.length,
                              formatBytes(entry.files
                                  .fold(0, (s, f) => s + f.size))),
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
                Text(S.of(context).skippedFiles(skipped.length),
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
            FilledButton(
                onPressed: onBack, child: Text(S.of(context).newBackup)),
            const SizedBox(width: ShelfSpacing.sm),
            Button(
              onPressed: () {
                onBack();
                ref.read(shellIndexProvider.notifier).state = ShellTab.home;
              },
              child: Text(S.of(context).goHome),
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

import 'package:file_selector/file_selector.dart' as fs;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';

import '../../shared/widgets/footer_action_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/shelf_card.dart';
import '../../shared/widgets/wizard_steps.dart';
import '../../theme/shelf_theme.dart';
import '../database/db_providers.dart';
import '../scan/scan_view_model.dart';
import 'backup_view_model.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  final _selectedApps = <String>{};
  String _filter = '';

  @override
  Widget build(BuildContext context) {
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
            subtitle:
                'Choose what travels with you. Nothing is written until you confirm.',
            trailing: WizardSteps(
              labels: const ['Select', 'Back up', 'Done'],
              current: step,
            ),
          ),
          Expanded(
            child: switch (run) {
              BackupRunning() => _Progress(run: run),
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
                  : (v) => setState(() {
                        if (v ?? false) {
                          _selectedApps
                              .addAll([for (final e in detectedEntries) e.id]);
                        } else {
                          _selectedApps.clear();
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
                    onChanged: (v) => setState(() {
                      v
                          ? _selectedApps.add(entry.id)
                          : _selectedApps.remove(entry.id);
                    }),
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
              onPressed: _addCustomItem,
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

  Future<void> _addCustomItem() async {
    final dir = await fs.getDirectoryPath();
    if (dir == null || !mounted) return;

    final parsed = StoragePath.parse(dir, allowAbsolute: true);
    final path = parsed.valueOrNull;
    if (path == null) {
      await displayInfoBar(context, builder: (context, close) {
        return InfoBar(
          title: const Text('Unsupported path'),
          content: Text(parsed.failureOrNull!.message),
          severity: InfoBarSeverity.error,
          onClose: close,
        );
      });
      return;
    }

    final defaultName = dir.split(RegExp(r'[\\/]')).last;
    final name = await _promptName(defaultName);
    if (name == null || name.isEmpty) return;

    final slug = _slugify(name);
    ref.read(customItemsProvider.notifier).add(CustomItem(
          slug: slug,
          name: name,
          backup: [BackupRule(path: path)],
        ));
  }

  Future<String?> _promptName(String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Name this item'),
        content: TextBox(controller: controller, autofocus: true),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _slugify(String name) {
    final existing = {for (final i in ref.read(customItemsProvider)) i.slug};
    var base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (base.isEmpty) base = 'item';
    var slug = base;
    var n = 2;
    while (existing.contains(slug)) {
      slug = '$base-${n++}';
    }
    return slug;
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
  const _Progress({required this.run});

  final BackupRunning run;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Center(
      child: ShelfCard(
        padding: const EdgeInsets.all(ShelfSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backing up…',
                style: ShelfType.subtitle.copyWith(color: p.textPrimary)),
            const SizedBox(height: ShelfSpacing.lg),
            SizedBox(
              width: 360,
              child: ProgressBar(
                  value: run.filesTotal == 0
                      ? null
                      : run.filesDone * 100 / run.filesTotal),
            ),
            const SizedBox(height: ShelfSpacing.md),
            Text(
                '${run.currentEntry} — ${run.filesDone}/${run.filesTotal} files',
                style: ShelfType.caption.copyWith(color: p.textSecondary)),
          ],
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

class _Report extends StatelessWidget {
  const _Report({required this.run, required this.onBack});

  final BackupDone run;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    final entries = run.manifest.entries;
    final totalFiles = entries.fold(0, (sum, e) => sum + e.files.length);
    final totalSkipped = entries.fold(0, (sum, e) => sum + e.skipped.length);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          ShelfSpacing.xl, 0, ShelfSpacing.xl, ShelfSpacing.xl),
      children: [
        ShelfCard(
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Backup complete',
                  style: ShelfType.subtitle.copyWith(color: p.textPrimary)),
              const SizedBox(height: ShelfSpacing.xs),
              Text(run.outputPath,
                  style: ShelfType.mono.copyWith(color: p.textSecondary)),
              const SizedBox(height: ShelfSpacing.xs),
              Text(
                  '$totalFiles files across ${entries.length} entries'
                  '${totalSkipped > 0 ? ' · $totalSkipped skipped' : ''}',
                  style: ShelfType.caption.copyWith(color: p.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: ShelfSpacing.lg),
        ShelfCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, entry) in entries.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ShelfSpacing.lg,
                      vertical: ShelfSpacing.md),
                  decoration: i == 0
                      ? null
                      : BoxDecoration(
                          border:
                              Border(top: BorderSide(color: p.stroke))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(entry.name,
                                style: ShelfType.bodyStrong
                                    .copyWith(color: p.textPrimary)),
                          ),
                          Text(
                              '${entry.files.length} files'
                              '${entry.skipped.isNotEmpty ? ' · ${entry.skipped.length} skipped' : ''}',
                              style: ShelfType.caption
                                  .copyWith(color: p.textSecondary)),
                        ],
                      ),
                      for (final skip in entry.skipped)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                              '⚠ ${skip.targetPath} (${skip.reason})',
                              style: ShelfType.mono
                                  .copyWith(color: p.caution)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ShelfSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: Button(onPressed: onBack, child: const Text('New backup')),
        ),
      ],
    );
  }
}

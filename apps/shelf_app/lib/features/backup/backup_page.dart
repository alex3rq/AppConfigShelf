import 'package:file_selector/file_selector.dart' as fs;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';

import '../scan/scan_view_model.dart';
import 'backup_view_model.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  final _selectedApps = <String>{};

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

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Create backup'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.save),
              label: const Text('Back up selection'),
              onPressed: run is BackupRunning ||
                      (_selectedApps.isEmpty && customItems.isEmpty)
                  ? null
                  : () => _startBackup(detectedEntries, customItems),
            ),
          ],
        ),
      ),
      content: switch (run) {
        BackupRunning() => _Progress(run: run),
        BackupDone() => _Report(run: run, onBack: () {
            ref.read(backupRunProvider.notifier).reset();
          }),
        BackupFailed(:final error) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Backup failed: $error'),
                const SizedBox(height: 8),
                Button(
                  onPressed: () =>
                      ref.read(backupRunProvider.notifier).reset(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        BackupIdle() => _buildSelection(detectedEntries, customItems),
      },
    );
  }

  Widget _buildSelection(
      List<AppEntry> detectedEntries, List<CustomItem> customItems) {
    final theme = FluentTheme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        Text('Detected applications', style: theme.typography.subtitle),
        const SizedBox(height: 4),
        if (detectedEntries.isEmpty)
          const Text('Run a scan first (Applications tab).'),
        for (final entry in detectedEntries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Checkbox(
              checked: _selectedApps.contains(entry.id),
              onChanged: (v) => setState(() {
                v! ? _selectedApps.add(entry.id) : _selectedApps.remove(entry.id);
              }),
              content: Text(entry.name),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Custom items', style: theme.typography.subtitle),
            const SizedBox(width: 12),
            Button(
              onPressed: _addCustomItem,
              child: const Text('Add folder…'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (customItems.isEmpty)
          const Text(
              'Add any folder or file to back up, even if no app is detected. '
              'Custom items are always restored to their original location.'),
        for (final item in customItems)
          ListTile(
            leading: const Icon(FluentIcons.folder),
            title: Text(item.name),
            subtitle: Text(item.backup.map((r) => r.path.stored).join(', ')),
            trailing: IconButton(
              icon: const Icon(FluentIcons.delete),
              onPressed: () =>
                  ref.read(customItemsProvider.notifier).remove(item.slug),
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

class _Progress extends StatelessWidget {
  const _Progress({required this.run});

  final BackupRunning run;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressBar(
              value: run.filesTotal == 0
                  ? null
                  : run.filesDone * 100 / run.filesTotal),
          const SizedBox(height: 12),
          Text('${run.currentEntry} — ${run.filesDone}/${run.filesTotal} files'),
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
    final theme = FluentTheme.of(context);
    final entries = run.manifest.entries;
    final totalFiles =
        entries.fold(0, (sum, e) => sum + e.files.length);
    final totalSkipped =
        entries.fold(0, (sum, e) => sum + e.skipped.length);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        Text('Backup complete', style: theme.typography.subtitle),
        const SizedBox(height: 4),
        Text('Saved to ${run.outputPath}'),
        Text('$totalFiles files across ${entries.length} entries'
            '${totalSkipped > 0 ? ' · $totalSkipped skipped' : ''}'),
        const SizedBox(height: 12),
        for (final entry in entries) ...[
          Text(entry.name, style: theme.typography.bodyStrong),
          Text('  ${entry.files.length} files'
              '${entry.skipped.isNotEmpty ? ' · ${entry.skipped.length} skipped' : ''}'),
          for (final skip in entry.skipped)
            Text('  ⚠ ${skip.targetPath} (${skip.reason})'),
          const SizedBox(height: 8),
        ],
        Button(onPressed: onBack, child: const Text('New backup')),
      ],
    );
  }
}

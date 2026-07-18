import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_db/shelf_db.dart';

import '../../shared/widgets/origin_chip.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/shelf_card.dart';
import '../../theme/shelf_theme.dart';
import 'db_providers.dart';
import 'entry_draft.dart';
import 'entry_editor_dialog.dart';

final _updateStateProvider = StateProvider<UpdateOutcome?>((ref) => null);
final _checkingProvider = StateProvider<bool>((ref) => false);
final _searchProvider = StateProvider<String>((ref) => '');
final _selectedIdProvider = StateProvider<String?>((ref) => null);

enum _Filter { all, mine, official }

final _filterProvider = StateProvider<_Filter>((ref) => _Filter.all);

class DatabasePage extends ConsumerWidget {
  const DatabasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(dbBundleProvider);
    final updateState = ref.watch(_updateStateProvider);
    final checking = ref.watch(_checkingProvider);

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShelfPageHeader(
            title: 'Library',
            subtitle:
                'The official app database, plus your own entries. Yours '
                'always win when they overlap.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bundle.valueOrNull case final b?)
                  Padding(
                    padding:
                        const EdgeInsets.only(right: ShelfSpacing.md),
                    child: _VersionBadge(bundle: b),
                  ),
                Button(
                  onPressed: checking ? null : () => _check(ref),
                  child: const Text('Check for updates'),
                ),
              ],
            ),
          ),
          if (checking)
            const Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: ShelfSpacing.xl),
              child: ProgressBar(),
            ),
          if (updateState != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  ShelfSpacing.xl, 0, ShelfSpacing.xl, ShelfSpacing.sm),
              child: _outcomeBar(updateState),
            ),
          Expanded(
            child: switch (bundle) {
              AsyncData() => const _MasterDetail(),
              AsyncError(:final error) =>
                Center(child: Text('Failed to load database: $error')),
              _ => const Center(child: ProgressRing()),
            },
          ),
        ],
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

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.bundle});

  final DbBundle bundle;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: p.success, shape: BoxShape.circle),
        ),
        const SizedBox(width: ShelfSpacing.sm),
        Text('v${bundle.contentVersion} · signed',
            style: ShelfType.caption.copyWith(color: p.textSecondary)),
      ],
    );
  }
}

class _MasterDetail extends ConsumerWidget {
  const _MasterDetail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ShelfTokens.of(context);
    final local = ref.watch(localEntriesProvider);
    final merged = ref.watch(mergedDbProvider).valueOrNull;
    final bundle = ref.watch(dbBundleProvider).valueOrNull;
    final search = ref.watch(_searchProvider);
    final filter = ref.watch(_filterProvider);

    final all = merged?.entries ?? const <AppEntry>[];
    final localIds = {for (final e in local.entries) e.id};
    final entries = [
      for (final e in all)
        if (switch (filter) {
          _Filter.all => true,
          _Filter.mine => localIds.contains(e.id),
          _Filter.official => !(merged?.freshLocalIds.contains(e.id) ?? false),
        })
          if (search.isEmpty ||
              e.name.toLowerCase().contains(search.toLowerCase()) ||
              e.id.contains(search.toLowerCase()))
            e
    ];

    final selectedId = ref.watch(_selectedIdProvider) ??
        (entries.isEmpty ? null : entries.first.id);
    final selected =
        entries.where((e) => e.id == selectedId).firstOrNull ??
            entries.firstOrNull;

    ChipOrigin originOf(AppEntry e) {
      if (merged?.freshLocalIds.contains(e.id) ?? false) {
        return ChipOrigin.local;
      }
      if (merged?.overriddenIds.contains(e.id) ?? false) {
        return ChipOrigin.customized;
      }
      return ChipOrigin.official;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          ShelfSpacing.xl, 0, ShelfSpacing.xl, ShelfSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextBox(
                  placeholder: 'Search ${all.length} entries',
                  onChanged: (v) =>
                      ref.read(_searchProvider.notifier).state = v,
                ),
                const SizedBox(height: ShelfSpacing.sm),
                Wrap(
                  spacing: ShelfSpacing.xs,
                  children: [
                    for (final (f, label) in [
                      (_Filter.all, 'All ${all.length}'),
                      (_Filter.mine, 'My library ${local.entries.length}'),
                      (
                        _Filter.official,
                        'Official ${bundle?.entries.length ?? 0}'
                      ),
                    ])
                      ToggleButton(
                        checked: filter == f,
                        onChanged: (_) =>
                            ref.read(_filterProvider.notifier).state = f,
                        child: Text(label, style: ShelfType.caption),
                      ),
                  ],
                ),
                const SizedBox(height: ShelfSpacing.sm),
                for (final warning in local.warnings)
                  InfoBar(
                    title: const Text('Skipped invalid entry file'),
                    content: Text(warning),
                    severity: InfoBarSeverity.warning,
                  ),
                Expanded(
                  child: ShelfCard(
                    padding: EdgeInsets.zero,
                    child: ListView(
                      children: [
                        for (final e in entries)
                          _EntryListRow(
                            entry: e,
                            origin: originOf(e),
                            selected: e.id == selected?.id,
                            onPressed: () => ref
                                .read(_selectedIdProvider.notifier)
                                .state = e.id,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ShelfSpacing.lg),
          Expanded(
            child: selected == null
                ? Center(
                    child: Text('No entries match.',
                        style: ShelfType.body
                            .copyWith(color: p.textSecondary)))
                : _EntryDetail(
                    entry: selected, origin: originOf(selected)),
          ),
        ],
      ),
    );
  }
}

class _EntryListRow extends StatelessWidget {
  const _EntryListRow({
    required this.entry,
    required this.origin,
    required this.selected,
    required this.onPressed,
  });

  final AppEntry entry;
  final ChipOrigin origin;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return HoverButton(
      onPressed: onPressed,
      builder: (context, states) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: ShelfSpacing.lg, vertical: ShelfSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? p.accent.withValues(alpha: 0.08)
              : states.isHovered
                  ? p.card
                  : null,
          border: Border(
            left: BorderSide(
              color: selected ? p.accent : const Color(0x00000000),
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name,
                      style: ShelfType.bodyStrong
                          .copyWith(color: p.textPrimary)),
                  const SizedBox(height: 2),
                  Text(entry.id,
                      style:
                          ShelfType.mono.copyWith(color: p.textSecondary)),
                ],
              ),
            ),
            if (origin != ChipOrigin.official) OriginChip(origin: origin),
          ],
        ),
      ),
    );
  }
}

class _EntryDetail extends ConsumerWidget {
  const _EntryDetail({required this.entry, required this.origin});

  final AppEntry entry;
  final ChipOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ShelfTokens.of(context);
    final isMine = origin != ChipOrigin.official;

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.name,
                          style: ShelfType.title
                              .copyWith(color: p.textPrimary)),
                      const SizedBox(width: ShelfSpacing.md),
                      if (origin != ChipOrigin.official)
                        OriginChip(origin: origin),
                      const SizedBox(width: ShelfSpacing.sm),
                      RiskChip(risk: entry.risk),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(entry.id,
                      style:
                          ShelfType.mono.copyWith(color: p.textSecondary)),
                ],
              ),
            ),
            Button(
              onPressed: () => _copyDraft(context, entry),
              child: const Text('Copy YAML draft'),
            ),
            const SizedBox(width: ShelfSpacing.sm),
            if (isMine)
              Button(
                onPressed: () =>
                    ref.read(localEntriesProvider.notifier).delete(entry.id),
                child: Text(origin == ChipOrigin.customized
                    ? 'Reset to official'
                    : 'Delete entry'),
              ),
            const SizedBox(width: ShelfSpacing.sm),
            FilledButton(
              onPressed: () => _edit(context, ref, entry),
              child: const Text('Edit entry'),
            ),
          ],
        ),
        const SizedBox(height: ShelfSpacing.md),
        if (origin == ChipOrigin.customized)
          InfoBar(
            title: const Text('Your customized copy.'),
            content: const Text(
                'Scanning and backups use this instead of the official '
                'entry.'),
            severity: InfoBarSeverity.info,
          )
        else if (origin == ChipOrigin.local)
          InfoBar(
            title: const Text('Local entry.'),
            content: const Text(
                'Created on this PC — copy a YAML draft to contribute it to '
                'the official database.'),
            severity: InfoBarSeverity.info,
          ),
        const SizedBox(height: ShelfSpacing.lg),
        Text('Detection',
            style: ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
        const SizedBox(height: ShelfSpacing.sm),
        ShelfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final rule in entry.detect)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(_describeDetection(rule),
                      style:
                          ShelfType.mono.copyWith(color: p.textPrimary)),
                ),
              Text('Entry is active only when detection matches',
                  style:
                      ShelfType.caption.copyWith(color: p.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: ShelfSpacing.lg),
        Text('Backup locations (${entry.backup.length})',
            style: ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
        const SizedBox(height: ShelfSpacing.sm),
        for (final rule in entry.backup) ...[
          ShelfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(rule.path.stored,
                          style: ShelfType.mono
                              .copyWith(color: p.textPrimary)),
                    ),
                    if (rule.optional)
                      const ShelfChip(label: 'optional'),
                    if (rule.sizeWarning)
                      ShelfChip(label: 'large', color: p.caution),
                  ],
                ),
                if (rule.include.isNotEmpty) ...[
                  const SizedBox(height: ShelfSpacing.xs),
                  _RuleLine(
                      label: 'Include',
                      color: p.success,
                      globs: rule.include),
                ],
                if (rule.exclude.isNotEmpty) ...[
                  const SizedBox(height: ShelfSpacing.xs),
                  _RuleLine(
                      label: 'Exclude',
                      color: p.danger,
                      globs: rule.exclude),
                ],
              ],
            ),
          ),
          const SizedBox(height: ShelfSpacing.sm),
        ],
      ],
    );
  }

  String _describeDetection(DetectionRule rule) => switch (rule) {
        RegistryDetection(:final keyPath) => 'Registry: $keyPath',
        PathDetection(:final path) => path.stored,
        MsixDetection(:final packageFamilyName) =>
          'MSIX package: $packageFamilyName',
      };

  Future<void> _edit(
      BuildContext context, WidgetRef ref, AppEntry entry) async {
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

class _RuleLine extends StatelessWidget {
  const _RuleLine({
    required this.label,
    required this.color,
    required this.globs,
  });

  final String label;
  final Color color;
  final List<String> globs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: ShelfType.caption.copyWith(color: color)),
        ),
        Expanded(
          child: Text(globs.join(' · '),
              style: ShelfType.mono.copyWith(color: color)),
        ),
      ],
    );
  }
}

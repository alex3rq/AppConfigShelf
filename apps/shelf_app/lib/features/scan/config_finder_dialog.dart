import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_detect/shelf_detect.dart';
import 'package:shelf_win32/shelf_win32.dart';

import '../../shared/widgets/risk_chip.dart';
import '../../theme/shelf_theme.dart';
import '../backup/add_custom_item.dart';
import '../database/db_providers.dart';
import '../database/entry_editor_dialog.dart';

enum _FinderOutcome { savedToLibrary, addedCustomItem }

/// Shows heuristic config-folder candidates for an app the database doesn't
/// know. Primary flow: save the app to "My library" as a real database
/// entry (detection-gated, appears as Recognized on the next scan).
/// Secondary: copy a YAML draft for contributing to the community db.
Future<void> showConfigFinderDialog(
    BuildContext context, WidgetRef ref, InstallEvidence evidence) async {
  final candidates = locateConfigCandidates(
    evidence: evidence,
    fileSystem: const RealFileSystem(),
    knownFolders: WindowsKnownFolderResolver(),
  );
  if (!context.mounted) return;

  final outcome = await showDialog<_FinderOutcome>(
    context: context,
    builder: (context) =>
        _ConfigFinderDialog(evidence: evidence, candidates: candidates),
  );
  if (outcome == null || !context.mounted) return;

  final name = evidence.displayName ?? 'Unknown app';
  await displayInfoBar(context, builder: (context, close) {
    return switch (outcome) {
      _FinderOutcome.savedToLibrary => InfoBar(
          title: Text('"$name" saved to My library'),
          content: const Text(
              'It will appear under Recognized on the next scan, and can be '
              'edited any time from the Database tab.'),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      _FinderOutcome.addedCustomItem => const InfoBar(
          title: Text('Custom item added'),
          content: Text(
              'The folder is listed under Custom items on the Backup tab '
              'and will be included in every backup.'),
          severity: InfoBarSeverity.success,
        ),
    };
  });
}

class _ConfigFinderDialog extends ConsumerStatefulWidget {
  const _ConfigFinderDialog({required this.evidence, required this.candidates});

  final InstallEvidence evidence;
  final List<ConfigCandidate> candidates;

  @override
  ConsumerState<_ConfigFinderDialog> createState() => _ConfigFinderDialogState();
}

class _ConfigFinderDialogState extends ConsumerState<_ConfigFinderDialog> {
  // A 100% match is pre-approved: pre-checked, save enabled immediately.
  late final Set<String> _selected = {
    if (widget.candidates.isNotEmpty && widget.candidates.first.score >= 1.0)
      widget.candidates.first.path.stored,
  };

  String get _appName => widget.evidence.displayName ?? 'Unknown app';

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 560),
      title: Text('Find configuration — $_appName'),
      content: widget.candidates.isEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'No likely config folders found under AppData, '
                    'LocalAppData, or Documents. The app may store settings '
                    'in the registry or its install folder — you can still '
                    'pick any folder yourself and back it up as a custom '
                    'item.'),
                const SizedBox(height: ShelfSpacing.md),
                Button(
                  onPressed: _addCustomItem,
                  child: const Text('Add folder as custom item…'),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'AppConfigShelf looked in the usual places. Check the '
                    'folders that hold this app\'s settings.',
                    style:
                        ShelfType.caption.copyWith(color: p.textSecondary)),
                const SizedBox(height: ShelfSpacing.md),
                for (final candidate in widget.candidates.take(8))
                  _CandidateRow(
                    candidate: candidate,
                    checked: _selected.contains(candidate.path.stored),
                    onChanged: (v) => setState(() {
                      v
                          ? _selected.add(candidate.path.stored)
                          : _selected.remove(candidate.path.stored);
                    }),
                  ),
                const SizedBox(height: ShelfSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          'Nothing here? Settings may live in the registry '
                          'or the install folder.',
                          style: ShelfType.caption
                              .copyWith(color: p.textSecondary)),
                    ),
                    HyperlinkButton(
                      onPressed: _addCustomItem,
                      child: const Text('Add folder as custom item…'),
                    ),
                  ],
                ),
              ],
            ),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (widget.candidates.isNotEmpty) ...[
          Button(
            onPressed: _selected.isEmpty ? null : _editBeforeSaving,
            child: const Text('Edit before saving…'),
          ),
          FilledButton(
            onPressed: _selected.isEmpty ? null : _saveToLibrary,
            child: const Text('Save to my library'),
          ),
        ],
      ],
    );
  }

  AppEntry _buildEntry() {
    final existingIds = {
      for (final e in ref.read(localEntriesProvider).entries) e.id,
    };
    var id = normalizeAppName(_appName);
    if (id.isEmpty) id = 'app';
    var unique = id;
    var n = 2;
    while (existingIds.contains(unique)) {
      unique = '$id-${n++}';
    }
    final paths = [
      for (final c in widget.candidates)
        if (_selected.contains(c.path.stored)) c.path,
    ];
    return AppEntry(
      id: unique,
      name: _appName,
      publisher: widget.evidence.publisher,
      detect: [PathDetection(paths.first)],
      backup: [for (final p in paths) BackupRule(path: p)],
    );
  }

  void _saveToLibrary() {
    ref.read(localEntriesProvider.notifier).save(_buildEntry());
    Navigator.pop(context, _FinderOutcome.savedToLibrary);
  }

  Future<void> _editBeforeSaving() async {
    final edited = await showEntryEditorDialog(context, _buildEntry());
    if (edited == null || !mounted) return;
    ref.read(localEntriesProvider.notifier).save(edited);
    Navigator.pop(context, _FinderOutcome.savedToLibrary);
  }

  Future<void> _addCustomItem() async {
    final added = await addCustomItemFlow(context, ref);
    if (!added || !mounted) return;
    Navigator.pop(context, _FinderOutcome.addedCustomItem);
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.candidate,
    required this.checked,
    required this.onChanged,
  });

  final ConfigCandidate candidate;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    final lowConfidence = candidate.score < 0.5;
    return Padding(
      padding: const EdgeInsets.only(bottom: ShelfSpacing.sm),
      child: HoverButton(
        onPressed: () => onChanged(!checked),
        builder: (context, states) => Container(
          padding: const EdgeInsets.symmetric(
              horizontal: ShelfSpacing.md, vertical: ShelfSpacing.sm),
          decoration: BoxDecoration(
            color: checked ? p.accent.withValues(alpha: 0.08) : p.card,
            borderRadius: BorderRadius.circular(ShelfSpacing.controlRadius),
            border: Border.all(color: checked ? p.accent : p.stroke),
          ),
          child: Row(
            children: [
              Checkbox(checked: checked, onChanged: (v) => onChanged(v!)),
              const SizedBox(width: ShelfSpacing.sm),
              Expanded(
                child: Text(candidate.path.stored,
                    style: ShelfType.mono.copyWith(color: p.textPrimary)),
              ),
              if (lowConfidence) ...[
                ShelfChip(label: 'low confidence', color: p.caution),
                const SizedBox(width: ShelfSpacing.sm),
              ],
              Text('match ${(candidate.score * 100).round()}%',
                  style: ShelfType.caption.copyWith(color: p.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

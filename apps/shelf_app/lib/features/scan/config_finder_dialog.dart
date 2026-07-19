import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_detect/shelf_detect.dart';
import 'package:shelf_win32/shelf_win32.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../theme/shelf_theme.dart';
import '../backup/add_custom_item.dart';
import '../database/db_providers.dart';
import '../database/entry_editor_dialog.dart';
import 'scan_view_model.dart';

enum _FinderOutcome { savedToLibrary, addedCustomItem }

/// Shows heuristic config-folder candidates for an app the database doesn't
/// know. Primary flow: save the app to "My library" as a real database
/// entry (detection-gated, appears as Recognized on the next scan).
/// Fallback when nothing is found: add any folder as a custom backup item.
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

  final name = evidence.displayName ?? S.of(context).unknownApp;
  await displayInfoBar(context, builder: (context, close) {
    return switch (outcome) {
      _FinderOutcome.savedToLibrary => InfoBar(
          title: Text(S.of(context).savedToLibraryTitle(name)),
          content: Text(S.of(context).savedToLibraryBody),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      _FinderOutcome.addedCustomItem => InfoBar(
          title: Text(S.of(context).customItemAddedTitle),
          content: Text(S.of(context).customItemAddedBody),
          severity: InfoBarSeverity.success,
          onClose: close,
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

  String get _appName =>
      widget.evidence.displayName ?? S.of(context).unknownApp;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 560),
      title: Text(S.of(context).findConfigTitle(_appName)),
      content: widget.candidates.isEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).finderNoCandidates),
                const SizedBox(height: ShelfSpacing.md),
                Button(
                  onPressed: _addCustomItem,
                  child: Text(S.of(context).addFolderAsCustomItem),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).finderSubtitle,
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
                      child: Text(S.of(context).finderNothingHere,
                          style: ShelfType.caption
                              .copyWith(color: p.textSecondary)),
                    ),
                    HyperlinkButton(
                      onPressed: _addCustomItem,
                      child: Text(S.of(context).addFolderAsCustomItem),
                    ),
                  ],
                ),
              ],
            ),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).close),
        ),
        if (widget.candidates.isNotEmpty) ...[
          Button(
            onPressed: _selected.isEmpty ? null : _editBeforeSaving,
            child: Text(S.of(context).editBeforeSaving),
          ),
          FilledButton(
            onPressed: _selected.isEmpty ? null : _saveToLibrary,
            child: Text(S.of(context).saveToMyLibrary),
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
    // Background rescan so the new entry shows up as Recognized and in the
    // Backup list without a manual "Scan system".
    ref.read(scanProvider.notifier).scan();
    Navigator.pop(context, _FinderOutcome.savedToLibrary);
  }

  Future<void> _editBeforeSaving() async {
    final edited = await showEntryEditorDialog(context, _buildEntry());
    if (edited == null || !mounted) return;
    ref.read(localEntriesProvider.notifier).save(edited);
    ref.read(scanProvider.notifier).scan();
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
                ShelfChip(
                    label: S.of(context).lowConfidence, color: p.caution),
                const SizedBox(width: ShelfSpacing.sm),
              ],
              Text(
                  S
                      .of(context)
                      .matchPercent((candidate.score * 100).round()),
                  style: ShelfType.caption.copyWith(color: p.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

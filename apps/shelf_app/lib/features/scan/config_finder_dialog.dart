import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_detect/shelf_detect.dart';
import 'package:shelf_win32/shelf_win32.dart';

import '../backup/backup_view_model.dart';

enum _FinderOutcome { addedItem, copiedDraft }

/// Shows heuristic config-folder candidates for an app the database doesn't
/// know, and lets the user add one as a custom item and/or copy a draft
/// database entry to contribute upstream.
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
      _FinderOutcome.addedItem => InfoBar(
          title: Text('Added "$name" as a custom item'),
          content: const Text('Select it on the Backup tab.'),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      _FinderOutcome.copiedDraft => const InfoBar(
          title: Text('Draft copied'),
          content: Text(
              'Paste it into a new file under apps/ in the AppConfigShelf-DB '
              'repository and open a pull request.'),
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
  late final Set<String> _selected = {
    if (widget.candidates.isNotEmpty && widget.candidates.first.score >= 0.9)
      widget.candidates.first.path.stored,
  };

  String get _appName => widget.evidence.displayName ?? 'Unknown app';

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 560),
      title: Text('Find config — $_appName'),
      content: widget.candidates.isEmpty
          ? const Text(
              'No likely config folders found under AppData, LocalAppData, or '
              'Documents. The app may store settings in the registry or its '
              'install folder — you can still add any folder manually as a '
              'custom item on the Backup tab.')
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Likely config locations (best guesses — verify before '
                    'relying on them):',
                    style: theme.typography.body),
                const SizedBox(height: 8),
                for (final candidate in widget.candidates.take(8))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Checkbox(
                      checked: _selected.contains(candidate.path.stored),
                      onChanged: (v) => setState(() {
                        v!
                            ? _selected.add(candidate.path.stored)
                            : _selected.remove(candidate.path.stored);
                      }),
                      content: Text(
                          '${candidate.path.stored}   ·   match ${(candidate.score * 100).round()}%'),
                    ),
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
            onPressed: _selected.isEmpty ? null : _copyDraft,
            child: const Text('Copy db-entry draft'),
          ),
          FilledButton(
            onPressed: _selected.isEmpty ? null : _addCustomItem,
            child: const Text('Add as custom item'),
          ),
        ],
      ],
    );
  }

  void _addCustomItem() {
    final existing = {for (final i in ref.read(customItemsProvider)) i.slug};
    var slug = normalizeAppName(_appName);
    if (slug.isEmpty) slug = 'app';
    var unique = slug;
    var n = 2;
    while (existing.contains(unique)) {
      unique = '$slug-${n++}';
    }
    final paths = [
      for (final c in widget.candidates)
        if (_selected.contains(c.path.stored)) c.path,
    ];
    ref.read(customItemsProvider.notifier).add(CustomItem(
          slug: unique,
          name: _appName,
          backup: [for (final p in paths) BackupRule(path: p)],
        ));
    Navigator.pop(context, _FinderOutcome.addedItem);
  }

  Future<void> _copyDraft() async {
    final id = normalizeAppName(_appName).isEmpty
        ? 'app-id'
        : normalizeAppName(_appName);
    final buffer = StringBuffer()
      ..writeln('id: $id')
      ..writeln('name: $_appName');
    if (widget.evidence.publisher != null) {
      buffer.writeln('publisher: ${widget.evidence.publisher}');
    }
    buffer.writeln('detect:');
    for (final c in widget.candidates) {
      if (_selected.contains(c.path.stored)) {
        buffer.writeln('  - path: "${c.path.stored.replaceAll(r'\', r'\\')}"');
        break; // one detect probe is enough for a draft
      }
    }
    buffer.writeln('backup:');
    for (final c in widget.candidates) {
      if (_selected.contains(c.path.stored)) {
        buffer
          ..writeln('  - path: "${c.path.stored.replaceAll(r'\', r'\\')}"')
          ..writeln('    exclude: []   # TODO: exclude caches/logs');
      }
    }
    buffer
      ..writeln('risk: safe        # TODO: caution if profile/credentials')
      ..writeln('origin: original');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    Navigator.pop(context, _FinderOutcome.copiedDraft);
  }
}

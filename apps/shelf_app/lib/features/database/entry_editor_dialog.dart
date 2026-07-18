import 'package:file_selector/file_selector.dart' as fs;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_rules/shelf_rules.dart';
import 'package:shelf_win32/shelf_win32.dart';

import '../../theme/shelf_theme.dart';

/// Editable form for a database entry (official or local). Validation runs
/// through the real parser, so anything the editor accepts the engines
/// accept. Returns the edited entry, or null on cancel.
Future<AppEntry?> showEntryEditorDialog(BuildContext context, AppEntry entry) {
  return showDialog<AppEntry>(
    context: context,
    builder: (context) => _EntryEditorDialog(entry: entry),
  );
}

class _EntryEditorDialog extends StatefulWidget {
  const _EntryEditorDialog({required this.entry});

  final AppEntry entry;

  @override
  State<_EntryEditorDialog> createState() => _EntryEditorDialogState();
}

class _RuleFields {
  _RuleFields(BackupRule rule)
      : path = TextEditingController(text: rule.path.stored),
        exclude = TextEditingController(text: rule.exclude.join('\n')),
        include = TextEditingController(text: rule.include.join('\n')),
        optional = rule.optional;

  _RuleFields.empty()
      : path = TextEditingController(),
        exclude = TextEditingController(),
        include = TextEditingController(),
        optional = false;

  final TextEditingController path;
  final TextEditingController exclude;
  final TextEditingController include;
  bool optional;

  void dispose() {
    path.dispose();
    exclude.dispose();
    include.dispose();
  }
}

class _EntryEditorDialogState extends State<_EntryEditorDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.entry.name);
  late final TextEditingController _detectPath = TextEditingController(
      text: widget.entry.detect
              .whereType<PathDetection>()
              .map((d) => d.path.stored)
              .firstOrNull ??
          '');
  late final List<_RuleFields> _rules = [
    for (final rule in widget.entry.backup) _RuleFields(rule),
  ];
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _detectPath.dispose();
    for (final r in _rules) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    final errorCount = _error == null
        ? 0
        : _error!.split('\n').where((l) => l.trim().isNotEmpty).length;
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit entry — ${widget.entry.name}'),
          const SizedBox(height: ShelfSpacing.xs),
          Text(
              'Saved to My library only — the official database entry is '
              'never modified.',
              style: ShelfType.caption.copyWith(color: p.textSecondary)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoLabel(
              label: 'Display name',
              child: TextBox(controller: _name),
            ),
            const SizedBox(height: ShelfSpacing.sm),
            InfoLabel(
              label: 'Detect path',
              child: Row(children: [
                Expanded(
                  child: TextBox(
                    controller: _detectPath,
                    placeholder: r'%APPDATA%\MyApp\config.ini',
                  ),
                ),
                const SizedBox(width: ShelfSpacing.sm),
                Button(
                    onPressed: _browseDetectPath,
                    child: const Text('Browse…')),
              ]),
            ),
            const SizedBox(height: ShelfSpacing.xs),
            Text('The entry is used only when this file exists on the PC.',
                style: ShelfType.caption.copyWith(color: p.textSecondary)),
            const SizedBox(height: ShelfSpacing.md),
            Text('Backup locations',
                style: ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
            for (var i = 0; i < _rules.length; i++) ...[
              const SizedBox(height: ShelfSpacing.sm),
              _RuleCard(
                fields: _rules[i],
                canRemove: _rules.length > 1,
                onRemove: () => setState(() {
                  _rules.removeAt(i).dispose();
                }),
                onOptionalChanged: (v) =>
                    setState(() => _rules[i].optional = v),
              ),
            ],
            const SizedBox(height: ShelfSpacing.sm),
            HyperlinkButton(
              onPressed: _addRuleFromPicker,
              child: const Text('+ Add backup location…'),
            ),
            if (_error != null) ...[
              const SizedBox(height: ShelfSpacing.sm),
              InfoBar(
                title: const Text('Cannot save'),
                content: Text(_error!),
                severity: InfoBarSeverity.error,
              ),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (errorCount > 0)
          Center(
            child: Text(
                '$errorCount ${errorCount == 1 ? 'issue' : 'issues'} to fix',
                style: ShelfType.caption.copyWith(color: p.danger)),
          ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save to my library'),
        ),
      ],
    );
  }

  Future<void> _browseDetectPath() async {
    final file = await fs.openFile();
    if (file == null) return;
    // Db entries store tokenized paths only.
    final tokenized = _tokenize(file.path);
    if (tokenized == null) {
      setState(() => _error =
          'That file is outside the supported locations (AppData, '
          'LocalAppData, ProgramData, user profile, Documents).');
      return;
    }
    setState(() {
      _error = null;
      _detectPath.text = tokenized;
    });
  }

  static String? _tokenize(String absolute) {
    final folders = WindowsKnownFolderResolver();
    for (final folder in KnownFolder.values) {
      final root = folders.resolve(folder);
      if (absolute.toLowerCase().startsWith(root.toLowerCase())) {
        final rest = absolute.substring(root.length).replaceAll('/', r'\');
        return '${folder.token}$rest';
      }
    }
    return null;
  }

  Future<void> _addRuleFromPicker() async {
    final dir = await fs.getDirectoryPath();
    if (dir == null) return;
    // Re-tokenize picked absolute paths when they live under a known folder;
    // db entries cannot carry absolute paths.
    final tokenized = _tokenize(dir);
    if (tokenized == null) {
      setState(() => _error =
          'That folder is outside the supported locations (AppData, '
          'LocalAppData, ProgramData, user profile, Documents). Use a '
          'custom item on the Backup tab for arbitrary folders.');
      return;
    }
    setState(() {
      _error = null;
      _rules.add(_RuleFields.empty()..path.text = tokenized);
    });
  }

  void _save() {
    final map = <String, Object?>{
      'id': widget.entry.id,
      'name': _name.text.trim(),
      if (widget.entry.publisher != null) 'publisher': widget.entry.publisher,
      if (widget.entry.aliases.isNotEmpty) 'aliases': widget.entry.aliases,
      'detect': [
        if (_detectPath.text.trim().isNotEmpty)
          {'path': _detectPath.text.trim()},
        // Preserve non-path detect rules the editor doesn't surface.
        for (final rule in widget.entry.detect)
          switch (rule) {
            RegistryDetection(:final keyPath) => {'registry': keyPath},
            MsixDetection(:final packageFamilyName) => {
                'msix': packageFamilyName
              },
            PathDetection() => null,
          },
      ].nonNulls.toList(),
      'backup': [
        for (final rule in _rules)
          {
            'path': rule.path.text.trim(),
            if (_lines(rule.include).isNotEmpty) 'include': _lines(rule.include),
            if (_lines(rule.exclude).isNotEmpty) 'exclude': _lines(rule.exclude),
            if (rule.optional) 'optional': true,
          },
      ],
      if (widget.entry.wingetId != null) 'winget': widget.entry.wingetId,
      'risk': widget.entry.risk.name,
      'origin': widget.entry.origin.name,
    };

    final outcome = parseAppEntry(map);
    if (outcome.value == null) {
      setState(() => _error = outcome.issues
          .where((i) => i.severity == IssueSeverity.error)
          .join('\n'));
      return;
    }
    Navigator.pop(context, outcome.value);
  }

  static List<String> _lines(TextEditingController controller) => [
        for (final line in controller.text.split(RegExp(r'[\n,]')))
          if (line.trim().isNotEmpty) line.trim(),
      ];
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.fields,
    required this.canRemove,
    required this.onRemove,
    required this.onOptionalChanged,
  });

  final _RuleFields fields;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<bool> onOptionalChanged;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(ShelfSpacing.md),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(ShelfSpacing.cardRadius),
        border: Border.all(color: p.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: InfoLabel(
                label: 'Folder',
                child: TextBox(
                  controller: fields.path,
                  placeholder: r'%APPDATA%\MyApp',
                ),
              ),
            ),
            const SizedBox(width: ShelfSpacing.sm),
            IconButton(
              icon: const Icon(FluentIcons.delete),
              onPressed: canRemove ? onRemove : null,
            ),
          ]),
          const SizedBox(height: ShelfSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoLabel(
                      label: 'Include patterns',
                      child: TextBox(
                          controller: fields.include,
                          maxLines: 2,
                          minLines: 1,
                          placeholder: '**/*.json, snippets/**'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                        'Patterns like **/*.json — leave empty to include '
                        'everything',
                        style: ShelfType.caption
                            .copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: ShelfSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoLabel(
                      label: 'Exclude patterns',
                      child: TextBox(
                          controller: fields.exclude,
                          maxLines: 2,
                          minLines: 1,
                          placeholder: 'Cache/**'),
                    ),
                    const SizedBox(height: 2),
                    Text('Skipped even when matched by Include',
                        style: ShelfType.caption
                            .copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ShelfSpacing.sm),
          ToggleSwitch(
            checked: fields.optional,
            onChanged: onOptionalChanged,
            content: const Text(
                'Optional — skip silently when this folder is missing'),
          ),
        ],
      ),
    );
  }
}

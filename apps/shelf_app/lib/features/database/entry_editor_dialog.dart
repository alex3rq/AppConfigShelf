import 'package:file_selector/file_selector.dart' as fs;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_rules/shelf_rules.dart';
import 'package:shelf_win32/shelf_win32.dart';

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
    final theme = FluentTheme.of(context);
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
      title: Text('Edit entry — ${widget.entry.id}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoLabel(
              label: 'Display name',
              child: TextBox(controller: _name),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Detect path (app is "installed" when this exists)',
              child: TextBox(
                controller: _detectPath,
                placeholder: r'%APPDATA%\MyApp\config.ini',
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Text('Backup locations', style: theme.typography.bodyStrong),
              const SizedBox(width: 8),
              Button(
                onPressed: _addRuleFromPicker,
                child: const Text('Add folder…'),
              ),
            ]),
            for (var i = 0; i < _rules.length; i++) ...[
              const SizedBox(height: 8),
              Card(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: InfoLabel(
                          label: 'Path',
                          child: TextBox(
                            controller: _rules[i].path,
                            placeholder: r'%APPDATA%\MyApp',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(FluentIcons.delete),
                        onPressed: _rules.length == 1
                            ? null
                            : () => setState(() {
                                  _rules.removeAt(i).dispose();
                                }),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    InfoLabel(
                      label: 'Exclude patterns (one per line, e.g. Cache/**)',
                      child: TextBox(
                          controller: _rules[i].exclude,
                          maxLines: 2,
                          minLines: 1),
                    ),
                    const SizedBox(height: 6),
                    InfoLabel(
                      label: 'Include patterns (one per line; empty = everything)',
                      child: TextBox(
                          controller: _rules[i].include,
                          maxLines: 2,
                          minLines: 1),
                    ),
                    const SizedBox(height: 6),
                    Checkbox(
                      checked: _rules[i].optional,
                      onChanged: (v) =>
                          setState(() => _rules[i].optional = v!),
                      content: const Text('Optional (unchecked by default)'),
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
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
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _addRuleFromPicker() async {
    final dir = await fs.getDirectoryPath();
    if (dir == null) return;
    // Re-tokenize picked absolute paths when they live under a known folder;
    // db entries cannot carry absolute paths.
    final folders = WindowsKnownFolderResolver();
    String? tokenized;
    for (final folder in KnownFolder.values) {
      final root = folders.resolve(folder);
      if (dir.toLowerCase().startsWith(root.toLowerCase())) {
        final rest = dir.substring(root.length).replaceAll('/', r'\');
        tokenized = '${folder.token}$rest';
        break;
      }
    }
    if (tokenized == null) {
      setState(() => _error =
          'That folder is outside the supported locations (AppData, '
          'LocalAppData, ProgramData, user profile, Documents). Use a '
          'custom item on the Backup tab for arbitrary folders.');
      return;
    }
    setState(() {
      _error = null;
      _rules.add(_RuleFields.empty()..path.text = tokenized!);
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

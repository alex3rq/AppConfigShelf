import 'package:file_selector/file_selector.dart' as fs;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart';

import '../../l10n/gen/app_localizations.dart';
import 'backup_view_model.dart';

/// Shared "add a folder as a custom backup item" flow: folder picker →
/// path validation → name prompt → saved via [customItemsProvider].
/// Returns true when an item was added.
Future<bool> addCustomItemFlow(BuildContext context, WidgetRef ref) async {
  final dir = await fs.getDirectoryPath();
  if (dir == null || !context.mounted) return false;

  final parsed = StoragePath.parse(dir, allowAbsolute: true);
  final path = parsed.valueOrNull;
  if (path == null) {
    await displayInfoBar(context, builder: (context, close) {
      return InfoBar(
        title: Text(S.of(context).unsupportedPath),
        content: Text(parsed.failureOrNull!.message),
        severity: InfoBarSeverity.error,
        onClose: close,
      );
    });
    return false;
  }

  final defaultName = dir.split(RegExp(r'[\\/]')).last;
  final name = await _promptName(context, defaultName);
  if (name == null || name.isEmpty) return false;

  ref.read(customItemsProvider.notifier).add(CustomItem(
        slug: _slugify(ref, name),
        name: name,
        backup: [BackupRule(path: path)],
      ));
  return true;
}

Future<String?> _promptName(BuildContext context, String initial) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => ContentDialog(
      title: Text(S.of(context).nameThisItem),
      content: TextBox(controller: controller, autofocus: true, maxLines: 1),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(S.of(context).add),
        ),
      ],
    ),
  );
}

String _slugify(WidgetRef ref, String name) {
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

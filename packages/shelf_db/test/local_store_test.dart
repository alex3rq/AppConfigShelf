import 'dart:io';

import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_db/shelf_db.dart';
import 'package:test/test.dart';

AppEntry _entry(String id, {String name = 'App'}) => AppEntry(
      id: id,
      name: name,
      detect: [
        PathDetection(
            StoragePath.parse('%APPDATA%\\$id').valueOrNull! as TokenizedPath)
      ],
      backup: [
        BackupRule(path: StoragePath.parse('%APPDATA%\\$id').valueOrNull!),
      ],
    );

void main() {
  late Directory temp;
  late LocalEntryStore store;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('local_entries');
    store = LocalEntryStore(temp.path);
  });

  tearDown(() => temp.deleteSync(recursive: true));

  test('save/load round trip', () {
    store.save(_entry('upscayl', name: 'Upscayl'));
    final loaded = store.load();
    expect(loaded.warnings, isEmpty);
    expect(loaded.entries.single.id, 'upscayl');
    expect(loaded.entries.single.name, 'Upscayl');
    expect(loaded.entries.single.backup.single.path.stored,
        r'%APPDATA%\upscayl');
  });

  test('save overwrites same id', () {
    store.save(_entry('a', name: 'One'));
    store.save(_entry('a', name: 'Two'));
    expect(store.load().entries.single.name, 'Two');
  });

  test('delete removes entry', () {
    store.save(_entry('a'));
    store.delete('a');
    expect(store.load().entries, isEmpty);
  });

  test('invalid file is skipped with warning, valid ones survive', () {
    store.save(_entry('good'));
    File('${temp.path}/bad.json').writeAsStringSync('{not json');
    File('${temp.path}/invalid-entry.json')
        .writeAsStringSync('{"id": "x y z"}');
    final loaded = store.load();
    expect(loaded.entries.single.id, 'good');
    expect(loaded.warnings, hasLength(2));
  });

  test('missing directory loads empty', () {
    final missing = LocalEntryStore('${temp.path}/nope');
    expect(missing.load().entries, isEmpty);
  });

  group('mergeEntries', () {
    test('local override wins, badges reported', () {
      final official = [_entry('vscode', name: 'Official'), _entry('git')];
      final local = [_entry('vscode', name: 'Customized'), _entry('upscayl')];
      final merged = mergeEntries(official, local);

      expect(merged.entries.map((e) => e.id),
          containsAll(['vscode', 'git', 'upscayl']));
      expect(merged.entries.firstWhere((e) => e.id == 'vscode').name,
          'Customized');
      expect(merged.overriddenIds, {'vscode'});
      expect(merged.freshLocalIds, {'upscayl'});
      expect(merged.entries, hasLength(3), reason: 'no duplicate vscode');
    });
  });
}

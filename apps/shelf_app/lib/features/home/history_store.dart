import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_core/shelf_core.dart' show KnownFolder;
import 'package:shelf_win32/shelf_win32.dart';

/// One row of the Home "Safety timeline": a backup this PC produced or an
/// undo bundle a restore kept.
enum HistoryKind { backup, undoBundle }

final class HistoryEvent {
  const HistoryEvent({
    required this.kind,
    required this.path,
    required this.timestamp,
    required this.summary,
  });

  final HistoryKind kind;

  /// Absolute path of the .acshelf / undo bundle.
  final String path;
  final DateTime timestamp;

  /// e.g. "38 apps · 3 custom items · 812 MB" or "rolls back 12 entries".
  final String summary;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'path': path,
        'timestamp': timestamp.toIso8601String(),
        'summary': summary,
      };

  static HistoryEvent? fromJson(Map<String, Object?> json) {
    final kind = HistoryKind.values
        .where((k) => k.name == json['kind'])
        .firstOrNull;
    final path = json['path'];
    final ts = DateTime.tryParse(json['timestamp']?.toString() ?? '');
    if (kind == null || path is! String || ts == null) return null;
    return HistoryEvent(
      kind: kind,
      path: path,
      timestamp: ts,
      summary: json['summary']?.toString() ?? '',
    );
  }
}

/// Persists the safety timeline to
/// `%APPDATA%\AppConfigShelf\history.json`, newest first.
final class HistoryStore {
  HistoryStore({String? overridePath})
      : _path = overridePath ??
            '${WindowsKnownFolderResolver().resolve(KnownFolder.appData)}'
                r'\AppConfigShelf\history.json';

  final String _path;

  List<HistoryEvent> load() {
    final file = File(_path);
    if (!file.existsSync()) return const [];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! List) return const [];
      return [
        for (final raw in decoded)
          if (raw is Map)
            ?HistoryEvent.fromJson(
                raw.map((k, v) => MapEntry(k.toString(), v))),
      ];
    } on FormatException {
      return const [];
    }
  }

  void save(List<HistoryEvent> events) {
    final file = File(_path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(const JsonEncoder.withIndent('  ')
        .convert([for (final e in events) e.toJson()]));
  }
}

final historyProvider =
    NotifierProvider<HistoryNotifier, List<HistoryEvent>>(HistoryNotifier.new);

final class HistoryNotifier extends Notifier<List<HistoryEvent>> {
  final _store = HistoryStore();

  @override
  List<HistoryEvent> build() => _store.load();

  void record(HistoryEvent event) {
    state = [event, ...state];
    _store.save(state);
  }
}

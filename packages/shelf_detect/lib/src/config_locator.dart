import 'package:shelf_core/shelf_core.dart';

import 'evidence.dart';

/// A guessed configuration location for an app the database doesn't know.
final class ConfigCandidate {
  const ConfigCandidate({required this.path, required this.score});

  final TokenizedPath path;

  /// 0.0–1.0; higher = stronger name match. Candidates are returned sorted
  /// descending.
  final double score;

  @override
  String toString() => '${path.stored} (${(score * 100).round()}%)';
}

/// Lowercase, strip parenthesized decorations, non-alphanumerics, and a
/// trailing version — "Notepad++ (64-bit x64)" and "notepad++" meet in the
/// middle. Shared by the resolver and the config locator.
String normalizeAppName(String name) {
  var n = name.toLowerCase();
  n = n.replaceAll(RegExp(r'\((?:[^)]*)\)'), '');
  n = n.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  n = n.replaceAll(RegExp(r'(?:v?\d+(?:\.\d+)*)$'), '');
  return n;
}

const _searchRoots = [
  KnownFolder.appData,
  KnownFolder.localAppData,
  KnownFolder.documents,
];

/// Heuristically finds likely config folders for [evidence] by matching the
/// app name and publisher against directory names under the user-scope
/// known folders. Checks two levels: `root\App` and `root\Publisher\App`.
/// Pure: all I/O via the views. Results are suggestions for the user to
/// confirm — never backed up automatically.
List<ConfigCandidate> locateConfigCandidates({
  required InstallEvidence evidence,
  required FileSystemView fileSystem,
  required KnownFolderResolver knownFolders,
}) {
  final appNorm = normalizeAppName(evidence.displayName ?? '');
  if (appNorm.isEmpty) return const [];
  final publisherNorm = normalizeAppName(evidence.publisher ?? '');

  final candidates = <String, ConfigCandidate>{};

  void consider(KnownFolder root, List<String> segments, double score) {
    final path = TokenizedPath(root, segments);
    final key = path.stored.toLowerCase();
    final existing = candidates[key];
    if (existing == null || existing.score < score) {
      candidates[key] = ConfigCandidate(path: path, score: score);
    }
  }

  double? matchScore(String dirName) {
    final dirNorm = normalizeAppName(dirName);
    if (dirNorm.isEmpty) return null;
    if (dirNorm == appNorm) return 1.0;
    // Containment both ways, guarded against trivial short strings.
    if (appNorm.length >= 4 && dirNorm.contains(appNorm)) return 0.7;
    if (dirNorm.length >= 4 && appNorm.contains(dirNorm)) return 0.6;
    return null;
  }

  for (final root in _searchRoots) {
    final rootAbsolute = knownFolders.resolve(root);
    final level1 = fileSystem.subdirectoryNames(rootAbsolute);
    for (final dir in level1) {
      final direct = matchScore(dir);
      if (direct != null) {
        consider(root, [dir], direct);
      }
      // Publisher\App second level.
      final dirNorm = normalizeAppName(dir);
      final isPublisherDir = publisherNorm.isNotEmpty &&
          dirNorm.isNotEmpty &&
          (dirNorm == publisherNorm ||
              publisherNorm.contains(dirNorm) ||
              dirNorm.contains(publisherNorm));
      if (isPublisherDir || direct != null) {
        for (final sub in fileSystem.subdirectoryNames('$rootAbsolute\\$dir')) {
          final subScore = matchScore(sub);
          if (subScore != null) {
            consider(root, [dir, sub],
                isPublisherDir ? (subScore * 0.95).clamp(0, 1).toDouble() : subScore * 0.85);
          }
        }
        if (isPublisherDir && direct == null) {
          // Publisher dir with no app-named child still worth surfacing low.
          consider(root, [dir], 0.4);
        }
      }
    }
  }

  final sorted = candidates.values.toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return sorted;
}

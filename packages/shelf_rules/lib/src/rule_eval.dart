import 'package:glob/glob.dart';
import 'package:shelf_core/shelf_core.dart';

/// Compiled include/exclude matcher for one [BackupRule]. Pure — operates on
/// relative paths the caller enumerated.
///
/// Semantics (ADR-001): empty include list means everything under the rule
/// root; exclude always wins over include.
final class RuleMatcher {
  RuleMatcher(BackupRule rule)
      : _include = [for (final g in rule.include) Glob(g, caseSensitive: false)],
        _exclude = [for (final g in rule.exclude) Glob(g, caseSensitive: false)];

  final List<Glob> _include;
  final List<Glob> _exclude;

  /// [relativePath] uses forward slashes, relative to the rule root, no
  /// leading slash (e.g. `snippets/dart.json`).
  bool matches(String relativePath) {
    if (_exclude.any((g) => g.matches(relativePath))) return false;
    if (_include.isEmpty) return true;
    return _include.any((g) => g.matches(relativePath));
  }

  /// Filters an enumeration, preserving order.
  List<String> filter(Iterable<String> relativePaths) =>
      [for (final p in relativePaths) if (matches(p)) p];
}

/// Severity of a validation finding. [error] blocks the entry; [warning]
/// merges but should be surfaced (db CI may still choose to fail on it).
enum IssueSeverity { error, warning }

/// A single validation finding, addressed by a dotted field path so db CI
/// can point contributors at the exact spot (e.g. `backup[0].path`).
final class ValidationIssue {
  const ValidationIssue(this.severity, this.field, this.message);

  const ValidationIssue.error(String field, String message)
      : this(IssueSeverity.error, field, message);

  const ValidationIssue.warning(String field, String message)
      : this(IssueSeverity.warning, field, message);

  final IssueSeverity severity;
  final String field;
  final String message;

  @override
  String toString() => '${severity.name}: $field: $message';
}

/// Outcome of parsing one entry: a parsed value when no errors occurred,
/// plus every issue found (errors and warnings are accumulated, not
/// fail-fast, so a contributor sees all problems in one CI run).
final class ParseOutcome<T> {
  const ParseOutcome(this.value, this.issues);

  /// Null iff [hasErrors].
  final T? value;

  final List<ValidationIssue> issues;

  bool get hasErrors =>
      issues.any((i) => i.severity == IssueSeverity.error);
}

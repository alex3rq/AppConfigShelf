/// Typed failures used across all engine packages.
///
/// Engines return failures as values (see [Result]) instead of throwing, so
/// pipelines can aggregate per-file failures and continue. Exceptions are
/// reserved for programming errors.
sealed class ShelfFailure {
  const ShelfFailure(this.message);

  /// Human-neutral description. UI layers map failure types to localized,
  /// actionable messages; this string is for logs.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// A path string could not be parsed or violates path constraints
/// (e.g. contains `..`, empty segments, or an unknown token).
final class InvalidPathFailure extends ShelfFailure {
  const InvalidPathFailure(super.message, {required this.input});

  /// The offending raw input.
  final String input;
}

/// Access to a file, directory, or registry key was denied.
final class AccessDeniedFailure extends ShelfFailure {
  const AccessDeniedFailure(super.message, {required this.path});

  final String path;
}

/// A file is locked by another process.
final class FileLockedFailure extends ShelfFailure {
  const FileLockedFailure(super.message, {required this.path, this.lockingProcess});

  final String path;

  /// Process name holding the lock, when known.
  final String? lockingProcess;
}

/// A resolved path exceeds platform limits and long-path handling failed.
final class PathTooLongFailure extends ShelfFailure {
  const PathTooLongFailure(super.message, {required this.path});

  final String path;
}

/// Content hash did not match the manifest at verification time.
final class HashMismatchFailure extends ShelfFailure {
  const HashMismatchFailure(super.message, {required this.path, required this.expected, required this.actual});

  final String path;
  final String expected;
  final String actual;
}

/// A referenced file, directory, or registry key does not exist.
final class NotFoundFailure extends ShelfFailure {
  const NotFoundFailure(super.message, {required this.path});

  final String path;
}

/// Structured data (db entry, manifest, bundle) failed to parse or validate.
final class ParseFailure extends ShelfFailure {
  const ParseFailure(super.message, {this.source});

  /// Where the bad data came from (file name, entry id), when known.
  final String? source;
}

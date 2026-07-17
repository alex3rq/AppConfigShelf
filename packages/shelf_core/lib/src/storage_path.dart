import 'failure.dart';
import 'result.dart';

/// Windows known folders a [TokenizedPath] can be rooted at.
///
/// At runtime these are resolved through the Known Folders API (never
/// environment variables, which can lie under elevation). The [token] form is
/// what gets stored in database entries and package manifests.
enum KnownFolder {
  appData('%APPDATA%'),
  localAppData('%LOCALAPPDATA%'),
  programData('%PROGRAMDATA%'),
  userProfile('%USERPROFILE%'),
  documents('%DOCUMENTS%');

  const KnownFolder(this.token);

  final String token;

  static KnownFolder? fromToken(String token) {
    final upper = token.toUpperCase();
    for (final folder in values) {
      if (folder.token == upper) return folder;
    }
    return null;
  }
}

/// A storage location as persisted in database entries, custom items, and
/// package manifests. Never a raw machine-specific string.
///
/// Two forms:
/// - [TokenizedPath]: rooted at a [KnownFolder]; survives username/drive
///   changes across a reinstall. Required for database entries.
/// - [AbsolutePath]: full Windows path; only permitted for user-created
///   custom items whose target lies outside every known folder. Restore
///   warns when the root no longer exists.
sealed class StoragePath {
  const StoragePath();

  /// Parses a stored path string.
  ///
  /// Accepts `\` or `/` separators. Fails on `..` segments, empty segments,
  /// and unknown `%TOKEN%` roots. Absolute inputs (drive-letter or UNC) are
  /// only accepted when [allowAbsolute] is true — database entries must
  /// always pass false so a malicious entry cannot target arbitrary
  /// locations (see docs/plan/10-security.md).
  static Result<StoragePath> parse(String input, {bool allowAbsolute = false}) {
    final raw = input.trim();
    if (raw.isEmpty) {
      return Result.err(InvalidPathFailure('empty path', input: input));
    }

    final tokenMatch = RegExp(r'^%([A-Za-z]+)%[\\/]?').firstMatch(raw);
    if (tokenMatch != null) {
      final folder = KnownFolder.fromToken('%${tokenMatch.group(1)!}%');
      if (folder == null) {
        return Result.err(InvalidPathFailure(
            'unknown token %${tokenMatch.group(1)}%',
            input: input));
      }
      final rest = raw.substring(tokenMatch.end);
      final segments = _splitSegments(rest);
      return _validateSegments(segments, input)
          .map((s) => TokenizedPath(folder, s));
    }

    final isDrive = RegExp(r'^[A-Za-z]:[\\/]').hasMatch(raw);
    final isUnc = raw.startsWith(r'\\');
    if (isDrive || isUnc) {
      if (!allowAbsolute) {
        return Result.err(InvalidPathFailure(
            'absolute paths are not allowed here', input: input));
      }
      // Validate everything after the root for traversal.
      final afterRoot = isDrive ? raw.substring(3) : raw.substring(2);
      final root = isDrive ? raw.substring(0, 3) : r'\\';
      final segments = _splitSegments(afterRoot);
      return _validateSegments(segments, input)
          .map((s) => AbsolutePath(root: root, segments: s));
    }

    return Result.err(InvalidPathFailure(
        'path must start with a known-folder token'
        '${allowAbsolute ? ' or be absolute' : ''}',
        input: input));
  }

  static List<String> _splitSegments(String rest) => rest
      .split(RegExp(r'[\\/]'))
      .where((s) => s.isNotEmpty)
      .toList(growable: false);

  static Result<List<String>> _validateSegments(
      List<String> segments, String input) {
    for (final segment in segments) {
      if (segment == '..' || segment == '.') {
        return Result.err(
            InvalidPathFailure("'$segment' segment not allowed", input: input));
      }
      if (segment.contains(':')) {
        return Result.err(InvalidPathFailure(
            "':' not allowed in path segment '$segment'",
            input: input));
      }
    }
    return Result.ok(segments);
  }

  /// Path segments below the root, in order.
  List<String> get segments;

  /// Canonical stored form (backslash separators, token root when tokenized).
  String get stored;
}

/// A path rooted at a [KnownFolder]. The only form database entries may use.
final class TokenizedPath extends StoragePath {
  const TokenizedPath(this.root, this.segments);

  final KnownFolder root;

  @override
  final List<String> segments;

  @override
  String get stored =>
      segments.isEmpty ? root.token : '${root.token}\\${segments.join(r'\')}';

  @override
  bool operator ==(Object other) =>
      other is TokenizedPath && other.stored == stored;

  @override
  int get hashCode => stored.hashCode;

  @override
  String toString() => stored;
}

/// A machine-specific absolute path. Custom items only.
final class AbsolutePath extends StoragePath {
  const AbsolutePath({required this.root, required this.segments});

  /// Drive root like `C:\` or `\\` for UNC.
  final String root;

  @override
  final List<String> segments;

  @override
  String get stored => '$root${segments.join(r'\')}';

  @override
  bool operator ==(Object other) =>
      other is AbsolutePath && other.stored == stored;

  @override
  int get hashCode => stored.hashCode;

  @override
  String toString() => stored;
}

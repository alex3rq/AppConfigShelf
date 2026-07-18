import 'package:glob/glob.dart';

/// Matches display names against the database's ignore patterns —
/// system-component-like software (redistributables, SDKs, drivers) that is
/// never a config-backup candidate. Case-insensitive globs over the raw
/// (unnormalized) display name, since patterns are authored against real
/// installer names.
final class IgnoreMatcher {
  IgnoreMatcher(List<String> patterns)
      : _globs = [for (final p in patterns) Glob(p, caseSensitive: false)];

  final List<Glob> _globs;

  bool isIgnored(String? displayName) {
    if (displayName == null || displayName.isEmpty) return false;
    return _globs.any((g) => g.matches(displayName));
  }
}

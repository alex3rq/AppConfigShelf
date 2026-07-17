import 'package:shelf_core/shelf_core.dart';
import 'package:yaml/yaml.dart';

import 'validation.dart';

/// Db schema v1 parser/validator. Accumulates all issues instead of failing
/// fast so database CI reports every problem in one run.
///
/// Security constraints enforced here are duplicated at runtime by the
/// backup/restore pipelines (defense in depth, docs/plan/10-security.md):
/// database entries may never use absolute paths or `..` traversal.

const _idPattern = r'^[a-z0-9][a-z0-9-]*$';
const _registryHives = ['HKCU', 'HKLM', 'HKEY_CURRENT_USER', 'HKEY_LOCAL_MACHINE'];

/// Parses a database entry from YAML source text.
ParseOutcome<AppEntry> parseAppEntryYaml(String source) {
  final Object? doc;
  try {
    doc = loadYaml(source);
  } on YamlException catch (e) {
    return ParseOutcome(
        null, [ValidationIssue.error('(document)', 'invalid YAML: ${e.message}')]);
  }
  if (doc is! Map) {
    return ParseOutcome(
        null, const [ValidationIssue.error('(document)', 'entry must be a map')]);
  }
  return parseAppEntry(_toPlainMap(doc));
}

/// Parses a database entry from an already-decoded map (compiled db.json).
ParseOutcome<AppEntry> parseAppEntry(Map<String, Object?> map) {
  final issues = <ValidationIssue>[];

  final id = _requireString(map, 'id', issues);
  if (id != null && !RegExp(_idPattern).hasMatch(id)) {
    issues.add(ValidationIssue.error(
        'id', "must match $_idPattern (got '$id')"));
  }

  final name = _requireString(map, 'name', issues);
  final publisher = _optionalString(map, 'publisher', issues);
  final wingetId = _optionalString(map, 'winget', issues);
  final aliases = _stringList(map, 'aliases', issues);

  final risk = _parseRisk(map, issues);
  final detect = _parseDetect(map, issues);
  final backup = _parseBackup(map, issues);

  final knownKeys = {
    'id', 'name', 'publisher', 'aliases', 'detect', 'backup',
    'registry', 'winget', 'risk',
  };
  for (final key in map.keys) {
    if (!knownKeys.contains(key)) {
      issues.add(ValidationIssue.warning(key, 'unknown field (ignored)'));
    }
  }

  if (issues.any((i) => i.severity == IssueSeverity.error)) {
    return ParseOutcome(null, issues);
  }
  return ParseOutcome(
    AppEntry(
      id: id!,
      name: name!,
      publisher: publisher,
      aliases: aliases,
      detect: detect,
      backup: backup,
      wingetId: wingetId,
      risk: risk,
    ),
    issues,
  );
}

/// Parses a custom item as stored in a package manifest. Manifest data is
/// untrusted input on load, so it passes through the same validation as
/// database entries — except absolute paths are permitted.
ParseOutcome<CustomItem> parseCustomItem(Map<String, Object?> map) {
  final issues = <ValidationIssue>[];

  final slug = _requireString(map, 'slug', issues);
  if (slug != null && !RegExp(_idPattern).hasMatch(slug)) {
    issues.add(ValidationIssue.error(
        'slug', "must match $_idPattern (got '$slug')"));
  }
  final name = _requireString(map, 'name', issues);
  final backup = _parseBackupRules(map['backup'], 'backup', issues,
      allowAbsolute: true);
  if (backup.isEmpty) {
    issues.add(const ValidationIssue.error(
        'backup', 'custom item must have at least one backup rule'));
  }

  if (issues.any((i) => i.severity == IssueSeverity.error)) {
    return ParseOutcome(null, issues);
  }
  return ParseOutcome(
      CustomItem(slug: slug!, name: name!, backup: backup), issues);
}

RiskTier _parseRisk(Map<String, Object?> map, List<ValidationIssue> issues) {
  final raw = map['risk'];
  if (raw == null) return RiskTier.safe;
  if (raw is String) {
    for (final tier in RiskTier.values) {
      if (tier.name == raw) return tier;
    }
  }
  issues.add(ValidationIssue.error(
      'risk', "must be one of ${RiskTier.values.map((r) => r.name).join('|')}"));
  return RiskTier.safe;
}

List<DetectionRule> _parseDetect(
    Map<String, Object?> map, List<ValidationIssue> issues) {
  final raw = map['detect'];
  if (raw is! List || raw.isEmpty) {
    issues.add(const ValidationIssue.error(
        'detect', 'at least one detection rule is required'));
    return const [];
  }
  final rules = <DetectionRule>[];
  for (var i = 0; i < raw.length; i++) {
    final field = 'detect[$i]';
    final item = raw[i];
    if (item is! Map) {
      issues.add(ValidationIssue.error(field, 'must be a map'));
      continue;
    }
    final keys = item.keys.cast<Object?>().toSet();
    if (item['registry'] is String && keys.length == 1) {
      final keyPath = item['registry'] as String;
      final hive = keyPath.split(RegExp(r'[\\/]')).first.toUpperCase();
      if (!_registryHives.contains(hive)) {
        issues.add(ValidationIssue.error(
            '$field.registry', 'key must start with one of $_registryHives'));
      } else {
        rules.add(RegistryDetection(keyPath));
      }
    } else if (item['path'] is String && keys.length == 1) {
      final parsed = StoragePath.parse(item['path'] as String);
      parsed.fold(
        (path) => rules.add(PathDetection(path as TokenizedPath)),
        (failure) =>
            issues.add(ValidationIssue.error('$field.path', failure.message)),
      );
    } else if (item['msix'] is String && keys.length == 1) {
      rules.add(MsixDetection(item['msix'] as String));
    } else {
      issues.add(ValidationIssue.error(field,
          'must be exactly one of {registry: <key>}, {path: <tokenized path>}, {msix: <family name>}'));
    }
  }
  return rules;
}

List<BackupRule> _parseBackup(
    Map<String, Object?> map, List<ValidationIssue> issues) {
  final rules = _parseBackupRules(map['backup'], 'backup', issues,
      allowAbsolute: false);
  if (rules.isEmpty &&
      !issues.any((i) => i.field.startsWith('backup'))) {
    issues.add(const ValidationIssue.error(
        'backup', 'at least one backup rule is required'));
  } else if (rules.isEmpty) {
    // Individual rule errors already reported; still flag the entry.
    issues.add(const ValidationIssue.error(
        'backup', 'no valid backup rules remain'));
  }
  return rules;
}

List<BackupRule> _parseBackupRules(Object? raw, String field,
    List<ValidationIssue> issues, {required bool allowAbsolute}) {
  if (raw == null) {
    return const [];
  }
  if (raw is! List) {
    issues.add(ValidationIssue.error(field, 'must be a list'));
    return const [];
  }
  final rules = <BackupRule>[];
  for (var i = 0; i < raw.length; i++) {
    final ruleField = '$field[$i]';
    final item = raw[i];
    if (item is! Map) {
      issues.add(ValidationIssue.error(ruleField, 'must be a map'));
      continue;
    }
    final ruleMap = _toPlainMap(item);
    final pathRaw = ruleMap['path'];
    if (pathRaw is! String) {
      issues.add(ValidationIssue.error('$ruleField.path', 'required string'));
      continue;
    }
    final parsed = StoragePath.parse(pathRaw, allowAbsolute: allowAbsolute);
    final path = parsed.valueOrNull;
    if (path == null) {
      issues.add(ValidationIssue.error(
          '$ruleField.path', parsed.failureOrNull!.message));
      continue;
    }
    rules.add(BackupRule(
      path: path,
      include: _stringList(ruleMap, 'include', issues, prefix: '$ruleField.'),
      exclude: _stringList(ruleMap, 'exclude', issues, prefix: '$ruleField.'),
      optional: _boolField(ruleMap, 'optional', issues, prefix: '$ruleField.'),
      sizeWarning:
          _boolField(ruleMap, 'sizeWarning', issues, prefix: '$ruleField.'),
    ));
  }
  return rules;
}

String? _requireString(
    Map<String, Object?> map, String key, List<ValidationIssue> issues) {
  final value = map[key];
  if (value is String && value.isNotEmpty) return value;
  issues.add(ValidationIssue.error(key, 'required non-empty string'));
  return null;
}

String? _optionalString(
    Map<String, Object?> map, String key, List<ValidationIssue> issues) {
  final value = map[key];
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return value;
  issues.add(ValidationIssue.error(key, 'must be a non-empty string'));
  return null;
}

List<String> _stringList(
    Map<String, Object?> map, String key, List<ValidationIssue> issues,
    {String prefix = ''}) {
  final value = map[key];
  if (value == null) return const [];
  if (value is List && value.every((e) => e is String)) {
    return value.cast<String>();
  }
  issues.add(ValidationIssue.error('$prefix$key', 'must be a list of strings'));
  return const [];
}

bool _boolField(
    Map<String, Object?> map, String key, List<ValidationIssue> issues,
    {String prefix = ''}) {
  final value = map[key];
  if (value == null) return false;
  if (value is bool) return value;
  issues.add(ValidationIssue.error('$prefix$key', 'must be a boolean'));
  return false;
}

Map<String, Object?> _toPlainMap(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key.toString(), _toPlain(value)));
}

Object? _toPlain(Object? value) => switch (value) {
      Map<dynamic, dynamic>() => _toPlainMap(value),
      List<dynamic>() => value.map(_toPlain).toList(growable: false),
      _ => value,
    };

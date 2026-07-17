// Validates and compiles the AppConfigShelf database.
//
// Usage:
//   db_validator --entries <dir>                      validate all entries
//   db_validator --entries <dir> --compile <db.json>  validate + compile bundle
//       [--content-version <v>]
//   db_validator --sign <db.json> --version-file <db-version.json>
//       [--content-version <v>]                       sign a compiled bundle
//       (reads the Ed25519 private key, hex, from $DB_SIGNING_KEY)
//
// Exit codes: 0 ok (warnings allowed), 1 validation errors, 2 usage/IO error.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as c;
import 'package:cryptography/cryptography.dart';
import 'package:shelf_core/shelf_core.dart';
import 'package:shelf_rules/shelf_rules.dart';

const schemaVersion = 1;

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  if (options == null) {
    stderr.writeln('invalid arguments — see header of this file for usage');
    exit(2);
  }

  if (options.signPath != null) {
    await _sign(options);
    return;
  }

  final entriesDir = Directory(options.entriesDir!);
  if (!entriesDir.existsSync()) {
    stderr.writeln('entries directory not found: ${entriesDir.path}');
    exit(2);
  }

  final files = entriesDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final entries = <AppEntry>[];
  final seenIds = <String, String>{};
  final aliasOwner = <String, String>{};
  var errorCount = 0;
  var warningCount = 0;

  for (final file in files) {
    final relative = file.path
        .substring(entriesDir.path.length + 1)
        .replaceAll(r'\', '/');
    final outcome = parseAppEntryYaml(file.readAsStringSync());
    for (final issue in outcome.issues) {
      final line = '$relative: $issue';
      if (issue.severity == IssueSeverity.error) {
        errorCount += 1;
        stderr.writeln('ERROR $line');
      } else {
        warningCount += 1;
        stdout.writeln('warn  $line');
      }
    }
    final entry = outcome.value;
    if (entry == null) continue;

    final expectedFileName = '${entry.id}.yaml';
    if (!relative.endsWith('/$expectedFileName') &&
        relative != expectedFileName) {
      errorCount += 1;
      stderr.writeln(
          'ERROR $relative: file must be named $expectedFileName (id: ${entry.id})');
    }
    final duplicate = seenIds[entry.id];
    if (duplicate != null) {
      errorCount += 1;
      stderr.writeln("ERROR $relative: duplicate id '${entry.id}' (also in $duplicate)");
    }
    seenIds[entry.id] = relative;

    for (final alias in entry.aliases) {
      final owner = aliasOwner[alias.toLowerCase()];
      if (owner != null && owner != entry.id) {
        errorCount += 1;
        stderr.writeln(
            "ERROR $relative: alias '$alias' collides with entry '$owner'");
      }
      aliasOwner[alias.toLowerCase()] = entry.id;
    }
    entries.add(entry);
  }

  stdout.writeln(
      '${files.length} files, ${entries.length} valid entries, $errorCount errors, $warningCount warnings');
  if (errorCount > 0) exit(1);

  final compilePath = options.compilePath;
  if (compilePath != null) {
    entries.sort((a, b) => a.id.compareTo(b.id));
    final bundle = {
      'schemaVersion': schemaVersion,
      'contentVersion': options.contentVersion ?? 'dev',
      'entries': [for (final e in entries) appEntryToJson(e)],
    };
    final out = File(compilePath);
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(jsonEncode(bundle));
    stdout.writeln('compiled ${entries.length} entries -> $compilePath '
        '(${out.lengthSync()} bytes)');
  }
}

Future<void> _sign(_Options options) async {
  final keyHex = Platform.environment['DB_SIGNING_KEY'];
  if (keyHex == null || keyHex.isEmpty) {
    stderr.writeln('DB_SIGNING_KEY env var not set');
    exit(2);
  }
  final bundleFile = File(options.signPath!);
  final bytes = bundleFile.readAsBytesSync();

  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPairFromSeed(_fromHex(keyHex));
  final signature = await algorithm.sign(bytes, keyPair: keyPair);
  final publicKey = await keyPair.extractPublicKey();

  final versionInfo = {
    'schemaVersion': schemaVersion,
    'contentVersion': options.contentVersion ?? 'dev',
    'sha256': c.sha256.convert(bytes).toString(),
    'signature': _toHex(signature.bytes),
    'publicKey': _toHex(publicKey.bytes),
    'sizeBytes': bytes.length,
  };
  File(options.versionFilePath!)
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(versionInfo));
  stdout.writeln('signed ${options.signPath} -> ${options.versionFilePath}');
}

final class _Options {
  _Options({
    this.entriesDir,
    this.compilePath,
    this.contentVersion,
    this.signPath,
    this.versionFilePath,
  });

  final String? entriesDir;
  final String? compilePath;
  final String? contentVersion;
  final String? signPath;
  final String? versionFilePath;
}

_Options? _parseArgs(List<String> args) {
  String? entries, compile, contentVersion, sign, versionFile;
  for (var i = 0; i < args.length; i += 2) {
    if (i + 1 >= args.length) return null;
    final value = args[i + 1];
    switch (args[i]) {
      case '--entries':
        entries = value;
      case '--compile':
        compile = value;
      case '--content-version':
        contentVersion = value;
      case '--sign':
        sign = value;
      case '--version-file':
        versionFile = value;
      default:
        return null;
    }
  }
  if (sign != null) {
    return versionFile == null
        ? null
        : _Options(
            signPath: sign,
            versionFilePath: versionFile,
            contentVersion: contentVersion);
  }
  if (entries == null) return null;
  return _Options(
      entriesDir: entries, compilePath: compile, contentVersion: contentVersion);
}

List<int> _fromHex(String hex) => [
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ];

String _toHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

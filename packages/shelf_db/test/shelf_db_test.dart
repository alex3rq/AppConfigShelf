import 'dart:convert';

import 'package:crypto/crypto.dart' as c;
import 'package:cryptography/cryptography.dart';
import 'package:shelf_db/shelf_db.dart';
import 'package:test/test.dart';

const _bundleJson = '''
{
  "schemaVersion": 1,
  "contentVersion": "2026.07.1",
  "entries": [
    {
      "id": "vscode",
      "name": "Visual Studio Code",
      "detect": [{"path": "%APPDATA%\\\\Code"}],
      "backup": [{"path": "%APPDATA%\\\\Code\\\\User"}]
    },
    {"id": "broken entry with spaces", "name": "Broken"}
  ]
}
''';

void main() {
  group('DbBundle.parse', () {
    test('parses valid bundle, drops broken entries', () {
      final bundle = DbBundle.parse(_bundleJson).valueOrNull!;
      expect(bundle.schemaVersion, 1);
      expect(bundle.contentVersion, '2026.07.1');
      expect(bundle.entries.map((e) => e.id), ['vscode']);
    });

    test('rejects newer schema major', () {
      final result =
          DbBundle.parse('{"schemaVersion": 99, "entries": []}');
      expect(result.isOk, isFalse);
      expect(result.failureOrNull!.message, contains('update AppConfigShelf'));
    });

    test('rejects non-JSON', () {
      expect(DbBundle.parse('nope').isOk, isFalse);
    });
  });

  group('verifyBundle', () {
    late List<int> bytes;
    late String versionJson;
    late String publicKeyHex;

    setUp(() async {
      bytes = utf8.encode(_bundleJson);
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final signature = await algorithm.sign(bytes, keyPair: keyPair);
      final publicKey = await keyPair.extractPublicKey();
      publicKeyHex = _hex(publicKey.bytes);
      versionJson = jsonEncode({
        'contentVersion': '2026.07.1',
        'sha256': c.sha256.convert(bytes).toString(),
        'signature': _hex(signature.bytes),
      });
    });

    test('accepts valid signature', () async {
      final result = await verifyBundle(
          bundleBytes: bytes,
          versionJson: versionJson,
          publicKeyHex: publicKeyHex);
      expect(result.isOk, isTrue);
    });

    test('rejects tampered bundle bytes', () async {
      final tampered = [...bytes, 32];
      final result = await verifyBundle(
          bundleBytes: tampered,
          versionJson: versionJson,
          publicKeyHex: publicKeyHex);
      expect(result.isOk, isFalse);
    });

    test('rejects signature from a different key', () async {
      final otherKey = await Ed25519().newKeyPair();
      final otherPub = await otherKey.extractPublicKey();
      final result = await verifyBundle(
          bundleBytes: bytes,
          versionJson: versionJson,
          publicKeyHex: _hex(otherPub.bytes));
      expect(result.isOk, isFalse);
    });
  });
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

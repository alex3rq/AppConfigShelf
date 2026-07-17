import 'dart:convert';

import 'package:crypto/crypto.dart' as c;
import 'package:cryptography/cryptography.dart';
import 'package:shelf_core/shelf_core.dart';

/// Ed25519 public key (hex) that db release bundles must be signed with.
/// The matching private key lives only in the database repo's CI secret.
const dbReleasePublicKeyHex =
    'ae085a8db9da1f59e28ddae74d77d41883a82e4d8b2a52f1201b6314749610b7';

/// Verifies a downloaded bundle against its `db-version.json` metadata:
/// sha256 integrity first, then the Ed25519 signature with the pinned key.
/// The version file's own `publicKey` field is informational only and is
/// deliberately ignored — trusting it would defeat the pinning.
Future<Result<void>> verifyBundle({
  required List<int> bundleBytes,
  required String versionJson,
  String publicKeyHex = dbReleasePublicKeyHex,
}) async {
  final Map<String, Object?> version;
  try {
    version = jsonDecode(versionJson) as Map<String, Object?>;
  } on Object {
    return const Result.err(ParseFailure('db-version.json is not valid JSON'));
  }

  final expectedSha = version['sha256'] as String?;
  final signatureHex = version['signature'] as String?;
  if (expectedSha == null || signatureHex == null) {
    return const Result.err(
        ParseFailure('db-version.json missing sha256 or signature'));
  }

  final actualSha = c.sha256.convert(bundleBytes).toString();
  if (actualSha != expectedSha) {
    return Result.err(HashMismatchFailure('db bundle integrity check failed',
        path: 'db.json', expected: expectedSha, actual: actualSha));
  }

  final algorithm = Ed25519();
  final valid = await algorithm.verify(
    bundleBytes,
    signature: Signature(
      _fromHex(signatureHex),
      publicKey: SimplePublicKey(_fromHex(publicKeyHex),
          type: KeyPairType.ed25519),
    ),
  );
  if (!valid) {
    return const Result.err(
        ParseFailure('db bundle signature invalid — refusing update'));
  }
  return const Result.ok(null);
}

List<int> _fromHex(String hex) => [
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ];

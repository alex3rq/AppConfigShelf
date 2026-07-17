// One-time Ed25519 keypair generation for db release signing.
// Prints the public key (pin in shelf_db) and writes the private seed to the
// given file (keep out of git; add as the DB_SIGNING_KEY GitHub secret).
// Usage: dart run bin/generate_keypair.dart <private-key-out-file>
import 'dart:io';

import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  final outPath = args.first;
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final seed = await keyPair.extractPrivateKeyBytes();
  final publicKey = await keyPair.extractPublicKey();

  final file = File(outPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(_hex(seed));
  stdout.writeln('private key seed written to $outPath — keep it secret');
  stdout.writeln('public key (pin in shelf_db): ${_hex(publicKey.bytes)}');
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

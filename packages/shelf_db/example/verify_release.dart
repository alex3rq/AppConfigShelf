// Verifies a downloaded release bundle against the pinned public key —
// the exact check the app performs.
// Usage: dart run example/verify_release.dart <db.json> <db-version.json>
import 'dart:io';

import 'package:shelf_db/shelf_db.dart';

Future<void> main(List<String> args) async {
  final bytes = File(args[0]).readAsBytesSync();
  final versionJson = File(args[1]).readAsStringSync();

  final result =
      await verifyBundle(bundleBytes: bytes, versionJson: versionJson);
  if (!result.isOk) {
    print('VERIFICATION FAILED: ${result.failureOrNull}');
    exitCode = 1;
    return;
  }
  final bundle = DbBundle.parse(String.fromCharCodes(bytes)).valueOrNull!;
  print('SIGNATURE VALID (pinned key) — '
      '${bundle.entries.length} entries, content ${bundle.contentVersion}');
}

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf_core/shelf_core.dart';

import 'bundle.dart';
import 'verifier.dart';

const _releasesLatestUrl =
    'https://api.github.com/repos/alex3rq/AppConfigShelf-DB/releases/latest';

/// Result of an update check.
sealed class UpdateOutcome {
  const UpdateOutcome();
}

final class UpToDate extends UpdateOutcome {
  const UpToDate(this.currentVersion);
  final String currentVersion;
}

final class Updated extends UpdateOutcome {
  const Updated(this.newVersion);
  final String newVersion;
}

final class UpdateFailed extends UpdateOutcome {
  const UpdateFailed(this.failure);
  final ShelfFailure failure;
}

/// Loads the best available database and checks GitHub Releases for signed
/// updates, caching them under [cacheDir].
final class DbManager {
  DbManager({required this.cacheDir, http.Client? client})
      : _client = client ?? http.Client();

  final String cacheDir;
  final http.Client _client;

  String get _cachedBundlePath => '$cacheDir\\db.json';
  String get _cachedVersionPath => '$cacheDir\\db-version.json';

  /// Loads the cached (previously verified) bundle if present and valid;
  /// otherwise falls back to [bundledJson] (the copy shipped inside the app).
  DbBundle loadBest({required String bundledJson}) {
    final cached = File(_cachedBundlePath);
    if (cached.existsSync()) {
      final parsed = DbBundle.parse(cached.readAsStringSync());
      final bundle = parsed.valueOrNull;
      if (bundle != null) return bundle;
    }
    final fallback = DbBundle.parse(bundledJson).valueOrNull;
    if (fallback == null) {
      throw StateError('bundled database is invalid — broken build');
    }
    return fallback;
  }

  /// Checks the latest release; downloads, verifies (sha256 + Ed25519
  /// signature against the pinned key), and caches a newer bundle.
  Future<UpdateOutcome> checkForUpdate({required String currentVersion}) async {
    try {
      final releaseResponse = await _client.get(
        Uri.parse(_releasesLatestUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      );
      if (releaseResponse.statusCode == 404) {
        return const UpdateFailed(ParseFailure('no db releases published yet'));
      }
      if (releaseResponse.statusCode != 200) {
        return UpdateFailed(ParseFailure(
            'release check failed: HTTP ${releaseResponse.statusCode}'));
      }
      final release =
          jsonDecode(releaseResponse.body) as Map<String, Object?>;
      final assets = (release['assets'] as List<Object?>? ?? [])
          .cast<Map<String, Object?>>();
      String? urlOf(String name) => assets
          .where((a) => a['name'] == name)
          .map((a) => a['browser_download_url'] as String?)
          .firstOrNull;

      final versionUrl = urlOf('db-version.json');
      final bundleUrl = urlOf('db.json');
      if (versionUrl == null || bundleUrl == null) {
        return const UpdateFailed(
            ParseFailure('release is missing db.json or db-version.json'));
      }

      final versionJson =
          (await _client.get(Uri.parse(versionUrl))).body;
      final versionInfo = jsonDecode(versionJson) as Map<String, Object?>;
      final remoteVersion = versionInfo['contentVersion'] as String? ?? '';
      if (remoteVersion == currentVersion) {
        return UpToDate(currentVersion);
      }

      final bundleBytes =
          (await _client.get(Uri.parse(bundleUrl))).bodyBytes;
      final verification = await verifyBundle(
          bundleBytes: bundleBytes, versionJson: versionJson);
      if (!verification.isOk) {
        return UpdateFailed(verification.failureOrNull!);
      }
      // Confirm it parses before caching — a signed-but-unreadable bundle
      // must not brick the local cache.
      final parsed = DbBundle.parse(utf8.decode(bundleBytes));
      if (!parsed.isOk) {
        return UpdateFailed(parsed.failureOrNull!);
      }

      Directory(cacheDir).createSync(recursive: true);
      File(_cachedBundlePath).writeAsBytesSync(bundleBytes, flush: true);
      File(_cachedVersionPath).writeAsStringSync(versionJson, flush: true);
      return Updated(remoteVersion);
    } on SocketException catch (e) {
      return UpdateFailed(ParseFailure('network error: ${e.message}'));
    } on Object catch (e) {
      return UpdateFailed(ParseFailure('update check failed: $e'));
    }
  }
}

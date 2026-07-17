import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:shelf_core/shelf_core.dart';

import 'manifest.dart';

/// Highest `.acshelf` format version this build can read. Readers must keep
/// support for every version ≤ this forever (ADR-002).
const supportedFormatVersion = 1;

/// An opened `.acshelf` package. Wraps the zip and its parsed manifest.
final class PackageReader {
  PackageReader._(this.manifest, this._archive, this.path);

  final PackageManifest manifest;
  final Archive _archive;
  final String path;

  /// Opens and validates a package. Fails (as a value) on missing/invalid
  /// manifest or an unsupported format version.
  static Result<PackageReader> open(String path) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
    } on Object catch (e) {
      return Result.err(ParseFailure('not a readable zip: $e', source: path));
    }

    final manifestFile =
        archive.where((f) => f.name == 'manifest.json').firstOrNull;
    if (manifestFile == null) {
      return Result.err(ParseFailure(
          'no manifest.json — not an .acshelf package or an aborted write',
          source: path));
    }
    final PackageManifest manifest;
    try {
      manifest = PackageManifest.fromJson(
          jsonDecode(utf8.decode(manifestFile.content))
              as Map<String, Object?>);
    } on Object catch (e) {
      return Result.err(ParseFailure('invalid manifest: $e', source: path));
    }
    if (manifest.formatVersion > supportedFormatVersion) {
      return Result.err(ParseFailure(
          'package format v${manifest.formatVersion} is newer than this app '
          'supports (v$supportedFormatVersion) — update AppConfigShelf',
          source: path));
    }
    return Result.ok(PackageReader._(manifest, archive, path));
  }

  /// Raw bytes of an archived file, or null when absent.
  List<int>? readFile(String storedPath) {
    final file = _archive.where((f) => f.name == storedPath).firstOrNull;
    return file?.content;
  }
}

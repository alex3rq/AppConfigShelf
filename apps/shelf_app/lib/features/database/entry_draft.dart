import 'package:shelf_core/shelf_core.dart';

/// Builds a contributor-facing YAML draft of an entry, ready to paste into
/// a new file under apps/ in the AppConfigShelf-DB repository.
String buildYamlDraft(AppEntry entry) {
  String esc(String path) => path.replaceAll(r'\', r'\\');
  final buffer = StringBuffer()
    ..writeln('id: ${entry.id}')
    ..writeln('name: ${entry.name}');
  if (entry.publisher != null) buffer.writeln('publisher: ${entry.publisher}');
  if (entry.aliases.isNotEmpty) {
    buffer.writeln('aliases: [${entry.aliases.join(', ')}]');
  }
  buffer.writeln('detect:');
  for (final rule in entry.detect) {
    switch (rule) {
      case PathDetection(:final path):
        buffer.writeln('  - path: "${esc(path.stored)}"');
      case RegistryDetection(:final keyPath):
        buffer.writeln('  - registry: $keyPath');
      case MsixDetection(:final packageFamilyName):
        buffer.writeln('  - msix: $packageFamilyName');
    }
  }
  buffer.writeln('backup:');
  for (final rule in entry.backup) {
    buffer.writeln('  - path: "${esc(rule.path.stored)}"');
    if (rule.include.isNotEmpty) {
      buffer.writeln(
          '    include: [${rule.include.map((g) => '"$g"').join(', ')}]');
    }
    if (rule.exclude.isNotEmpty) {
      buffer.writeln(
          '    exclude: [${rule.exclude.map((g) => '"$g"').join(', ')}]');
    }
    if (rule.optional) buffer.writeln('    optional: true');
  }
  if (entry.wingetId != null) buffer.writeln('winget: ${entry.wingetId}');
  buffer
    ..writeln('risk: ${entry.risk.name}')
    ..writeln('origin: original');
  return buffer.toString();
}

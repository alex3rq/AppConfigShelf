/// Human-readable byte size, e.g. "1.2 GB", "84 MB", "40 KB".
String formatBytes(int bytes) {
  if (bytes >= 1 << 30) {
    return '${(bytes / (1 << 30)).toStringAsFixed(1)} GB';
  }
  if (bytes >= 1 << 20) return '${(bytes / (1 << 20)).round()} MB';
  if (bytes >= 1 << 10) return '${(bytes / (1 << 10)).round()} KB';
  return '$bytes B';
}

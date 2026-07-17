import 'manifest.dart';

/// Progress events streamed by the backup writer. The UI renders these;
/// nothing here is Flutter-specific.
sealed class BackupEvent {
  const BackupEvent();
}

final class EntryStarted extends BackupEvent {
  const EntryStarted(this.entryId, this.name, this.fileCount);
  final String entryId;
  final String name;
  final int fileCount;
}

final class FileBackedUp extends BackupEvent {
  const FileBackedUp(this.entryId, this.targetPath, this.filesDone, this.filesTotal);
  final String entryId;
  final String targetPath;
  final int filesDone;
  final int filesTotal;
}

final class FileSkipped extends BackupEvent {
  const FileSkipped(this.entryId, this.targetPath, this.reason);
  final String entryId;
  final String targetPath;
  final String reason;
}

final class BackupFinished extends BackupEvent {
  const BackupFinished(this.manifest, this.outputPath);
  final PackageManifest manifest;
  final String outputPath;
}

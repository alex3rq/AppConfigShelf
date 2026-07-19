// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AppConfigShelf';

  @override
  String get appTagline => 'Back up your apps';

  @override
  String get navHome => 'Home';

  @override
  String get navApplications => 'Applications';

  @override
  String get navBackup => 'Backup';

  @override
  String get navRestore => 'Restore';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSettings => 'Settings';

  @override
  String get statusDbLoading => 'Database loading…';

  @override
  String statusDb(String version, int count) {
    return 'Db v$version · $count entries';
  }

  @override
  String get statusNoBackups => 'No backups yet';

  @override
  String statusLastBackup(String when) {
    return 'Last backup $when';
  }

  @override
  String get relativeToday => 'today';

  @override
  String get relativeYesterday => 'yesterday';

  @override
  String relativeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String relativeDaysAgoShort(int days) {
    return '${days}d ago';
  }

  @override
  String get homeSlogan => 'Reinstall Windows. Not your workflow.';

  @override
  String get scanThisPc => 'Scan this PC';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get homeScanPrompt =>
      'Scan this PC to see which of your installed apps AppConfigShelf can back up.';

  @override
  String get homeScanning => 'Scanning this PC…';

  @override
  String get statAppsFound => 'apps found on this PC';

  @override
  String get statRecognized => 'recognized by the database';

  @override
  String get statUnknown => 'unknown apps worth a look';

  @override
  String get viewApplications => 'View applications';

  @override
  String get readyToBackUp => 'Ready to back up';

  @override
  String get review => 'Review';

  @override
  String get backupCardTitle => 'Back up this PC';

  @override
  String get backupCardBody =>
      'Pick the apps and folders that matter, get one portable .acshelf file you can carry through a reinstall.';

  @override
  String get startBackup => 'Start backup';

  @override
  String get restoreCardTitle => 'Restore a backup';

  @override
  String get restoreCardBody =>
      'Open an .acshelf file from this or another machine and bring everything back — all of it, or just the parts you choose.';

  @override
  String get openBackupAction => 'Open backup…';

  @override
  String get timelineTitle => 'Safety timeline';

  @override
  String get timelineSubtitle =>
      'Every backup and undo bundle this PC has produced — open any of them like a backup.';

  @override
  String get openAFile => 'Open a file…';

  @override
  String get timelineEmpty => 'Nothing yet — your first backup will show here.';

  @override
  String get timelineBackupCreated => 'Backup created';

  @override
  String get timelineUndoKept => 'Undo bundle kept';

  @override
  String get open => 'Open';

  @override
  String get rollBack => 'Roll back';

  @override
  String get appsSubtitle =>
      'Everything the scan found, and what the database knows about it.';

  @override
  String get scanSystem => 'Scan system';

  @override
  String get runScanPrompt => 'Run a scan to detect installed applications.';

  @override
  String scanFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String chipFound(int count) {
    return '$count found';
  }

  @override
  String chipRecognized(int count) {
    return '$count recognized';
  }

  @override
  String chipNotInDb(int count) {
    return '$count not in database';
  }

  @override
  String chipHidden(int count) {
    return '$count hidden';
  }

  @override
  String recognizedSection(int count) {
    return 'Recognized ($count)';
  }

  @override
  String get addAllToBackup => 'Add all to backup';

  @override
  String get addToBackup => 'Add to backup';

  @override
  String matchPercent(int percent) {
    return 'match $percent%';
  }

  @override
  String notInDbSection(int count) {
    return 'Not in database yet ($count)';
  }

  @override
  String get teachPrompt =>
      'Teach AppConfigShelf where these keep their settings';

  @override
  String get findConfig => 'Find config…';

  @override
  String get hide => 'Hide';

  @override
  String hiddenSection(int count) {
    return 'Hidden ($count)';
  }

  @override
  String hiddenSummary(int user, int official) {
    return '$user hidden by you · $official system components ignored by database rules';
  }

  @override
  String get hiddenByYou => 'hidden by you';

  @override
  String get unhide => 'Unhide';

  @override
  String get systemComponentIgnored =>
      'system component — matched a database ignore rule';

  @override
  String get unnamed => '(unnamed)';

  @override
  String get backupTitle => 'Back up';

  @override
  String get backupSubtitle =>
      'Choose what travels with you. Nothing is written until you confirm.';

  @override
  String get backupSubtitleRunning =>
      'Writing your backup — you can keep using this PC.';

  @override
  String get stepSelect => 'Select';

  @override
  String get stepBackUp => 'Back up';

  @override
  String get stepDone => 'Done';

  @override
  String get stepOpen => 'Open';

  @override
  String detectedAppsSelected(int selected, int total) {
    return 'Detected applications — $selected of $total selected';
  }

  @override
  String get filterApps => 'Filter apps';

  @override
  String get backupScanCtaTitle => 'See what\'s on this PC first';

  @override
  String get backupScanCtaBody =>
      'A quick scan finds your installed apps so you can pick which ones to back up.';

  @override
  String get scanApplications => 'Scan applications';

  @override
  String get customItemsSection =>
      'Custom items — restored to their original paths';

  @override
  String get addFolderAction => 'Add folder…';

  @override
  String get customItemsEmpty =>
      'Add any folder or file to back up, even if no app is detected. Custom items are always restored to their original location.';

  @override
  String get remove => 'Remove';

  @override
  String footerSummary(int apps, int items) {
    return '$apps apps · $items custom items';
  }

  @override
  String cautionSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count caution/expert items selected — review before restoring on another PC',
      one:
          '1 caution/expert item selected — review before restoring on another PC',
    );
    return '$_temp0';
  }

  @override
  String get footerNote =>
      'Writes one .acshelf file · nothing on this PC is changed';

  @override
  String get backUpSelection => 'Back up selection';

  @override
  String backingUpEntry(String entry) {
    return 'Backing up $entry…';
  }

  @override
  String filesProgress(int done, int total) {
    return '$done of $total files';
  }

  @override
  String get lockedFilesNote =>
      'Files locked by running apps are skipped safely and listed in the report.';

  @override
  String get backupComplete => 'Backup complete';

  @override
  String reportTotals(int entries, int files, String size) {
    return '$entries entries · $files files · $size';
  }

  @override
  String get savedTo => 'Saved to';

  @override
  String get openFolder => 'Open folder';

  @override
  String filesAndSize(int files, String size) {
    return '$files files · $size';
  }

  @override
  String customSuffix(String name) {
    return '$name (custom)';
  }

  @override
  String skippedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files skipped',
      one: '1 file skipped',
    );
    return '$_temp0';
  }

  @override
  String get newBackup => 'New backup';

  @override
  String get goHome => 'Go home';

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get back => 'Back';

  @override
  String get restoreSubtitle =>
      'Nothing is touched until you press Restore — and everything replaced can be rolled back.';

  @override
  String get restoreOpenPrompt =>
      'Open an .acshelf backup package to begin restoring.';

  @override
  String get chooseAnotherFile => 'Choose another file…';

  @override
  String packageInfo(String host, String date, String version, int count) {
    return 'From $host · created $date · app v$version · $count entries';
  }

  @override
  String get conflictQuestion => 'If a file already exists on this PC';

  @override
  String get replaceExisting => 'Replace existing';

  @override
  String get replaceExistingBody =>
      'Current files are copied into an undo bundle first — you can roll the whole restore back.';

  @override
  String get keepExisting => 'Keep existing';

  @override
  String get keepExistingBody =>
      'Only files missing on this PC are restored. Nothing is overwritten, no undo bundle needed.';

  @override
  String get applicationsSection => 'Applications';

  @override
  String get selectAllRestorable => 'Select all restorable';

  @override
  String get customItemsTitle => 'Custom items';

  @override
  String nFiles(int count) {
    return '$count files';
  }

  @override
  String get appNotInstalled => 'app not installed';

  @override
  String get notInDbRestores => 'not in database — restores to recorded paths';

  @override
  String existingReplaced(int count) {
    return '$count existing will be replaced';
  }

  @override
  String selectionSummary(int selected, int total) {
    return '$selected of $total entries selected';
  }

  @override
  String selectionConflicts(int count) {
    return ' · $count existing files will be replaced';
  }

  @override
  String get undoNotice =>
      'An undo bundle is saved before anything is replaced';

  @override
  String restoreEntries(int count) {
    return 'Restore $count entries';
  }

  @override
  String restoreProgress(String entry, int count) {
    return '$entry — $count files restored';
  }

  @override
  String get restoreComplete => 'Restore complete';

  @override
  String get restoreProblems => 'Restore finished with problems';

  @override
  String restoredStats(int count) {
    return '$count files restored';
  }

  @override
  String keptNewer(int count) {
    return ' · $count kept (newer on this PC)';
  }

  @override
  String get undoSavedTitle =>
      'Undo bundle saved — this restore can be rolled back';

  @override
  String get undoSavedBody =>
      'Open it like any backup to return this PC to exactly how it was before the restore.';

  @override
  String get rollBackNow => 'Roll back now…';

  @override
  String get showInFolder => 'Show in folder';

  @override
  String entryHalted(String entry) {
    return '$entry — halted';
  }

  @override
  String get done => 'Done';

  @override
  String get openAnotherBackup => 'Open another backup';

  @override
  String get librarySubtitle =>
      'The official app database, plus your own entries. Yours always win when they overlap.';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String versionSigned(String version) {
    return 'v$version · signed';
  }

  @override
  String get upToDateTitle => 'Up to date';

  @override
  String upToDateBody(String version) {
    return 'Version $version is current.';
  }

  @override
  String get dbUpdatedTitle => 'Database updated';

  @override
  String dbUpdatedBody(String version) {
    return 'Now using version $version.';
  }

  @override
  String get updateFailedTitle => 'Update check failed';

  @override
  String dbLoadFailed(String error) {
    return 'Failed to load database: $error';
  }

  @override
  String searchEntries(int count) {
    return 'Search $count entries';
  }

  @override
  String filterAll(int count) {
    return 'All $count';
  }

  @override
  String filterMine(int count) {
    return 'My library $count';
  }

  @override
  String filterOfficial(int count) {
    return 'Official $count';
  }

  @override
  String get skippedInvalidEntry => 'Skipped invalid entry file';

  @override
  String get noEntriesMatch => 'No entries match.';

  @override
  String get exportYaml => 'Export YAML…';

  @override
  String get resetToOfficial => 'Reset to official';

  @override
  String get deleteEntry => 'Delete entry';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get customizedBannerTitle => 'Your customized copy.';

  @override
  String get customizedBannerBody =>
      'Scanning and backups use this instead of the official entry.';

  @override
  String get localBannerTitle => 'Local entry.';

  @override
  String get localBannerBody =>
      'Created on this PC — export a YAML draft to contribute it to the official database.';

  @override
  String get detectionSection => 'Detection';

  @override
  String get detectionActiveNote =>
      'Entry is active only when detection matches';

  @override
  String backupLocationsSection(int count) {
    return 'Backup locations ($count)';
  }

  @override
  String get chipOptional => 'optional';

  @override
  String get chipLarge => 'large';

  @override
  String get includeLabel => 'Include';

  @override
  String get excludeLabel => 'Exclude';

  @override
  String get yamlExportedTitle => 'YAML exported';

  @override
  String yamlExportedBody(String path) {
    return 'Saved to $path. Add it under apps/ in the AppConfigShelf-DB repository and open a pull request.';
  }

  @override
  String registryDetection(String key) {
    return 'Registry: $key';
  }

  @override
  String msixDetection(String name) {
    return 'MSIX package: $name';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Appearance and language.';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'Follow Windows setting';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get languageSection => 'Language';

  @override
  String get languageLabel => 'App language';

  @override
  String get languageSystem => 'Follow Windows setting';

  @override
  String get langEnglish => 'English';

  @override
  String get langSpanish => 'Español (Latinoamérica)';

  @override
  String findConfigTitle(String app) {
    return 'Find configuration — $app';
  }

  @override
  String get finderSubtitle =>
      'AppConfigShelf looked in the usual places. Check the folders that hold this app\'s settings.';

  @override
  String get finderNoCandidates =>
      'No likely config folders found under AppData, LocalAppData, or Documents. The app may store settings in the registry or its install folder — you can still pick any folder yourself and back it up as a custom item.';

  @override
  String get addFolderAsCustomItem => 'Add folder as custom item…';

  @override
  String get finderNothingHere =>
      'Nothing here? Settings may live in the registry or the install folder.';

  @override
  String get lowConfidence => 'low confidence';

  @override
  String get close => 'Close';

  @override
  String get editBeforeSaving => 'Edit before saving…';

  @override
  String get saveToMyLibrary => 'Save to my library';

  @override
  String savedToLibraryTitle(String name) {
    return '\"$name\" saved to My library';
  }

  @override
  String get savedToLibraryBody =>
      'Rescanning to pick it up — it will appear under Recognized and in the Backup list in a moment. Edit it any time from the Library tab.';

  @override
  String get customItemAddedTitle => 'Custom item added';

  @override
  String get customItemAddedBody =>
      'The folder is listed under Custom items on the Backup tab and will be included in every backup.';

  @override
  String get unknownApp => 'Unknown app';

  @override
  String get nameThisItem => 'Name this item';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get unsupportedPath => 'Unsupported path';

  @override
  String editEntryTitle(String name) {
    return 'Edit entry — $name';
  }

  @override
  String get editorSubtitle =>
      'Saved to My library only — the official database entry is never modified.';

  @override
  String get displayName => 'Display name';

  @override
  String get detectPath => 'Detect path';

  @override
  String get browse => 'Browse…';

  @override
  String get detectPathNote =>
      'The entry is used only when this file exists on the PC.';

  @override
  String get backupLocations => 'Backup locations';

  @override
  String get folder => 'Folder';

  @override
  String get includePatterns => 'Include patterns';

  @override
  String get excludePatterns => 'Exclude patterns';

  @override
  String get includeHelp =>
      'Patterns like **/*.json — leave empty to include everything';

  @override
  String get excludeHelp => 'Skipped even when matched by Include';

  @override
  String get optionalToggle =>
      'Optional — skip silently when this folder is missing';

  @override
  String get addBackupLocation => '+ Add backup location…';

  @override
  String get cannotSave => 'Cannot save';

  @override
  String issuesToFix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count issues to fix',
      one: '1 issue to fix',
    );
    return '$_temp0';
  }

  @override
  String get outsideSupportedFile =>
      'That file is outside the supported locations (AppData, LocalAppData, ProgramData, user profile, Documents).';

  @override
  String get outsideSupportedFolder =>
      'That folder is outside the supported locations (AppData, LocalAppData, ProgramData, user profile, Documents). Use a custom item on the Backup tab for arbitrary folders.';

  @override
  String get chipSafe => 'Safe';

  @override
  String get chipCaution => 'Caution';

  @override
  String get chipExpert => 'Expert';

  @override
  String get chipLocal => 'local';

  @override
  String get chipCustomized => 'customized';

  @override
  String get chipOfficial => 'official';

  @override
  String get runScanFirst => 'Run a scan first (Applications tab).';
}

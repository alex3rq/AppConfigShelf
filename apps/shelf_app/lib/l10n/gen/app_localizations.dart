import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AppConfigShelf'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Back up your apps'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get navApplications;

  /// No description provided for @navBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get navBackup;

  /// No description provided for @navRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get navRestore;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @statusDbLoading.
  ///
  /// In en, this message translates to:
  /// **'Database loading…'**
  String get statusDbLoading;

  /// No description provided for @statusDb.
  ///
  /// In en, this message translates to:
  /// **'Db v{version} · {count} entries'**
  String statusDb(String version, int count);

  /// No description provided for @statusNoBackups.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get statusNoBackups;

  /// No description provided for @statusLastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup {when}'**
  String statusLastBackup(String when);

  /// No description provided for @relativeToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get relativeToday;

  /// No description provided for @relativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get relativeYesterday;

  /// No description provided for @relativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String relativeDaysAgo(int days);

  /// No description provided for @relativeDaysAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String relativeDaysAgoShort(int days);

  /// No description provided for @homeSlogan.
  ///
  /// In en, this message translates to:
  /// **'Reinstall Windows. Not your workflow.'**
  String get homeSlogan;

  /// No description provided for @scanThisPc.
  ///
  /// In en, this message translates to:
  /// **'Scan this PC'**
  String get scanThisPc;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @homeScanPrompt.
  ///
  /// In en, this message translates to:
  /// **'Scan this PC to see which of your installed apps AppConfigShelf can back up.'**
  String get homeScanPrompt;

  /// No description provided for @homeScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning this PC…'**
  String get homeScanning;

  /// No description provided for @statAppsFound.
  ///
  /// In en, this message translates to:
  /// **'apps found on this PC'**
  String get statAppsFound;

  /// No description provided for @statRecognized.
  ///
  /// In en, this message translates to:
  /// **'recognized by the database'**
  String get statRecognized;

  /// No description provided for @statUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown apps worth a look'**
  String get statUnknown;

  /// No description provided for @viewApplications.
  ///
  /// In en, this message translates to:
  /// **'View applications'**
  String get viewApplications;

  /// No description provided for @readyToBackUp.
  ///
  /// In en, this message translates to:
  /// **'Ready to back up'**
  String get readyToBackUp;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @backupCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up this PC'**
  String get backupCardTitle;

  /// No description provided for @backupCardBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the apps and folders that matter, get one portable .acshelf file you can carry through a reinstall.'**
  String get backupCardBody;

  /// No description provided for @startBackup.
  ///
  /// In en, this message translates to:
  /// **'Start backup'**
  String get startBackup;

  /// No description provided for @restoreCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get restoreCardTitle;

  /// No description provided for @restoreCardBody.
  ///
  /// In en, this message translates to:
  /// **'Open an .acshelf file from this or another machine and bring everything back — all of it, or just the parts you choose.'**
  String get restoreCardBody;

  /// No description provided for @openBackupAction.
  ///
  /// In en, this message translates to:
  /// **'Open backup…'**
  String get openBackupAction;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety timeline'**
  String get timelineTitle;

  /// No description provided for @timelineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every backup and undo bundle this PC has produced — open any of them like a backup.'**
  String get timelineSubtitle;

  /// No description provided for @openAFile.
  ///
  /// In en, this message translates to:
  /// **'Open a file…'**
  String get openAFile;

  /// No description provided for @timelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet — your first backup will show here.'**
  String get timelineEmpty;

  /// No description provided for @timelineBackupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get timelineBackupCreated;

  /// No description provided for @timelineUndoKept.
  ///
  /// In en, this message translates to:
  /// **'Undo bundle kept'**
  String get timelineUndoKept;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @rollBack.
  ///
  /// In en, this message translates to:
  /// **'Roll back'**
  String get rollBack;

  /// No description provided for @appsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything the scan found, and what the database knows about it.'**
  String get appsSubtitle;

  /// No description provided for @scanSystem.
  ///
  /// In en, this message translates to:
  /// **'Scan system'**
  String get scanSystem;

  /// No description provided for @runScanPrompt.
  ///
  /// In en, this message translates to:
  /// **'Run a scan to detect installed applications.'**
  String get runScanPrompt;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {error}'**
  String scanFailed(String error);

  /// No description provided for @chipFound.
  ///
  /// In en, this message translates to:
  /// **'{count} found'**
  String chipFound(int count);

  /// No description provided for @chipRecognized.
  ///
  /// In en, this message translates to:
  /// **'{count} recognized'**
  String chipRecognized(int count);

  /// No description provided for @chipNotInDb.
  ///
  /// In en, this message translates to:
  /// **'{count} not in database'**
  String chipNotInDb(int count);

  /// No description provided for @chipHidden.
  ///
  /// In en, this message translates to:
  /// **'{count} hidden'**
  String chipHidden(int count);

  /// No description provided for @recognizedSection.
  ///
  /// In en, this message translates to:
  /// **'Recognized ({count})'**
  String recognizedSection(int count);

  /// No description provided for @addAllToBackup.
  ///
  /// In en, this message translates to:
  /// **'Add all to backup'**
  String get addAllToBackup;

  /// No description provided for @addToBackup.
  ///
  /// In en, this message translates to:
  /// **'Add to backup'**
  String get addToBackup;

  /// No description provided for @matchPercent.
  ///
  /// In en, this message translates to:
  /// **'match {percent}%'**
  String matchPercent(int percent);

  /// No description provided for @notInDbSection.
  ///
  /// In en, this message translates to:
  /// **'Not in database yet ({count})'**
  String notInDbSection(int count);

  /// No description provided for @teachPrompt.
  ///
  /// In en, this message translates to:
  /// **'Teach AppConfigShelf where these keep their settings'**
  String get teachPrompt;

  /// No description provided for @findConfig.
  ///
  /// In en, this message translates to:
  /// **'Find config…'**
  String get findConfig;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @hiddenSection.
  ///
  /// In en, this message translates to:
  /// **'Hidden ({count})'**
  String hiddenSection(int count);

  /// No description provided for @hiddenSummary.
  ///
  /// In en, this message translates to:
  /// **'{user} hidden by you · {official} system components ignored by database rules'**
  String hiddenSummary(int user, int official);

  /// No description provided for @hiddenByYou.
  ///
  /// In en, this message translates to:
  /// **'hidden by you'**
  String get hiddenByYou;

  /// No description provided for @unhide.
  ///
  /// In en, this message translates to:
  /// **'Unhide'**
  String get unhide;

  /// No description provided for @systemComponentIgnored.
  ///
  /// In en, this message translates to:
  /// **'system component — matched a database ignore rule'**
  String get systemComponentIgnored;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'(unnamed)'**
  String get unnamed;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up'**
  String get backupTitle;

  /// No description provided for @backupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what travels with you. Nothing is written until you confirm.'**
  String get backupSubtitle;

  /// No description provided for @backupSubtitleRunning.
  ///
  /// In en, this message translates to:
  /// **'Writing your backup — you can keep using this PC.'**
  String get backupSubtitleRunning;

  /// No description provided for @stepSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get stepSelect;

  /// No description provided for @stepBackUp.
  ///
  /// In en, this message translates to:
  /// **'Back up'**
  String get stepBackUp;

  /// No description provided for @stepDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stepDone;

  /// No description provided for @stepOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get stepOpen;

  /// No description provided for @detectedAppsSelected.
  ///
  /// In en, this message translates to:
  /// **'Detected applications — {selected} of {total} selected'**
  String detectedAppsSelected(int selected, int total);

  /// No description provided for @filterApps.
  ///
  /// In en, this message translates to:
  /// **'Filter apps'**
  String get filterApps;

  /// No description provided for @backupScanCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'See what\'s on this PC first'**
  String get backupScanCtaTitle;

  /// No description provided for @backupScanCtaBody.
  ///
  /// In en, this message translates to:
  /// **'A quick scan finds your installed apps so you can pick which ones to back up.'**
  String get backupScanCtaBody;

  /// No description provided for @scanApplications.
  ///
  /// In en, this message translates to:
  /// **'Scan applications'**
  String get scanApplications;

  /// No description provided for @customItemsSection.
  ///
  /// In en, this message translates to:
  /// **'Custom items — restored to their original paths'**
  String get customItemsSection;

  /// No description provided for @addFolderAction.
  ///
  /// In en, this message translates to:
  /// **'Add folder…'**
  String get addFolderAction;

  /// No description provided for @customItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add any folder or file to back up, even if no app is detected. Custom items are always restored to their original location.'**
  String get customItemsEmpty;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @footerSummary.
  ///
  /// In en, this message translates to:
  /// **'{apps} apps · {items} custom items'**
  String footerSummary(int apps, int items);

  /// No description provided for @cautionSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 caution/expert item selected — review before restoring on another PC} other{{count} caution/expert items selected — review before restoring on another PC}}'**
  String cautionSelected(int count);

  /// No description provided for @footerNote.
  ///
  /// In en, this message translates to:
  /// **'Writes one .acshelf file · nothing on this PC is changed'**
  String get footerNote;

  /// No description provided for @backUpSelection.
  ///
  /// In en, this message translates to:
  /// **'Back up selection'**
  String get backUpSelection;

  /// No description provided for @backingUpEntry.
  ///
  /// In en, this message translates to:
  /// **'Backing up {entry}…'**
  String backingUpEntry(String entry);

  /// No description provided for @filesProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} files'**
  String filesProgress(int done, int total);

  /// No description provided for @lockedFilesNote.
  ///
  /// In en, this message translates to:
  /// **'Files locked by running apps are skipped safely and listed in the report.'**
  String get lockedFilesNote;

  /// No description provided for @backupComplete.
  ///
  /// In en, this message translates to:
  /// **'Backup complete'**
  String get backupComplete;

  /// No description provided for @reportTotals.
  ///
  /// In en, this message translates to:
  /// **'{entries} entries · {files} files · {size}'**
  String reportTotals(int entries, int files, String size);

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to'**
  String get savedTo;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @filesAndSize.
  ///
  /// In en, this message translates to:
  /// **'{files} files · {size}'**
  String filesAndSize(int files, String size);

  /// No description provided for @customSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (custom)'**
  String customSuffix(String name);

  /// No description provided for @skippedFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 file skipped} other{{count} files skipped}}'**
  String skippedFiles(int count);

  /// No description provided for @newBackup.
  ///
  /// In en, this message translates to:
  /// **'New backup'**
  String get newBackup;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get goHome;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @restoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing is touched until you press Restore — and everything replaced can be rolled back.'**
  String get restoreSubtitle;

  /// No description provided for @restoreOpenPrompt.
  ///
  /// In en, this message translates to:
  /// **'Open an .acshelf backup package to begin restoring.'**
  String get restoreOpenPrompt;

  /// No description provided for @chooseAnotherFile.
  ///
  /// In en, this message translates to:
  /// **'Choose another file…'**
  String get chooseAnotherFile;

  /// No description provided for @packageInfo.
  ///
  /// In en, this message translates to:
  /// **'From {host} · created {date} · app v{version} · {count} entries'**
  String packageInfo(String host, String date, String version, int count);

  /// No description provided for @conflictQuestion.
  ///
  /// In en, this message translates to:
  /// **'If a file already exists on this PC'**
  String get conflictQuestion;

  /// No description provided for @replaceExisting.
  ///
  /// In en, this message translates to:
  /// **'Replace existing'**
  String get replaceExisting;

  /// No description provided for @replaceExistingBody.
  ///
  /// In en, this message translates to:
  /// **'Current files are copied into an undo bundle first — you can roll the whole restore back.'**
  String get replaceExistingBody;

  /// No description provided for @keepExisting.
  ///
  /// In en, this message translates to:
  /// **'Keep existing'**
  String get keepExisting;

  /// No description provided for @keepExistingBody.
  ///
  /// In en, this message translates to:
  /// **'Only files missing on this PC are restored. Nothing is overwritten, no undo bundle needed.'**
  String get keepExistingBody;

  /// No description provided for @applicationsSection.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applicationsSection;

  /// No description provided for @selectAllRestorable.
  ///
  /// In en, this message translates to:
  /// **'Select all restorable'**
  String get selectAllRestorable;

  /// No description provided for @customItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom items'**
  String get customItemsTitle;

  /// No description provided for @nFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String nFiles(int count);

  /// No description provided for @appNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'app not installed'**
  String get appNotInstalled;

  /// No description provided for @notInDbRestores.
  ///
  /// In en, this message translates to:
  /// **'not in database — restores to recorded paths'**
  String get notInDbRestores;

  /// No description provided for @existingReplaced.
  ///
  /// In en, this message translates to:
  /// **'{count} existing will be replaced'**
  String existingReplaced(int count);

  /// No description provided for @selectionSummary.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} entries selected'**
  String selectionSummary(int selected, int total);

  /// No description provided for @selectionConflicts.
  ///
  /// In en, this message translates to:
  /// **' · {count} existing files will be replaced'**
  String selectionConflicts(int count);

  /// No description provided for @undoNotice.
  ///
  /// In en, this message translates to:
  /// **'An undo bundle is saved before anything is replaced'**
  String get undoNotice;

  /// No description provided for @restoreEntries.
  ///
  /// In en, this message translates to:
  /// **'Restore {count} entries'**
  String restoreEntries(int count);

  /// No description provided for @restoreProgress.
  ///
  /// In en, this message translates to:
  /// **'{entry} — {count} files restored'**
  String restoreProgress(String entry, int count);

  /// No description provided for @restoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get restoreComplete;

  /// No description provided for @restoreProblems.
  ///
  /// In en, this message translates to:
  /// **'Restore finished with problems'**
  String get restoreProblems;

  /// No description provided for @restoredStats.
  ///
  /// In en, this message translates to:
  /// **'{count} files restored'**
  String restoredStats(int count);

  /// No description provided for @keptNewer.
  ///
  /// In en, this message translates to:
  /// **' · {count} kept (newer on this PC)'**
  String keptNewer(int count);

  /// No description provided for @undoSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo bundle saved — this restore can be rolled back'**
  String get undoSavedTitle;

  /// No description provided for @undoSavedBody.
  ///
  /// In en, this message translates to:
  /// **'Open it like any backup to return this PC to exactly how it was before the restore.'**
  String get undoSavedBody;

  /// No description provided for @rollBackNow.
  ///
  /// In en, this message translates to:
  /// **'Roll back now…'**
  String get rollBackNow;

  /// No description provided for @showInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get showInFolder;

  /// No description provided for @entryHalted.
  ///
  /// In en, this message translates to:
  /// **'{entry} — halted'**
  String entryHalted(String entry);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @openAnotherBackup.
  ///
  /// In en, this message translates to:
  /// **'Open another backup'**
  String get openAnotherBackup;

  /// No description provided for @librarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The official app database, plus your own entries. Yours always win when they overlap.'**
  String get librarySubtitle;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @versionSigned.
  ///
  /// In en, this message translates to:
  /// **'v{version} · signed'**
  String versionSigned(String version);

  /// No description provided for @upToDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get upToDateTitle;

  /// No description provided for @upToDateBody.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is current.'**
  String upToDateBody(String version);

  /// No description provided for @dbUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Database updated'**
  String get dbUpdatedTitle;

  /// No description provided for @dbUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'Now using version {version}.'**
  String dbUpdatedBody(String version);

  /// No description provided for @updateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get updateFailedTitle;

  /// No description provided for @dbLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load database: {error}'**
  String dbLoadFailed(String error);

  /// No description provided for @searchEntries.
  ///
  /// In en, this message translates to:
  /// **'Search {count} entries'**
  String searchEntries(int count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String filterAll(int count);

  /// No description provided for @filterMine.
  ///
  /// In en, this message translates to:
  /// **'My library {count}'**
  String filterMine(int count);

  /// No description provided for @filterOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official {count}'**
  String filterOfficial(int count);

  /// No description provided for @skippedInvalidEntry.
  ///
  /// In en, this message translates to:
  /// **'Skipped invalid entry file'**
  String get skippedInvalidEntry;

  /// No description provided for @noEntriesMatch.
  ///
  /// In en, this message translates to:
  /// **'No entries match.'**
  String get noEntriesMatch;

  /// No description provided for @exportYaml.
  ///
  /// In en, this message translates to:
  /// **'Export YAML…'**
  String get exportYaml;

  /// No description provided for @resetToOfficial.
  ///
  /// In en, this message translates to:
  /// **'Reset to official'**
  String get resetToOfficial;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @customizedBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your customized copy.'**
  String get customizedBannerTitle;

  /// No description provided for @customizedBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Scanning and backups use this instead of the official entry.'**
  String get customizedBannerBody;

  /// No description provided for @localBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Local entry.'**
  String get localBannerTitle;

  /// No description provided for @localBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Created on this PC — export a YAML draft to contribute it to the official database.'**
  String get localBannerBody;

  /// No description provided for @detectionSection.
  ///
  /// In en, this message translates to:
  /// **'Detection'**
  String get detectionSection;

  /// No description provided for @detectionActiveNote.
  ///
  /// In en, this message translates to:
  /// **'Entry is active only when detection matches'**
  String get detectionActiveNote;

  /// No description provided for @backupLocationsSection.
  ///
  /// In en, this message translates to:
  /// **'Backup locations ({count})'**
  String backupLocationsSection(int count);

  /// No description provided for @chipOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get chipOptional;

  /// No description provided for @chipLarge.
  ///
  /// In en, this message translates to:
  /// **'large'**
  String get chipLarge;

  /// No description provided for @includeLabel.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get includeLabel;

  /// No description provided for @excludeLabel.
  ///
  /// In en, this message translates to:
  /// **'Exclude'**
  String get excludeLabel;

  /// No description provided for @yamlExportedTitle.
  ///
  /// In en, this message translates to:
  /// **'YAML exported'**
  String get yamlExportedTitle;

  /// No description provided for @yamlExportedBody.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}. Add it under apps/ in the AppConfigShelf-DB repository and open a pull request.'**
  String yamlExportedBody(String path);

  /// No description provided for @registryDetection.
  ///
  /// In en, this message translates to:
  /// **'Registry: {key}'**
  String registryDetection(String key);

  /// No description provided for @msixDetection.
  ///
  /// In en, this message translates to:
  /// **'MSIX package: {name}'**
  String msixDetection(String name);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance and language.'**
  String get settingsSubtitle;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow Windows setting'**
  String get themeSystem;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow Windows setting'**
  String get languageSystem;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español (Latinoamérica)'**
  String get langSpanish;

  /// No description provided for @findConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Find configuration — {app}'**
  String findConfigTitle(String app);

  /// No description provided for @finderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AppConfigShelf looked in the usual places. Check the folders that hold this app\'s settings.'**
  String get finderSubtitle;

  /// No description provided for @finderNoCandidates.
  ///
  /// In en, this message translates to:
  /// **'No likely config folders found under AppData, LocalAppData, or Documents. The app may store settings in the registry or its install folder — you can still pick any folder yourself and back it up as a custom item.'**
  String get finderNoCandidates;

  /// No description provided for @addFolderAsCustomItem.
  ///
  /// In en, this message translates to:
  /// **'Add folder as custom item…'**
  String get addFolderAsCustomItem;

  /// No description provided for @finderNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here? Settings may live in the registry or the install folder.'**
  String get finderNothingHere;

  /// No description provided for @lowConfidence.
  ///
  /// In en, this message translates to:
  /// **'low confidence'**
  String get lowConfidence;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @editBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Edit before saving…'**
  String get editBeforeSaving;

  /// No description provided for @saveToMyLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to my library'**
  String get saveToMyLibrary;

  /// No description provided for @savedToLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" saved to My library'**
  String savedToLibraryTitle(String name);

  /// No description provided for @savedToLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'Rescanning to pick it up — it will appear under Recognized and in the Backup list in a moment. Edit it any time from the Library tab.'**
  String get savedToLibraryBody;

  /// No description provided for @customItemAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom item added'**
  String get customItemAddedTitle;

  /// No description provided for @customItemAddedBody.
  ///
  /// In en, this message translates to:
  /// **'The folder is listed under Custom items on the Backup tab and will be included in every backup.'**
  String get customItemAddedBody;

  /// No description provided for @unknownApp.
  ///
  /// In en, this message translates to:
  /// **'Unknown app'**
  String get unknownApp;

  /// No description provided for @nameThisItem.
  ///
  /// In en, this message translates to:
  /// **'Name this item'**
  String get nameThisItem;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @unsupportedPath.
  ///
  /// In en, this message translates to:
  /// **'Unsupported path'**
  String get unsupportedPath;

  /// No description provided for @editEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry — {name}'**
  String editEntryTitle(String name);

  /// No description provided for @editorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved to My library only — the official database entry is never modified.'**
  String get editorSubtitle;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @detectPath.
  ///
  /// In en, this message translates to:
  /// **'Detect path'**
  String get detectPath;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse…'**
  String get browse;

  /// No description provided for @detectPathNote.
  ///
  /// In en, this message translates to:
  /// **'The entry is used only when this file exists on the PC.'**
  String get detectPathNote;

  /// No description provided for @backupLocations.
  ///
  /// In en, this message translates to:
  /// **'Backup locations'**
  String get backupLocations;

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @includePatterns.
  ///
  /// In en, this message translates to:
  /// **'Include patterns'**
  String get includePatterns;

  /// No description provided for @excludePatterns.
  ///
  /// In en, this message translates to:
  /// **'Exclude patterns'**
  String get excludePatterns;

  /// No description provided for @includeHelp.
  ///
  /// In en, this message translates to:
  /// **'Patterns like **/*.json — leave empty to include everything'**
  String get includeHelp;

  /// No description provided for @excludeHelp.
  ///
  /// In en, this message translates to:
  /// **'Skipped even when matched by Include'**
  String get excludeHelp;

  /// No description provided for @optionalToggle.
  ///
  /// In en, this message translates to:
  /// **'Optional — skip silently when this folder is missing'**
  String get optionalToggle;

  /// No description provided for @addBackupLocation.
  ///
  /// In en, this message translates to:
  /// **'+ Add backup location…'**
  String get addBackupLocation;

  /// No description provided for @cannotSave.
  ///
  /// In en, this message translates to:
  /// **'Cannot save'**
  String get cannotSave;

  /// No description provided for @issuesToFix.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 issue to fix} other{{count} issues to fix}}'**
  String issuesToFix(int count);

  /// No description provided for @outsideSupportedFile.
  ///
  /// In en, this message translates to:
  /// **'That file is outside the supported locations (AppData, LocalAppData, ProgramData, user profile, Documents).'**
  String get outsideSupportedFile;

  /// No description provided for @outsideSupportedFolder.
  ///
  /// In en, this message translates to:
  /// **'That folder is outside the supported locations (AppData, LocalAppData, ProgramData, user profile, Documents). Use a custom item on the Backup tab for arbitrary folders.'**
  String get outsideSupportedFolder;

  /// No description provided for @chipSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get chipSafe;

  /// No description provided for @chipCaution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get chipCaution;

  /// No description provided for @chipExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get chipExpert;

  /// No description provided for @chipLocal.
  ///
  /// In en, this message translates to:
  /// **'local'**
  String get chipLocal;

  /// No description provided for @chipCustomized.
  ///
  /// In en, this message translates to:
  /// **'customized'**
  String get chipCustomized;

  /// No description provided for @chipOfficial.
  ///
  /// In en, this message translates to:
  /// **'official'**
  String get chipOfficial;

  /// No description provided for @runScanFirst.
  ///
  /// In en, this message translates to:
  /// **'Run a scan first (Applications tab).'**
  String get runScanFirst;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'es':
      return SEs();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

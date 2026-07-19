// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'AppConfigShelf';

  @override
  String get appTagline => 'Respalda tus apps';

  @override
  String get navHome => 'Inicio';

  @override
  String get navApplications => 'Aplicaciones';

  @override
  String get navBackup => 'Respaldo';

  @override
  String get navRestore => 'Restaurar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navSettings => 'Configuración';

  @override
  String get statusDbLoading => 'Cargando base de datos…';

  @override
  String statusDb(String version, int count) {
    return 'BD v$version · $count entradas';
  }

  @override
  String get statusNoBackups => 'Aún no hay respaldos';

  @override
  String statusLastBackup(String when) {
    return 'Último respaldo $when';
  }

  @override
  String get relativeToday => 'hoy';

  @override
  String get relativeYesterday => 'ayer';

  @override
  String relativeDaysAgo(int days) {
    return 'hace $days días';
  }

  @override
  String relativeDaysAgoShort(int days) {
    return 'hace ${days}d';
  }

  @override
  String get homeSlogan => 'Reinstala Windows. No tu flujo de trabajo.';

  @override
  String get scanThisPc => 'Escanear esta PC';

  @override
  String get scanAgain => 'Escanear de nuevo';

  @override
  String get homeScanPrompt =>
      'Escanea esta PC para ver cuáles de tus aplicaciones instaladas puede respaldar AppConfigShelf.';

  @override
  String get homeScanning => 'Escaneando esta PC…';

  @override
  String get statAppsFound => 'aplicaciones encontradas en esta PC';

  @override
  String get statRecognized => 'reconocidas por la base de datos';

  @override
  String get statUnknown => 'aplicaciones desconocidas por revisar';

  @override
  String get viewApplications => 'Ver aplicaciones';

  @override
  String get readyToBackUp => 'Listas para respaldar';

  @override
  String get review => 'Revisar';

  @override
  String get backupCardTitle => 'Respaldar esta PC';

  @override
  String get backupCardBody =>
      'Elige las aplicaciones y carpetas que importan y obtén un único archivo .acshelf portátil que te acompaña durante la reinstalación.';

  @override
  String get startBackup => 'Iniciar respaldo';

  @override
  String get restoreCardTitle => 'Restaurar un respaldo';

  @override
  String get restoreCardBody =>
      'Abre un archivo .acshelf de esta u otra máquina y recupera todo — completo o solo las partes que elijas.';

  @override
  String get openBackupAction => 'Abrir respaldo…';

  @override
  String get timelineTitle => 'Línea de tiempo de seguridad';

  @override
  String get timelineSubtitle =>
      'Cada respaldo y paquete de deshacer que esta PC ha producido — abre cualquiera como un respaldo.';

  @override
  String get openAFile => 'Abrir un archivo…';

  @override
  String get timelineEmpty =>
      'Nada todavía — tu primer respaldo aparecerá aquí.';

  @override
  String get timelineBackupCreated => 'Respaldo creado';

  @override
  String get timelineUndoKept => 'Paquete de deshacer guardado';

  @override
  String get open => 'Abrir';

  @override
  String get rollBack => 'Revertir';

  @override
  String get appsSubtitle =>
      'Todo lo que encontró el escaneo y lo que la base de datos sabe al respecto.';

  @override
  String get scanSystem => 'Escanear sistema';

  @override
  String get runScanPrompt =>
      'Ejecuta un escaneo para detectar las aplicaciones instaladas.';

  @override
  String scanFailed(String error) {
    return 'El escaneo falló: $error';
  }

  @override
  String chipFound(int count) {
    return '$count encontradas';
  }

  @override
  String chipRecognized(int count) {
    return '$count reconocidas';
  }

  @override
  String chipNotInDb(int count) {
    return '$count fuera de la base de datos';
  }

  @override
  String chipHidden(int count) {
    return '$count ocultas';
  }

  @override
  String recognizedSection(int count) {
    return 'Reconocidas ($count)';
  }

  @override
  String get addAllToBackup => 'Agregar todas al respaldo';

  @override
  String get addToBackup => 'Agregar al respaldo';

  @override
  String matchPercent(int percent) {
    return 'coincidencia $percent%';
  }

  @override
  String notInDbSection(int count) {
    return 'Aún no están en la base de datos ($count)';
  }

  @override
  String get teachPrompt =>
      'Enséñale a AppConfigShelf dónde guardan su configuración';

  @override
  String get findConfig => 'Buscar config…';

  @override
  String get hide => 'Ocultar';

  @override
  String hiddenSection(int count) {
    return 'Ocultas ($count)';
  }

  @override
  String hiddenSummary(int user, int official) {
    return '$user ocultas por ti · $official componentes del sistema ignorados por reglas de la base de datos';
  }

  @override
  String get hiddenByYou => 'oculta por ti';

  @override
  String get unhide => 'Mostrar';

  @override
  String get systemComponentIgnored =>
      'componente del sistema — coincidió con una regla de exclusión de la base de datos';

  @override
  String get unnamed => '(sin nombre)';

  @override
  String get backupTitle => 'Respaldar';

  @override
  String get backupSubtitle =>
      'Elige lo que viaja contigo. No se escribe nada hasta que confirmes.';

  @override
  String get backupSubtitleRunning =>
      'Escribiendo tu respaldo — puedes seguir usando esta PC.';

  @override
  String get stepSelect => 'Seleccionar';

  @override
  String get stepBackUp => 'Respaldar';

  @override
  String get stepDone => 'Listo';

  @override
  String get stepOpen => 'Abrir';

  @override
  String detectedAppsSelected(int selected, int total) {
    return 'Aplicaciones detectadas — $selected de $total seleccionadas';
  }

  @override
  String get filterApps => 'Filtrar aplicaciones';

  @override
  String get backupScanCtaTitle => 'Primero mira qué hay en esta PC';

  @override
  String get backupScanCtaBody =>
      'Un escaneo rápido encuentra tus aplicaciones instaladas para que elijas cuáles respaldar.';

  @override
  String get scanApplications => 'Escanear aplicaciones';

  @override
  String get customItemsSection =>
      'Elementos personalizados — se restauran a sus rutas originales';

  @override
  String get addFolderAction => 'Agregar carpeta…';

  @override
  String get customItemsEmpty =>
      'Agrega cualquier carpeta o archivo para respaldar, aunque no se detecte ninguna aplicación. Los elementos personalizados siempre se restauran a su ubicación original.';

  @override
  String get remove => 'Quitar';

  @override
  String footerSummary(int apps, int items) {
    return '$apps aplicaciones · $items elementos personalizados';
  }

  @override
  String cautionSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count elementos de precaución/experto seleccionados — revísalos antes de restaurar en otra PC',
      one:
          '1 elemento de precaución/experto seleccionado — revísalo antes de restaurar en otra PC',
    );
    return '$_temp0';
  }

  @override
  String get footerNote =>
      'Escribe un solo archivo .acshelf · nada cambia en esta PC';

  @override
  String get backUpSelection => 'Respaldar selección';

  @override
  String backingUpEntry(String entry) {
    return 'Respaldando $entry…';
  }

  @override
  String filesProgress(int done, int total) {
    return '$done de $total archivos';
  }

  @override
  String get lockedFilesNote =>
      'Los archivos bloqueados por aplicaciones en ejecución se omiten de forma segura y se listan en el reporte.';

  @override
  String get backupComplete => 'Respaldo completo';

  @override
  String reportTotals(int entries, int files, String size) {
    return '$entries entradas · $files archivos · $size';
  }

  @override
  String get savedTo => 'Guardado en';

  @override
  String get openFolder => 'Abrir carpeta';

  @override
  String filesAndSize(int files, String size) {
    return '$files archivos · $size';
  }

  @override
  String customSuffix(String name) {
    return '$name (personalizado)';
  }

  @override
  String skippedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos omitidos',
      one: '1 archivo omitido',
    );
    return '$_temp0';
  }

  @override
  String get newBackup => 'Nuevo respaldo';

  @override
  String get goHome => 'Ir a Inicio';

  @override
  String backupFailed(String error) {
    return 'El respaldo falló: $error';
  }

  @override
  String get back => 'Atrás';

  @override
  String get restoreSubtitle =>
      'No se toca nada hasta que presiones Restaurar — y todo lo reemplazado se puede revertir.';

  @override
  String get restoreOpenPrompt =>
      'Abre un paquete de respaldo .acshelf para comenzar a restaurar.';

  @override
  String get chooseAnotherFile => 'Elegir otro archivo…';

  @override
  String packageInfo(String host, String date, String version, int count) {
    return 'De $host · creado $date · app v$version · $count entradas';
  }

  @override
  String get conflictQuestion => 'Si un archivo ya existe en esta PC';

  @override
  String get replaceExisting => 'Reemplazar existentes';

  @override
  String get replaceExistingBody =>
      'Los archivos actuales se copian primero a un paquete de deshacer — puedes revertir toda la restauración.';

  @override
  String get keepExisting => 'Conservar existentes';

  @override
  String get keepExistingBody =>
      'Solo se restauran los archivos que faltan en esta PC. No se sobrescribe nada; no se necesita paquete de deshacer.';

  @override
  String get applicationsSection => 'Aplicaciones';

  @override
  String get selectAllRestorable => 'Seleccionar todo lo restaurable';

  @override
  String get customItemsTitle => 'Elementos personalizados';

  @override
  String nFiles(int count) {
    return '$count archivos';
  }

  @override
  String get appNotInstalled => 'aplicación no instalada';

  @override
  String get notInDbRestores =>
      'fuera de la base de datos — se restaura a las rutas registradas';

  @override
  String existingReplaced(int count) {
    return '$count existentes serán reemplazados';
  }

  @override
  String selectionSummary(int selected, int total) {
    return '$selected de $total entradas seleccionadas';
  }

  @override
  String selectionConflicts(int count) {
    return ' · $count archivos existentes serán reemplazados';
  }

  @override
  String get undoNotice =>
      'Se guarda un paquete de deshacer antes de reemplazar cualquier cosa';

  @override
  String restoreEntries(int count) {
    return 'Restaurar $count entradas';
  }

  @override
  String restoreProgress(String entry, int count) {
    return '$entry — $count archivos restaurados';
  }

  @override
  String get restoreComplete => 'Restauración completa';

  @override
  String get restoreProblems => 'La restauración terminó con problemas';

  @override
  String restoredStats(int count) {
    return '$count archivos restaurados';
  }

  @override
  String keptNewer(int count) {
    return ' · $count conservados (más nuevos en esta PC)';
  }

  @override
  String get undoSavedTitle =>
      'Paquete de deshacer guardado — esta restauración se puede revertir';

  @override
  String get undoSavedBody =>
      'Ábrelo como cualquier respaldo para dejar esta PC exactamente como estaba antes de la restauración.';

  @override
  String get rollBackNow => 'Revertir ahora…';

  @override
  String get showInFolder => 'Mostrar en carpeta';

  @override
  String entryHalted(String entry) {
    return '$entry — detenida';
  }

  @override
  String get done => 'Listo';

  @override
  String get openAnotherBackup => 'Abrir otro respaldo';

  @override
  String get librarySubtitle =>
      'La base de datos oficial de aplicaciones, más tus propias entradas. Las tuyas siempre ganan cuando se superponen.';

  @override
  String get checkForUpdates => 'Buscar actualizaciones';

  @override
  String versionSigned(String version) {
    return 'v$version · firmada';
  }

  @override
  String get upToDateTitle => 'Actualizada';

  @override
  String upToDateBody(String version) {
    return 'La versión $version es la más reciente.';
  }

  @override
  String get dbUpdatedTitle => 'Base de datos actualizada';

  @override
  String dbUpdatedBody(String version) {
    return 'Ahora se usa la versión $version.';
  }

  @override
  String get updateFailedTitle => 'Falló la búsqueda de actualizaciones';

  @override
  String dbLoadFailed(String error) {
    return 'No se pudo cargar la base de datos: $error';
  }

  @override
  String searchEntries(int count) {
    return 'Buscar entre $count entradas';
  }

  @override
  String filterAll(int count) {
    return 'Todas $count';
  }

  @override
  String filterMine(int count) {
    return 'Mi biblioteca $count';
  }

  @override
  String filterOfficial(int count) {
    return 'Oficiales $count';
  }

  @override
  String get skippedInvalidEntry => 'Se omitió un archivo de entrada inválido';

  @override
  String get noEntriesMatch => 'Ninguna entrada coincide.';

  @override
  String get exportYaml => 'Exportar YAML…';

  @override
  String get resetToOfficial => 'Restablecer a oficial';

  @override
  String get deleteEntry => 'Eliminar entrada';

  @override
  String get editEntry => 'Editar entrada';

  @override
  String get customizedBannerTitle => 'Tu copia personalizada.';

  @override
  String get customizedBannerBody =>
      'El escaneo y los respaldos usan esta en lugar de la entrada oficial.';

  @override
  String get localBannerTitle => 'Entrada local.';

  @override
  String get localBannerBody =>
      'Creada en esta PC — exporta un borrador YAML para contribuirla a la base de datos oficial.';

  @override
  String get detectionSection => 'Detección';

  @override
  String get detectionActiveNote =>
      'La entrada solo está activa cuando la detección coincide';

  @override
  String backupLocationsSection(int count) {
    return 'Ubicaciones de respaldo ($count)';
  }

  @override
  String get chipOptional => 'opcional';

  @override
  String get chipLarge => 'grande';

  @override
  String get includeLabel => 'Incluir';

  @override
  String get excludeLabel => 'Excluir';

  @override
  String get yamlExportedTitle => 'YAML exportado';

  @override
  String yamlExportedBody(String path) {
    return 'Guardado en $path. Agrégalo bajo apps/ en el repositorio AppConfigShelf-DB y abre un pull request.';
  }

  @override
  String registryDetection(String key) {
    return 'Registro: $key';
  }

  @override
  String msixDetection(String name) {
    return 'Paquete MSIX: $name';
  }

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsSubtitle => 'Apariencia e idioma.';

  @override
  String get appearanceSection => 'Apariencia';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeSystem => 'Seguir la configuración de Windows';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get languageSection => 'Idioma';

  @override
  String get languageLabel => 'Idioma de la aplicación';

  @override
  String get languageSystem => 'Seguir la configuración de Windows';

  @override
  String get langEnglish => 'English';

  @override
  String get langSpanish => 'Español (Latinoamérica)';

  @override
  String findConfigTitle(String app) {
    return 'Buscar configuración — $app';
  }

  @override
  String get finderSubtitle =>
      'AppConfigShelf buscó en los lugares habituales. Marca las carpetas que guardan la configuración de esta aplicación.';

  @override
  String get finderNoCandidates =>
      'No se encontraron carpetas de configuración probables en AppData, LocalAppData ni Documentos. La aplicación puede guardar su configuración en el registro o en su carpeta de instalación — aun así puedes elegir cualquier carpeta y respaldarla como elemento personalizado.';

  @override
  String get addFolderAsCustomItem =>
      'Agregar carpeta como elemento personalizado…';

  @override
  String get finderNothingHere =>
      '¿Nada aquí? La configuración puede estar en el registro o en la carpeta de instalación.';

  @override
  String get lowConfidence => 'baja confianza';

  @override
  String get close => 'Cerrar';

  @override
  String get editBeforeSaving => 'Editar antes de guardar…';

  @override
  String get saveToMyLibrary => 'Guardar en mi biblioteca';

  @override
  String savedToLibraryTitle(String name) {
    return '\"$name\" se guardó en Mi biblioteca';
  }

  @override
  String get savedToLibraryBody =>
      'Reescaneando para detectarla — aparecerá bajo Reconocidas y en la lista de Respaldo en un momento. Edítala cuando quieras desde la pestaña Biblioteca.';

  @override
  String get customItemAddedTitle => 'Elemento personalizado agregado';

  @override
  String get customItemAddedBody =>
      'La carpeta aparece bajo Elementos personalizados en la pestaña Respaldo y se incluirá en cada respaldo.';

  @override
  String get unknownApp => 'Aplicación desconocida';

  @override
  String get nameThisItem => 'Nombra este elemento';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Agregar';

  @override
  String get unsupportedPath => 'Ruta no compatible';

  @override
  String editEntryTitle(String name) {
    return 'Editar entrada — $name';
  }

  @override
  String get editorSubtitle =>
      'Se guarda solo en Mi biblioteca — la entrada oficial de la base de datos nunca se modifica.';

  @override
  String get displayName => 'Nombre para mostrar';

  @override
  String get detectPath => 'Ruta de detección';

  @override
  String get browse => 'Examinar…';

  @override
  String get detectPathNote =>
      'La entrada se usa solo cuando este archivo existe en la PC.';

  @override
  String get backupLocations => 'Ubicaciones de respaldo';

  @override
  String get folder => 'Carpeta';

  @override
  String get includePatterns => 'Patrones de inclusión';

  @override
  String get excludePatterns => 'Patrones de exclusión';

  @override
  String get includeHelp =>
      'Patrones como **/*.json — deja vacío para incluir todo';

  @override
  String get excludeHelp => 'Se omiten aunque coincidan con Incluir';

  @override
  String get optionalToggle =>
      'Opcional — omitir en silencio cuando esta carpeta no exista';

  @override
  String get addBackupLocation => '+ Agregar ubicación de respaldo…';

  @override
  String get cannotSave => 'No se puede guardar';

  @override
  String issuesToFix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problemas por corregir',
      one: '1 problema por corregir',
    );
    return '$_temp0';
  }

  @override
  String get outsideSupportedFile =>
      'Ese archivo está fuera de las ubicaciones compatibles (AppData, LocalAppData, ProgramData, perfil de usuario, Documentos).';

  @override
  String get outsideSupportedFolder =>
      'Esa carpeta está fuera de las ubicaciones compatibles (AppData, LocalAppData, ProgramData, perfil de usuario, Documentos). Usa un elemento personalizado en la pestaña Respaldo para carpetas arbitrarias.';

  @override
  String get chipSafe => 'Segura';

  @override
  String get chipCaution => 'Precaución';

  @override
  String get chipExpert => 'Experto';

  @override
  String get chipLocal => 'local';

  @override
  String get chipCustomized => 'personalizada';

  @override
  String get chipOfficial => 'oficial';

  @override
  String get runScanFirst =>
      'Primero ejecuta un escaneo (pestaña Aplicaciones).';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get appTitle => 'my memo';

  @override
  String get appDescription =>
      'Приложение за организиране на бележки, задачи и screenshots';

  @override
  String get searchHint => 'Търсене...';

  @override
  String get noNotesFound => 'Няма открити бележки.';

  @override
  String get newNote => 'Нова бележка';

  @override
  String get editNote => 'Редактиране';

  @override
  String get viewNote => 'Преглед';

  @override
  String get titleHint => 'Заглавие';

  @override
  String get contentHint => 'Съдържание...';

  @override
  String get save => 'Запази';

  @override
  String get cancel => 'Отказ';

  @override
  String get delete => 'Изтрий';

  @override
  String get close => 'Затвори';

  @override
  String get done => 'Готово';

  @override
  String get confirm => 'Потвърждение';

  @override
  String get clearAll => 'Изчисти всички';

  @override
  String get back => 'Назад';

  @override
  String get confirmDeleteNote =>
      'Сигурни ли сте, че искате да изтриете тази бележка?';

  @override
  String get discardChanges => 'Отхвърляне на промените?';

  @override
  String get unsavedChanges =>
      'Имате незапазени промени. Сигурни ли сте, че искате да излезете?';

  @override
  String get discard => 'Отхвърли';

  @override
  String get settings => 'Настройки';

  @override
  String get appBackground => 'Фон на приложението';

  @override
  String get noteBackground => 'Фон на бележките';

  @override
  String get listView => 'Списък';

  @override
  String get gridView => 'Матрица';

  @override
  String get columns => 'Брой колони';

  @override
  String get textLines => 'Брой редове текст';

  @override
  String get compactView => 'Компактен вид';

  @override
  String get tabStop => 'Таб стоп';

  @override
  String get fontSizeTitle => 'Размер шрифт заглавие';

  @override
  String get fontSizeContent => 'Размер шрифт текст';

  @override
  String get showDate => 'Показване на датата';

  @override
  String get editor => 'Редактор';

  @override
  String get alignmentColumn => 'Подравняване в колона';

  @override
  String get tagFilter => 'Филтър по етикети';

  @override
  String get filterMatchAll => 'ВСИЧКИ избрани';

  @override
  String get filterMatchAny => 'ПОНЕ ЕДИН от избраните';

  @override
  String get confirmDelete => 'Потвърждение при изтриване';

  @override
  String get enabled => 'Включено';

  @override
  String get disabled => 'Изключено';

  @override
  String get sharing => 'Споделяне';

  @override
  String get maxTitleLength => 'Дължина на заглавие';

  @override
  String get googleDriveBackup => 'Архивиране в Google Drive';

  @override
  String get backupReminder => 'Напомняне (дни)';

  @override
  String get backupNow => 'Архивирай';

  @override
  String get restoreNow => 'Възстанови';

  @override
  String get noAccount => 'Няма свързан акаунт';

  @override
  String get backupPeriodNone => 'Изключено';

  @override
  String get localBackup => 'Локален архив';

  @override
  String get localBackupSaved =>
      'Архивът е записан в папка Изтегляния/my_memo_backups';

  @override
  String get localBackupError => 'Грешка при записване';

  @override
  String get unusedImages => 'Неизползвани снимки';

  @override
  String get database => 'База данни';

  @override
  String get files => 'Файлове';

  @override
  String get archiveConfirm =>
      'Това ще замести всички текущи бележки с данни от архива. Продължи?';

  @override
  String get restoreSuccess => 'Възстановяването е успешно!';

  @override
  String get restoreError => 'Грешка при възстановяване';

  @override
  String get noArchivesFound => 'Няма намерени архиви';

  @override
  String get selectArchive => 'Избор на архив';

  @override
  String get backupSuccess => 'Архивирането е успешно!';

  @override
  String get backupError => 'Грешка при архивиране';

  @override
  String get googleSignIn => 'Влизане в Google акаунт';

  @override
  String get googleSignOut => 'Излизане';

  @override
  String get signInFailed => 'Неуспешно влизане в Google акаунт';

  @override
  String get orphanedImages => 'Неизползвани снимки';

  @override
  String get orphanedImagesTitle => 'Неизползвани снимки';

  @override
  String get orphanedImagesDesc =>
      'Тези снимки не са свързани с никоя бележка. Да бъдат ли изчистени преди архивирането?';

  @override
  String get cleanOrphans => 'Да, изчисти';

  @override
  String get deleteAll => 'Изтрий всички';

  @override
  String get deleteSingle => 'Изтрий';

  @override
  String get noOrphanedImages => 'Няма неизползвани снимки';

  @override
  String get databaseTitle => 'Контрол на БД';

  @override
  String get filesInMemory => 'Файлове в паметта';

  @override
  String get noLocalFiles => 'Няма локални файлове.';

  @override
  String get previous => 'Предишен';

  @override
  String get next => 'Следващ';

  @override
  String get colorPicker => 'Изберете цвят';

  @override
  String get filter => 'Филтриране';

  @override
  String get period => 'Период';

  @override
  String get color => 'Цвят';

  @override
  String get tasksOnly => 'Само задачи';

  @override
  String get sequentialOrder => 'Последователен ред';

  @override
  String get reverseOrder => 'Обратно подреждане';

  @override
  String get tags => 'Етикети';

  @override
  String get tagFilterTitle => 'Филтър по етикети';

  @override
  String get noTagsAvailable => 'Няма налични етикети.';

  @override
  String get selectTags => 'Избери:';

  @override
  String get newTag => 'Нов етикет';

  @override
  String get tagHint => 'Име...';

  @override
  String get manageTags => 'Управление на етикети';

  @override
  String get scrollUp => 'Нагоре';

  @override
  String get viewToggle => 'Изглед';

  @override
  String get clearSearch => 'Без търсене';

  @override
  String get filters => 'Филтри';

  @override
  String get clearFilters => 'Без филтри';

  @override
  String get addNote => 'Нова бележка';

  @override
  String get noteFormDeleteImage => 'Изтрий снимката';

  @override
  String get noteFormCropImage => 'Изрежи снимката';

  @override
  String get noteFormCropTitle => 'Изрязване';

  @override
  String get noteFormGallery => 'Галерия';

  @override
  String get noteFormCamera => 'Камера';

  @override
  String get noteFormTags => 'Етикети';

  @override
  String get noteFormBulletList => 'Списък';

  @override
  String get noteFormNumberedList => 'Номериран списък';

  @override
  String get noteFormChecklist => 'Пазаруване';

  @override
  String get noteFormTask => 'Задача';

  @override
  String get noteFormCopyLocal => 'Копирай локално';

  @override
  String get noteFormCopyLocalDesc =>
      'Запазва снимката, дори да бъде изтрита от галерията';

  @override
  String get noteFormCopyLocalWarning => 'Внимание';

  @override
  String get noteFormCopyLocalWarningDesc =>
      'Ако изключите локалното копиране, приложението ще разчита на временен файл в кеша. Ако кешът бъде изчистен, файлът ще изчезне.';

  @override
  String get noteFormCopyLocalDisable => 'Изключи';

  @override
  String get noteFormMoveToTitle => 'Премести първия параграф към заглавието';

  @override
  String get noteFormClearTitle => 'Изчисти заглавието';

  @override
  String get noteFormLineStart => 'Начало на ред';

  @override
  String get noteFormTwoDecimals => 'Суми с 2 знака';

  @override
  String get noteFormLineEndTab => 'Край на ред / Таб';

  @override
  String get noteFormDuplicateLine => 'Дублирай реда';

  @override
  String get noteFormDeleteLine => 'Изтрий реда';

  @override
  String get noteFormCalculator => 'Калкулатор';

  @override
  String get noteFormEdit => 'Редактирай';

  @override
  String get noteFormPreview => 'Преглед';

  @override
  String get translationTranslateInterface => 'Превод на интерфейса';

  @override
  String get translationEditInterface => 'Редакция на интерфейса';

  @override
  String get translationSelectBaseLanguage => 'Базов език';

  @override
  String get translationSelectTargetLanguage => 'Целеви език';

  @override
  String get translationTranslateAll => 'Преведи всички низове';

  @override
  String translationProgress(Object current, Object total) {
    return 'Прогрес: $current/$total низа';
  }

  @override
  String get translationSaveArb => 'Запази ARB файл';

  @override
  String get translationComplete => 'Преводът е завършен!';

  @override
  String get translationSearchStrings => 'Търсене...';

  @override
  String get languageInterface => 'Език на интерфейса';

  @override
  String get editWith => 'Редактирай:';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Не';

  @override
  String get postpone => 'Отложи';

  @override
  String get note => 'Бележка';

  @override
  String get clear => 'Изчисти';

  @override
  String get restore => 'Възстанови';

  @override
  String get deleting => 'Изтриване';

  @override
  String get restoreTitle => 'Възстановяване';

  @override
  String get restoreConfirm =>
      'Това ще замести всички текущи бележки с данни от архива. Продължи?';

  @override
  String localBackupReminder(Object days) {
    return 'Напомняне на всеки $days дни';
  }

  @override
  String get confirmDeleteRecord =>
      'Сигурни ли сте, че искате да изтриете този запис?';

  @override
  String localFileWarning(Object fileName) {
    return 'Внимание: Локалното копие на файла ($fileName) също ще бъде изтрито от паметта на приложението.';
  }

  @override
  String get deleteRecordTooltip => 'Изтрий записа от БД';

  @override
  String get databaseEmpty => 'Базата данни е празна.';

  @override
  String recordInfo(Object m, Object n) {
    return 'Запис $n от $m';
  }

  @override
  String get fileNotFound => 'Файлът не е намерен';

  @override
  String get deleteFileTitle => 'Изтриване на файл';

  @override
  String get deleteFileConfirm =>
      'Сигурни ли сте? Това ще изтрие физическия файл от паметта. Ако той е свързан с бележка, тя вече няма да го показва.';

  @override
  String fileInfo(Object fileName, Object m, Object n, Object size) {
    return 'Файл $n от $m\n$fileName\nРазмер: $size';
  }

  @override
  String backupReminderMessage(Object days) {
    return 'Последният бекъп е преди $days дни. Желаете ли да архивирате данните си?';
  }

  @override
  String tagsForNote(Object title) {
    return 'Етикети за \"$title\"';
  }

  @override
  String get newTagColon => 'Нов етикет:';

  @override
  String copiedResult(Object expr, Object result) {
    return '$expr $result (Копирано)';
  }

  @override
  String calculationError(Object expr) {
    return 'Грешка при изчисление: $expr';
  }

  @override
  String saveError(Object error) {
    return 'Грешка запис: $error';
  }

  @override
  String orphanedImagesFound(Object count) {
    return 'Намерени са $count неизползвани снимки';
  }

  @override
  String get noLocalArchivesInDownloads =>
      'Няма намерени локални архиви в Downloads';

  @override
  String get noGoogleDriveBackups => 'Няма намерени архиви в Google Drive';

  @override
  String get noArchives => 'Няма архиви';

  @override
  String deleteBackupConfirmName(Object name) {
    return 'Изтрий архива $name?';
  }

  @override
  String deleteFileConfirmName(Object name) {
    return 'Изтрий $name?';
  }

  @override
  String orphanedImagesCount(Object count) {
    return 'Неизползвани снимки ($count)';
  }

  @override
  String get deleteAllOrphans => 'Изтриване на всички';

  @override
  String deleteOrphansConfirm(Object count) {
    return 'Изтрий $count неизползвани снимки?';
  }

  @override
  String get selectLanguage => 'Избор на език';

  @override
  String get searchLanguage => 'Търсене на език...';

  @override
  String get enterLanguageCode => 'Въведи ръчно езиков код';

  @override
  String get languageCodeHint =>
      'напр. \"sv\" за шведски, \"vi\" за виетнамски';

  @override
  String genericError(Object error) {
    return 'Грешка: $error';
  }
}

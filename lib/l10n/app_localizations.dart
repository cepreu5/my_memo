import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bg.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[Locale('bg')];

  /// No description provided for @appTitle.
  ///
  /// In bg, this message translates to:
  /// **'my memo'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In bg, this message translates to:
  /// **'Приложение за организиране на бележки, задачи и screenshots'**
  String get appDescription;

  /// No description provided for @searchHint.
  ///
  /// In bg, this message translates to:
  /// **'Търсене...'**
  String get searchHint;

  /// No description provided for @noNotesFound.
  ///
  /// In bg, this message translates to:
  /// **'Няма открити бележки.'**
  String get noNotesFound;

  /// No description provided for @newNote.
  ///
  /// In bg, this message translates to:
  /// **'Нова бележка'**
  String get newNote;

  /// No description provided for @editNote.
  ///
  /// In bg, this message translates to:
  /// **'Редактиране'**
  String get editNote;

  /// No description provided for @viewNote.
  ///
  /// In bg, this message translates to:
  /// **'Преглед'**
  String get viewNote;

  /// No description provided for @titleHint.
  ///
  /// In bg, this message translates to:
  /// **'Заглавие'**
  String get titleHint;

  /// No description provided for @contentHint.
  ///
  /// In bg, this message translates to:
  /// **'Съдържание...'**
  String get contentHint;

  /// No description provided for @save.
  ///
  /// In bg, this message translates to:
  /// **'Запази'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In bg, this message translates to:
  /// **'Отказ'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In bg, this message translates to:
  /// **'Изтрий'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In bg, this message translates to:
  /// **'Затвори'**
  String get close;

  /// No description provided for @done.
  ///
  /// In bg, this message translates to:
  /// **'Готово'**
  String get done;

  /// No description provided for @confirm.
  ///
  /// In bg, this message translates to:
  /// **'Потвърждение'**
  String get confirm;

  /// No description provided for @clearAll.
  ///
  /// In bg, this message translates to:
  /// **'Изчисти всички'**
  String get clearAll;

  /// No description provided for @back.
  ///
  /// In bg, this message translates to:
  /// **'Назад'**
  String get back;

  /// No description provided for @confirmDeleteNote.
  ///
  /// In bg, this message translates to:
  /// **'Сигурни ли сте, че искате да изтриете тази бележка?'**
  String get confirmDeleteNote;

  /// No description provided for @discardChanges.
  ///
  /// In bg, this message translates to:
  /// **'Отхвърляне на промените?'**
  String get discardChanges;

  /// No description provided for @unsavedChanges.
  ///
  /// In bg, this message translates to:
  /// **'Имате незапазени промени. Сигурни ли сте, че искате да излезете?'**
  String get unsavedChanges;

  /// No description provided for @discard.
  ///
  /// In bg, this message translates to:
  /// **'Отхвърли'**
  String get discard;

  /// No description provided for @settings.
  ///
  /// In bg, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @appBackground.
  ///
  /// In bg, this message translates to:
  /// **'Фон на приложението'**
  String get appBackground;

  /// No description provided for @noteBackground.
  ///
  /// In bg, this message translates to:
  /// **'Фон на бележките'**
  String get noteBackground;

  /// No description provided for @listView.
  ///
  /// In bg, this message translates to:
  /// **'Списък'**
  String get listView;

  /// No description provided for @gridView.
  ///
  /// In bg, this message translates to:
  /// **'Матрица'**
  String get gridView;

  /// No description provided for @columns.
  ///
  /// In bg, this message translates to:
  /// **'Брой колони'**
  String get columns;

  /// No description provided for @textLines.
  ///
  /// In bg, this message translates to:
  /// **'Брой редове текст'**
  String get textLines;

  /// No description provided for @compactView.
  ///
  /// In bg, this message translates to:
  /// **'Компактен вид'**
  String get compactView;

  /// No description provided for @tabStop.
  ///
  /// In bg, this message translates to:
  /// **'Таб стоп'**
  String get tabStop;

  /// No description provided for @fontSizeTitle.
  ///
  /// In bg, this message translates to:
  /// **'Размер шрифт заглавие'**
  String get fontSizeTitle;

  /// No description provided for @fontSizeContent.
  ///
  /// In bg, this message translates to:
  /// **'Размер шрифт текст'**
  String get fontSizeContent;

  /// No description provided for @showDate.
  ///
  /// In bg, this message translates to:
  /// **'Показване на датата'**
  String get showDate;

  /// No description provided for @editor.
  ///
  /// In bg, this message translates to:
  /// **'Редактор'**
  String get editor;

  /// No description provided for @alignmentColumn.
  ///
  /// In bg, this message translates to:
  /// **'Подравняване в колона'**
  String get alignmentColumn;

  /// No description provided for @tagFilter.
  ///
  /// In bg, this message translates to:
  /// **'Филтър по етикети'**
  String get tagFilter;

  /// No description provided for @filterMatchAll.
  ///
  /// In bg, this message translates to:
  /// **'ВСИЧКИ избрани'**
  String get filterMatchAll;

  /// No description provided for @filterMatchAny.
  ///
  /// In bg, this message translates to:
  /// **'ПОНЕ ЕДИН от избраните'**
  String get filterMatchAny;

  /// No description provided for @confirmDelete.
  ///
  /// In bg, this message translates to:
  /// **'Потвърждение при изтриване'**
  String get confirmDelete;

  /// No description provided for @enabled.
  ///
  /// In bg, this message translates to:
  /// **'Включено'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In bg, this message translates to:
  /// **'Изключено'**
  String get disabled;

  /// No description provided for @sharing.
  ///
  /// In bg, this message translates to:
  /// **'Споделяне'**
  String get sharing;

  /// No description provided for @maxTitleLength.
  ///
  /// In bg, this message translates to:
  /// **'Дължина на заглавие'**
  String get maxTitleLength;

  /// No description provided for @googleDriveBackup.
  ///
  /// In bg, this message translates to:
  /// **'Архивиране в Google Drive'**
  String get googleDriveBackup;

  /// No description provided for @backupReminder.
  ///
  /// In bg, this message translates to:
  /// **'Напомняне (дни)'**
  String get backupReminder;

  /// No description provided for @backupNow.
  ///
  /// In bg, this message translates to:
  /// **'Архивирай'**
  String get backupNow;

  /// No description provided for @restoreNow.
  ///
  /// In bg, this message translates to:
  /// **'Възстанови'**
  String get restoreNow;

  /// No description provided for @noAccount.
  ///
  /// In bg, this message translates to:
  /// **'Няма свързан акаунт'**
  String get noAccount;

  /// No description provided for @backupPeriodNone.
  ///
  /// In bg, this message translates to:
  /// **'Изключено'**
  String get backupPeriodNone;

  /// No description provided for @localBackup.
  ///
  /// In bg, this message translates to:
  /// **'Локален архив'**
  String get localBackup;

  /// No description provided for @localBackupSaved.
  ///
  /// In bg, this message translates to:
  /// **'Архивът е записан в папка Изтегляния/my_memo_backups'**
  String get localBackupSaved;

  /// No description provided for @localBackupError.
  ///
  /// In bg, this message translates to:
  /// **'Грешка при записване'**
  String get localBackupError;

  /// No description provided for @unusedImages.
  ///
  /// In bg, this message translates to:
  /// **'Неизползвани снимки'**
  String get unusedImages;

  /// No description provided for @database.
  ///
  /// In bg, this message translates to:
  /// **'База данни'**
  String get database;

  /// No description provided for @files.
  ///
  /// In bg, this message translates to:
  /// **'Файлове'**
  String get files;

  /// No description provided for @archiveConfirm.
  ///
  /// In bg, this message translates to:
  /// **'Това ще замести всички текущи бележки с данни от архива. Продължи?'**
  String get archiveConfirm;

  /// No description provided for @restoreSuccess.
  ///
  /// In bg, this message translates to:
  /// **'Възстановяването е успешно!'**
  String get restoreSuccess;

  /// No description provided for @restoreError.
  ///
  /// In bg, this message translates to:
  /// **'Грешка при възстановяване'**
  String get restoreError;

  /// No description provided for @noArchivesFound.
  ///
  /// In bg, this message translates to:
  /// **'Няма намерени архиви'**
  String get noArchivesFound;

  /// No description provided for @selectArchive.
  ///
  /// In bg, this message translates to:
  /// **'Избор на архив'**
  String get selectArchive;

  /// No description provided for @backupSuccess.
  ///
  /// In bg, this message translates to:
  /// **'Архивирането е успешно!'**
  String get backupSuccess;

  /// No description provided for @backupError.
  ///
  /// In bg, this message translates to:
  /// **'Грешка при архивиране'**
  String get backupError;

  /// No description provided for @googleSignIn.
  ///
  /// In bg, this message translates to:
  /// **'Влизане в Google акаунт'**
  String get googleSignIn;

  /// No description provided for @googleSignOut.
  ///
  /// In bg, this message translates to:
  /// **'Излизане'**
  String get googleSignOut;

  /// No description provided for @signInFailed.
  ///
  /// In bg, this message translates to:
  /// **'Неуспешно влизане в Google акаунт'**
  String get signInFailed;

  /// No description provided for @orphanedImages.
  ///
  /// In bg, this message translates to:
  /// **'Неизползвани снимки'**
  String get orphanedImages;

  /// No description provided for @orphanedImagesTitle.
  ///
  /// In bg, this message translates to:
  /// **'Неизползвани снимки'**
  String get orphanedImagesTitle;

  /// No description provided for @orphanedImagesDesc.
  ///
  /// In bg, this message translates to:
  /// **'Тези снимки не са свързани с никоя бележка. Да бъдат ли изчистени преди архивирането?'**
  String get orphanedImagesDesc;

  /// No description provided for @cleanOrphans.
  ///
  /// In bg, this message translates to:
  /// **'Да, изчисти'**
  String get cleanOrphans;

  /// No description provided for @deleteAll.
  ///
  /// In bg, this message translates to:
  /// **'Изтрий всички'**
  String get deleteAll;

  /// No description provided for @deleteSingle.
  ///
  /// In bg, this message translates to:
  /// **'Изтрий'**
  String get deleteSingle;

  /// No description provided for @noOrphanedImages.
  ///
  /// In bg, this message translates to:
  /// **'Няма неизползвани снимки'**
  String get noOrphanedImages;

  /// No description provided for @databaseTitle.
  ///
  /// In bg, this message translates to:
  /// **'Контрол на БД'**
  String get databaseTitle;

  /// No description provided for @filesInMemory.
  ///
  /// In bg, this message translates to:
  /// **'Файлове в паметта'**
  String get filesInMemory;

  /// No description provided for @noLocalFiles.
  ///
  /// In bg, this message translates to:
  /// **'Няма локални файлове.'**
  String get noLocalFiles;

  /// No description provided for @previous.
  ///
  /// In bg, this message translates to:
  /// **'Предишен'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In bg, this message translates to:
  /// **'Следващ'**
  String get next;

  /// No description provided for @colorPicker.
  ///
  /// In bg, this message translates to:
  /// **'Изберете цвят'**
  String get colorPicker;

  /// No description provided for @filter.
  ///
  /// In bg, this message translates to:
  /// **'Филтриране'**
  String get filter;

  /// No description provided for @period.
  ///
  /// In bg, this message translates to:
  /// **'Период'**
  String get period;

  /// No description provided for @color.
  ///
  /// In bg, this message translates to:
  /// **'Цвят'**
  String get color;

  /// No description provided for @tasksOnly.
  ///
  /// In bg, this message translates to:
  /// **'Само задачи'**
  String get tasksOnly;

  /// No description provided for @sequentialOrder.
  ///
  /// In bg, this message translates to:
  /// **'Последователен ред'**
  String get sequentialOrder;

  /// No description provided for @reverseOrder.
  ///
  /// In bg, this message translates to:
  /// **'Обратно подреждане'**
  String get reverseOrder;

  /// No description provided for @tags.
  ///
  /// In bg, this message translates to:
  /// **'Етикети'**
  String get tags;

  /// No description provided for @tagFilterTitle.
  ///
  /// In bg, this message translates to:
  /// **'Филтър по етикети'**
  String get tagFilterTitle;

  /// No description provided for @noTagsAvailable.
  ///
  /// In bg, this message translates to:
  /// **'Няма налични етикети.'**
  String get noTagsAvailable;

  /// No description provided for @selectTags.
  ///
  /// In bg, this message translates to:
  /// **'Избери:'**
  String get selectTags;

  /// No description provided for @newTag.
  ///
  /// In bg, this message translates to:
  /// **'Нов етикет'**
  String get newTag;

  /// No description provided for @tagHint.
  ///
  /// In bg, this message translates to:
  /// **'Име...'**
  String get tagHint;

  /// No description provided for @manageTags.
  ///
  /// In bg, this message translates to:
  /// **'Управление на етикети'**
  String get manageTags;

  /// No description provided for @scrollUp.
  ///
  /// In bg, this message translates to:
  /// **'Нагоре'**
  String get scrollUp;

  /// No description provided for @viewToggle.
  ///
  /// In bg, this message translates to:
  /// **'Изглед'**
  String get viewToggle;

  /// No description provided for @clearSearch.
  ///
  /// In bg, this message translates to:
  /// **'Без търсене'**
  String get clearSearch;

  /// No description provided for @filters.
  ///
  /// In bg, this message translates to:
  /// **'Филтри'**
  String get filters;

  /// No description provided for @clearFilters.
  ///
  /// In bg, this message translates to:
  /// **'Без филтри'**
  String get clearFilters;

  /// No description provided for @addNote.
  ///
  /// In bg, this message translates to:
  /// **'Нова бележка'**
  String get addNote;

  /// No description provided for @noteFormDeleteImage.
  ///
  /// In bg, this message translates to:
  /// **'Изтрий снимката'**
  String get noteFormDeleteImage;

  /// No description provided for @noteFormCropImage.
  ///
  /// In bg, this message translates to:
  /// **'Изрежи снимката'**
  String get noteFormCropImage;

  /// No description provided for @noteFormCropTitle.
  ///
  /// In bg, this message translates to:
  /// **'Изрязване'**
  String get noteFormCropTitle;

  /// No description provided for @noteFormGallery.
  ///
  /// In bg, this message translates to:
  /// **'Галерия'**
  String get noteFormGallery;

  /// No description provided for @noteFormCamera.
  ///
  /// In bg, this message translates to:
  /// **'Камера'**
  String get noteFormCamera;

  /// No description provided for @noteFormTags.
  ///
  /// In bg, this message translates to:
  /// **'Етикети'**
  String get noteFormTags;

  /// No description provided for @noteFormBulletList.
  ///
  /// In bg, this message translates to:
  /// **'Списък'**
  String get noteFormBulletList;

  /// No description provided for @noteFormNumberedList.
  ///
  /// In bg, this message translates to:
  /// **'Номериран списък'**
  String get noteFormNumberedList;

  /// No description provided for @noteFormChecklist.
  ///
  /// In bg, this message translates to:
  /// **'Пазаруване'**
  String get noteFormChecklist;

  /// No description provided for @noteFormTask.
  ///
  /// In bg, this message translates to:
  /// **'Задача'**
  String get noteFormTask;

  /// No description provided for @noteFormCopyLocal.
  ///
  /// In bg, this message translates to:
  /// **'Копирай локално'**
  String get noteFormCopyLocal;

  /// No description provided for @noteFormCopyLocalDesc.
  ///
  /// In bg, this message translates to:
  /// **'Запазва снимката, дори да бъде изтрита от галерията'**
  String get noteFormCopyLocalDesc;

  /// No description provided for @noteFormCopyLocalWarning.
  ///
  /// In bg, this message translates to:
  /// **'Внимание'**
  String get noteFormCopyLocalWarning;

  /// No description provided for @noteFormCopyLocalWarningDesc.
  ///
  /// In bg, this message translates to:
  /// **'Ако изключите локалното копиране, приложението ще разчита на временен файл в кеша. Ако кешът бъде изчистен, файлът ще изчезне.'**
  String get noteFormCopyLocalWarningDesc;

  /// No description provided for @noteFormCopyLocalDisable.
  ///
  /// In bg, this message translates to:
  /// **'Изключи'**
  String get noteFormCopyLocalDisable;

  /// No description provided for @noteFormMoveToTitle.
  ///
  /// In bg, this message translates to:
  /// **'Премести първия параграф към заглавието'**
  String get noteFormMoveToTitle;

  /// No description provided for @noteFormClearTitle.
  ///
  /// In bg, this message translates to:
  /// **'Изчисти заглавието'**
  String get noteFormClearTitle;

  /// No description provided for @noteFormLineStart.
  ///
  /// In bg, this message translates to:
  /// **'Начало на ред'**
  String get noteFormLineStart;

  /// No description provided for @noteFormTwoDecimals.
  ///
  /// In bg, this message translates to:
  /// **'Суми с 2 знака'**
  String get noteFormTwoDecimals;

  /// No description provided for @noteFormLineEndTab.
  ///
  /// In bg, this message translates to:
  /// **'Край на ред / Таб'**
  String get noteFormLineEndTab;

  /// No description provided for @noteFormDuplicateLine.
  ///
  /// In bg, this message translates to:
  /// **'Дублирай реда'**
  String get noteFormDuplicateLine;

  /// No description provided for @noteFormDeleteLine.
  ///
  /// In bg, this message translates to:
  /// **'Изтрий реда'**
  String get noteFormDeleteLine;

  /// No description provided for @noteFormCalculator.
  ///
  /// In bg, this message translates to:
  /// **'Калкулатор'**
  String get noteFormCalculator;

  /// No description provided for @noteFormEdit.
  ///
  /// In bg, this message translates to:
  /// **'Редактирай'**
  String get noteFormEdit;

  /// No description provided for @noteFormPreview.
  ///
  /// In bg, this message translates to:
  /// **'Преглед'**
  String get noteFormPreview;

  /// No description provided for @translationTranslateInterface.
  ///
  /// In bg, this message translates to:
  /// **'Превод на интерфейса'**
  String get translationTranslateInterface;

  /// No description provided for @translationEditInterface.
  ///
  /// In bg, this message translates to:
  /// **'Редакция на интерфейса'**
  String get translationEditInterface;

  /// No description provided for @translationSelectBaseLanguage.
  ///
  /// In bg, this message translates to:
  /// **'Базов език'**
  String get translationSelectBaseLanguage;

  /// No description provided for @translationSelectTargetLanguage.
  ///
  /// In bg, this message translates to:
  /// **'Целеви език'**
  String get translationSelectTargetLanguage;

  /// No description provided for @translationTranslateAll.
  ///
  /// In bg, this message translates to:
  /// **'Преведи всички низове'**
  String get translationTranslateAll;

  /// No description provided for @translationProgress.
  ///
  /// In bg, this message translates to:
  /// **'Прогрес: {current}/{total} низа'**
  String translationProgress(Object current, Object total);

  /// No description provided for @translationSaveArb.
  ///
  /// In bg, this message translates to:
  /// **'Запази ARB файл'**
  String get translationSaveArb;

  /// No description provided for @translationComplete.
  ///
  /// In bg, this message translates to:
  /// **'Преводът е завършен!'**
  String get translationComplete;

  /// No description provided for @translationSearchStrings.
  ///
  /// In bg, this message translates to:
  /// **'Търсене...'**
  String get translationSearchStrings;

  /// No description provided for @languageInterface.
  ///
  /// In bg, this message translates to:
  /// **'Език на интерфейса'**
  String get languageInterface;

  /// No description provided for @editWith.
  ///
  /// In bg, this message translates to:
  /// **'Редактирай:'**
  String get editWith;

  /// No description provided for @yes.
  ///
  /// In bg, this message translates to:
  /// **'Да'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In bg, this message translates to:
  /// **'Не'**
  String get no;

  /// No description provided for @postpone.
  ///
  /// In bg, this message translates to:
  /// **'Отложи'**
  String get postpone;

  /// No description provided for @note.
  ///
  /// In bg, this message translates to:
  /// **'Бележка'**
  String get note;

  /// No description provided for @clear.
  ///
  /// In bg, this message translates to:
  /// **'Изчисти'**
  String get clear;

  /// No description provided for @restore.
  ///
  /// In bg, this message translates to:
  /// **'Възстанови'**
  String get restore;

  /// No description provided for @deleting.
  ///
  /// In bg, this message translates to:
  /// **'Изтриване'**
  String get deleting;

  /// No description provided for @restoreTitle.
  ///
  /// In bg, this message translates to:
  /// **'Възстановяване'**
  String get restoreTitle;

  /// No description provided for @restoreConfirm.
  ///
  /// In bg, this message translates to:
  /// **'Това ще замести всички текущи бележки с данни от архива. Продължи?'**
  String get restoreConfirm;

  /// No description provided for @localBackupReminder.
  ///
  /// In bg, this message translates to:
  /// **'Напомняне на всеки {days} дни'**
  String localBackupReminder(Object days);

  /// No description provided for @confirmDeleteRecord.
  ///
  /// In bg, this message translates to:
  /// **'Сигурни ли сте, че искате да изтриете този запис?'**
  String get confirmDeleteRecord;

  /// No description provided for @localFileWarning.
  ///
  /// In bg, this message translates to:
  /// **'Внимание: Локалното копие на файла ({fileName}) също ще бъде изтрито от паметта на приложението.'**
  String localFileWarning(Object fileName);

  /// No description provided for @deleteRecordTooltip.
  ///
  /// In bg, this message translates to:
  /// **'Изтрий записа от БД'**
  String get deleteRecordTooltip;

  /// No description provided for @databaseEmpty.
  ///
  /// In bg, this message translates to:
  /// **'Базата данни е празна.'**
  String get databaseEmpty;

  /// No description provided for @recordInfo.
  ///
  /// In bg, this message translates to:
  /// **'Запис {n} от {m}'**
  String recordInfo(Object m, Object n);

  /// No description provided for @fileNotFound.
  ///
  /// In bg, this message translates to:
  /// **'Файлът не е намерен'**
  String get fileNotFound;

  /// No description provided for @deleteFileTitle.
  ///
  /// In bg, this message translates to:
  /// **'Изтриване на файл'**
  String get deleteFileTitle;

  /// No description provided for @deleteFileConfirm.
  ///
  /// In bg, this message translates to:
  /// **'Сигурни ли сте? Това ще изтрие физическия файл от паметта. Ако той е свързан с бележка, тя вече няма да го показва.'**
  String get deleteFileConfirm;

  /// No description provided for @fileInfo.
  ///
  /// In bg, this message translates to:
  /// **'Файл {n} от {m}\n{fileName}\nРазмер: {size}'**
  String fileInfo(Object fileName, Object m, Object n, Object size);

  /// No description provided for @backupReminderMessage.
  ///
  /// In bg, this message translates to:
  /// **'Последният бекъп е преди {days} дни. Желаете ли да архивирате данните си?'**
  String backupReminderMessage(Object days);

  /// No description provided for @tagsForNote.
  ///
  /// In bg, this message translates to:
  /// **'Етикети за \"{title}\"'**
  String tagsForNote(Object title);

  /// No description provided for @newTagColon.
  ///
  /// In bg, this message translates to:
  /// **'Нов етикет:'**
  String get newTagColon;

  /// No description provided for @copiedResult.
  ///
  /// In bg, this message translates to:
  /// **'{expr} {result} (Копирано)'**
  String copiedResult(Object expr, Object result);

  /// No description provided for @calculationError.
  ///
  /// In bg, this message translates to:
  /// **'Грешка при изчисление: {expr}'**
  String calculationError(Object expr);

  /// No description provided for @saveError.
  ///
  /// In bg, this message translates to:
  /// **'Грешка запис: {error}'**
  String saveError(Object error);

  /// No description provided for @orphanedImagesFound.
  ///
  /// In bg, this message translates to:
  /// **'Намерени са {count} неизползвани снимки'**
  String orphanedImagesFound(Object count);

  /// No description provided for @noLocalArchivesInDownloads.
  ///
  /// In bg, this message translates to:
  /// **'Няма намерени локални архиви в Downloads'**
  String get noLocalArchivesInDownloads;

  /// No description provided for @noGoogleDriveBackups.
  ///
  /// In bg, this message translates to:
  /// **'Няма намерени архиви в Google Drive'**
  String get noGoogleDriveBackups;

  /// No description provided for @noArchives.
  ///
  /// In bg, this message translates to:
  /// **'Няма архиви'**
  String get noArchives;

  /// No description provided for @deleteBackupConfirmName.
  ///
  /// In bg, this message translates to:
  /// **'Изтрий архива {name}?'**
  String deleteBackupConfirmName(Object name);

  /// No description provided for @deleteFileConfirmName.
  ///
  /// In bg, this message translates to:
  /// **'Изтрий {name}?'**
  String deleteFileConfirmName(Object name);

  /// No description provided for @orphanedImagesCount.
  ///
  /// In bg, this message translates to:
  /// **'Неизползвани снимки ({count})'**
  String orphanedImagesCount(Object count);

  /// No description provided for @deleteAllOrphans.
  ///
  /// In bg, this message translates to:
  /// **'Изтриване на всички'**
  String get deleteAllOrphans;

  /// No description provided for @deleteOrphansConfirm.
  ///
  /// In bg, this message translates to:
  /// **'Изтрий {count} неизползвани снимки?'**
  String deleteOrphansConfirm(Object count);

  /// No description provided for @selectLanguage.
  ///
  /// In bg, this message translates to:
  /// **'Избор на език'**
  String get selectLanguage;

  /// No description provided for @searchLanguage.
  ///
  /// In bg, this message translates to:
  /// **'Търсене на език...'**
  String get searchLanguage;

  /// No description provided for @enterLanguageCode.
  ///
  /// In bg, this message translates to:
  /// **'Въведи ръчно езиков код'**
  String get enterLanguageCode;

  /// No description provided for @languageCodeHint.
  ///
  /// In bg, this message translates to:
  /// **'напр. \"sv\" за шведски, \"vi\" за виетнамски'**
  String get languageCodeHint;

  /// No description provided for @genericError.
  ///
  /// In bg, this message translates to:
  /// **'Грешка: {error}'**
  String genericError(Object error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bg'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bg':
      return AppLocalizationsBg();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

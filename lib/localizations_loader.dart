import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'l10n/app_localizations.dart';
import 'l10n/app_localizations_bg.dart';

/// Custom delegate that loads translations from the filesystem at runtime.
class FilesystemLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  const FilesystemLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final fileStrings = await _loadFromFile(locale.languageCode);
    if (fileStrings != null) {
      return _AppLocalizationsFromFile(locale.languageCode, fileStrings);
    }
    return AppLocalizationsBg();
  }

  Future<Map<String, String>?> _loadFromFile(String languageCode) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = p.join(directory.path, 'l10n', 'app_$languageCode.arb');
      final file = File(filePath);

      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(content);

        final result = <String, String>{};
        for (final entry in json.entries) {
          if (!entry.key.startsWith('@')) {
            result[entry.key] = entry.value.toString();
          }
        }
        if (result.isNotEmpty) return result;
      }
    } catch (e) {
      print('Error loading filesystem translations: $e');
    }
    return null;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

/// AppLocalizations implementation backed by a runtime-loaded string map.
class _AppLocalizationsFromFile extends AppLocalizations {
  final Map<String, String> _strings;

  _AppLocalizationsFromFile(String locale, this._strings) : super(locale);

  String _g(String key) => _strings[key] ?? key;
  String _p(String key, Map<String, String> params) {
    var s = _strings[key] ?? key;
    for (final e in params.entries) {
      s = s.replaceAll('{${e.key}}', e.value);
    }
    return s;
  }

  @override String get appTitle => _g('appTitle');
  @override String get appDescription => _g('appDescription');
  @override String get searchHint => _g('searchHint');
  @override String get noNotesFound => _g('noNotesFound');
  @override String get newNote => _g('newNote');
  @override String get editNote => _g('editNote');
  @override String get viewNote => _g('viewNote');
  @override String get titleHint => _g('titleHint');
  @override String get contentHint => _g('contentHint');
  @override String get save => _g('save');
  @override String get cancel => _g('cancel');
  @override String get delete => _g('delete');
  @override String get close => _g('close');
  @override String get done => _g('done');
  @override String get confirm => _g('confirm');
  @override String get clearAll => _g('clearAll');
  @override String get back => _g('back');
  @override String get confirmDeleteNote => _g('confirmDeleteNote');
  @override String get discardChanges => _g('discardChanges');
  @override String get unsavedChanges => _g('unsavedChanges');
  @override String get discard => _g('discard');
  @override String get settings => _g('settings');
  @override String get appBackground => _g('appBackground');
  @override String get noteBackground => _g('noteBackground');
  @override String get listView => _g('listView');
  @override String get gridView => _g('gridView');
  @override String get columns => _g('columns');
  @override String get textLines => _g('textLines');
  @override String get compactView => _g('compactView');
  @override String get tabStop => _g('tabStop');
  @override String get fontSizeTitle => _g('fontSizeTitle');
  @override String get fontSizeContent => _g('fontSizeContent');
  @override String get showDate => _g('showDate');
  @override String get editor => _g('editor');
  @override String get alignmentColumn => _g('alignmentColumn');
  @override String get tagFilter => _g('tagFilter');
  @override String get filterMatchAll => _g('filterMatchAll');
  @override String get filterMatchAny => _g('filterMatchAny');
  @override String get confirmDelete => _g('confirmDelete');
  @override String get enabled => _g('enabled');
  @override String get disabled => _g('disabled');
  @override String get sharing => _g('sharing');
  @override String get maxTitleLength => _g('maxTitleLength');
  @override String get googleDriveBackup => _g('googleDriveBackup');
  @override String get backupReminder => _g('backupReminder');
  @override String get backupNow => _g('backupNow');
  @override String get restoreNow => _g('restoreNow');
  @override String get noAccount => _g('noAccount');
  @override String get backupPeriodNone => _g('backupPeriodNone');
  @override String get localBackup => _g('localBackup');
  @override String get localBackupSaved => _g('localBackupSaved');
  @override String get localBackupError => _g('localBackupError');
  @override String get unusedImages => _g('unusedImages');
  @override String get database => _g('database');
  @override String get files => _g('files');
  @override String get archiveConfirm => _g('archiveConfirm');
  @override String get restoreSuccess => _g('restoreSuccess');
  @override String get restoreError => _g('restoreError');
  @override String get noArchivesFound => _g('noArchivesFound');
  @override String get selectArchive => _g('selectArchive');
  @override String get backupSuccess => _g('backupSuccess');
  @override String get backupError => _g('backupError');
  @override String get googleSignIn => _g('googleSignIn');
  @override String get googleSignOut => _g('googleSignOut');
  @override String get signInFailed => _g('signInFailed');
  @override String get orphanedImages => _g('orphanedImages');
  @override String get orphanedImagesTitle => _g('orphanedImagesTitle');
  @override String get orphanedImagesDesc => _g('orphanedImagesDesc');
  @override String get cleanOrphans => _g('cleanOrphans');
  @override String get deleteAll => _g('deleteAll');
  @override String get deleteSingle => _g('deleteSingle');
  @override String get noOrphanedImages => _g('noOrphanedImages');
  @override String get databaseTitle => _g('databaseTitle');
  @override String get filesInMemory => _g('filesInMemory');
  @override String get noLocalFiles => _g('noLocalFiles');
  @override String get previous => _g('previous');
  @override String get next => _g('next');
  @override String get colorPicker => _g('colorPicker');
  @override String get filter => _g('filter');
  @override String get period => _g('period');
  @override String get color => _g('color');
  @override String get tasksOnly => _g('tasksOnly');
  @override String get sequentialOrder => _g('sequentialOrder');
  @override String get reverseOrder => _g('reverseOrder');
  @override String get tags => _g('tags');
  @override String get tagFilterTitle => _g('tagFilterTitle');
  @override String get noTagsAvailable => _g('noTagsAvailable');
  @override String get selectTags => _g('selectTags');
  @override String get newTag => _g('newTag');
  @override String get tagHint => _g('tagHint');
  @override String get manageTags => _g('manageTags');
  @override String get scrollUp => _g('scrollUp');
  @override String get viewToggle => _g('viewToggle');
  @override String get clearSearch => _g('clearSearch');
  @override String get filters => _g('filters');
  @override String get clearFilters => _g('clearFilters');
  @override String get addNote => _g('addNote');
  @override String get noteFormDeleteImage => _g('noteFormDeleteImage');
  @override String get noteFormCropImage => _g('noteFormCropImage');
  @override String get noteFormCropTitle => _g('noteFormCropTitle');
  @override String get noteFormGallery => _g('noteFormGallery');
  @override String get noteFormCamera => _g('noteFormCamera');
  @override String get noteFormTags => _g('noteFormTags');
  @override String get noteFormBulletList => _g('noteFormBulletList');
  @override String get noteFormNumberedList => _g('noteFormNumberedList');
  @override String get noteFormChecklist => _g('noteFormChecklist');
  @override String get noteFormTask => _g('noteFormTask');
  @override String get noteFormCopyLocal => _g('noteFormCopyLocal');
  @override String get noteFormCopyLocalDesc => _g('noteFormCopyLocalDesc');
  @override String get noteFormCopyLocalWarning => _g('noteFormCopyLocalWarning');
  @override String get noteFormCopyLocalWarningDesc => _g('noteFormCopyLocalWarningDesc');
  @override String get noteFormCopyLocalDisable => _g('noteFormCopyLocalDisable');
  @override String get noteFormMoveToTitle => _g('noteFormMoveToTitle');
  @override String get noteFormClearTitle => _g('noteFormClearTitle');
  @override String get noteFormLineStart => _g('noteFormLineStart');
  @override String get noteFormTwoDecimals => _g('noteFormTwoDecimals');
  @override String get noteFormLineEndTab => _g('noteFormLineEndTab');
  @override String get noteFormDuplicateLine => _g('noteFormDuplicateLine');
  @override String get noteFormDeleteLine => _g('noteFormDeleteLine');
  @override String get noteFormCalculator => _g('noteFormCalculator');
  @override String get noteFormEdit => _g('noteFormEdit');
  @override String get noteFormPreview => _g('noteFormPreview');
  @override String get translationTranslateInterface => _g('translationTranslateInterface');
  @override String get translationEditInterface => _g('translationEditInterface');
  @override String get translationSelectBaseLanguage => _g('translationSelectBaseLanguage');
  @override String get translationSelectTargetLanguage => _g('translationSelectTargetLanguage');
  @override String get translationTranslateAll => _g('translationTranslateAll');
  @override String get translationSaveArb => _g('translationSaveArb');
  @override String get translationComplete => _g('translationComplete');
  @override String get translationSearchStrings => _g('translationSearchStrings');
  @override String get languageInterface => _g('languageInterface');
  @override String get editWith => _g('editWith');
  @override String get yes => _g('yes');
  @override String get no => _g('no');
  @override String get postpone => _g('postpone');
  @override String get note => _g('note');
  @override String get clear => _g('clear');
  @override String get restore => _g('restore');
  @override String get deleting => _g('deleting');
  @override String get restoreTitle => _g('restoreTitle');
  @override String get restoreConfirm => _g('restoreConfirm');
  @override String get confirmDeleteRecord => _g('confirmDeleteRecord');
  @override String get deleteRecordTooltip => _g('deleteRecordTooltip');
  @override String get databaseEmpty => _g('databaseEmpty');
  @override String get fileNotFound => _g('fileNotFound');
  @override String get deleteFileTitle => _g('deleteFileTitle');
  @override String get deleteFileConfirm => _g('deleteFileConfirm');
  @override String get newTagColon => _g('newTagColon');
  @override String get noLocalArchivesInDownloads => _g('noLocalArchivesInDownloads');
  @override String get noGoogleDriveBackups => _g('noGoogleDriveBackups');
  @override String get noArchives => _g('noArchives');
  @override String get deleteAllOrphans => _g('deleteAllOrphans');
  @override String get selectLanguage => _g('selectLanguage');
  @override String get searchLanguage => _g('searchLanguage');
  @override String get enterLanguageCode => _g('enterLanguageCode');
  @override String get languageCodeHint => _g('languageCodeHint');

  @override String translationProgress(Object current, Object total) => _p('translationProgress', {'current': current.toString(), 'total': total.toString()});
  @override String localBackupReminder(Object days) => _p('localBackupReminder', {'days': days.toString()});
  @override String recordInfo(Object m, Object n) => _p('recordInfo', {'m': m.toString(), 'n': n.toString()});
  @override String fileInfo(Object fileName, Object m, Object n, Object size) => _p('fileInfo', {'fileName': fileName.toString(), 'm': m.toString(), 'n': n.toString(), 'size': size.toString()});
  @override String backupReminderMessage(Object days) => _p('backupReminderMessage', {'days': days.toString()});
  @override String tagsForNote(Object title) => _p('tagsForNote', {'title': title.toString()});
  @override String copiedResult(Object expr, Object result) => _p('copiedResult', {'expr': expr.toString(), 'result': result.toString()});
  @override String calculationError(Object expr) => _p('calculationError', {'expr': expr.toString()});
  @override String saveError(Object error) => _p('saveError', {'error': error.toString()});
  @override String orphanedImagesFound(Object count) => _p('orphanedImagesFound', {'count': count.toString()});
  @override String deleteBackupConfirmName(Object name) => _p('deleteBackupConfirmName', {'name': name.toString()});
  @override String deleteFileConfirmName(Object name) => _p('deleteFileConfirmName', {'name': name.toString()});
  @override String localFileWarning(Object fileName) => _p('localFileWarning', {'fileName': fileName.toString()});
  @override String orphanedImagesCount(Object count) => _p('orphanedImagesCount', {'count': count.toString()});
  @override String deleteOrphansConfirm(Object count) => _p('deleteOrphansConfirm', {'count': count.toString()});
  @override String genericError(Object error) => _p('genericError', {'error': error.toString()});
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'color_picker_helper.dart';
import 'db_viewer.dart';
import 'fly_menu.dart';
import 'local_files_viewer.dart';
import 'google_drive_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _appBgColor = Colors.white.toARGB32();
  int _defaultNoteColor = Colors.white.toARGB32();
  bool _filterMatchAll = false;
  bool _confirmDelete = true;
  bool _compactGridView = false;
  bool _showDate = false;
  int _listColumns = 1;
  int _gridColumns = 2;
  int _maxLinesList = 5;
  int _maxLinesGrid = 5;
  double _fontSizeListTitle = 14;
  double _fontSizeListContent = 13;
  double _fontSizeFormTitle = 18;
  double _fontSizeFormContent = 16;
  int _maxTitleLength = 70;
  int _alignmentColumn = 30;
  int _gridWidthOffset = 10;
  int _backupPeriodDays = 0;
  final TextEditingController _listLinesController = TextEditingController();
  final TextEditingController _gridLinesController = TextEditingController();
  final TextEditingController _listColumnsController = TextEditingController();
  final TextEditingController _gridColumnsController = TextEditingController();
  final TextEditingController _listTitleSizeController = TextEditingController();
  final TextEditingController _listContentSizeController = TextEditingController();
  final TextEditingController _formTitleSizeController = TextEditingController();
  final TextEditingController _formContentSizeController = TextEditingController();
  final TextEditingController _maxTitleLengthController = TextEditingController();
  final TextEditingController _alignmentColumnController = TextEditingController();
  final TextEditingController _gridWidthOffsetController = TextEditingController();
  final TextEditingController _backupPeriodController = TextEditingController();
  final List<Color> _availableColors = [
    Colors.white, const Color(0xFF0A1931), const Color(0xFFFF5E00), 
    const Color(0xFFFFC93C), const Color(0xFF6A2C70), const Color(0xFFB83B5E), 
    const Color(0xFF005082), Colors.black,
  ];
  List<Color> _customPalette = [];
  final GoogleDriveHelper _driveHelper = GoogleDriveHelper();
  String? _googleAccountEmail;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isSavingLocal = false;
  bool _isRestoringLocal = false;

  Color get _textColor => Color(_appBgColor).computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  Color get _secondaryTextColor => Color(_appBgColor).computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkGoogleAccount();
  }

  Future<void> _checkGoogleAccount() async {
    final email = await _driveHelper.getSignedInEmail();
    if (mounted) setState(() => _googleAccountEmail = email);
  }

  Future<void> _signInGoogle() async {
    final success = await _driveHelper.signIn();
    if (success) {
      await _checkGoogleAccount();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неуспешно влизане в Google акаунт')));
    }
  }

  Future<void> _signOutGoogle() async {
    await _driveHelper.signOut();
    if (mounted) setState(() => _googleAccountEmail = null);
  }

  Future<void> _performBackup() async {
    if (_googleAccountEmail == null) {
      await _signInGoogle();
      if (_googleAccountEmail == null) return;
    }
    if (!mounted) return;
    setState(() => _isBackingUp = true);
    try {
      final orphanCount = await _driveHelper.findOrphanedImages();
      bool cleanOrphans = false;
      if (orphanCount > 0 && mounted) {
        cleanOrphans = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Color(_appBgColor),
            title: Text('Намерени са $orphanCount неизползвани снимки', style: TextStyle(color: _textColor)),
            content: Text('Тези снимки не са свързани с никоя бележка. Да бъдат ли изчистени преди архивирането?', style: TextStyle(color: _secondaryTextColor)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Не', style: TextStyle(color: _secondaryTextColor))),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Да, изчисти', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ?? false;
      }
      if (cleanOrphans) await _driveHelper.deleteOrphanedImages();
      final success = await _driveHelper.backupToDrive();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Архивирането е успешно!' : 'Грешка при архивиране'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_backup_date', DateTime.now().toIso8601String());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Грешка: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _performLocalBackup() async {
    if (!mounted) return;
    setState(() => _isSavingLocal = true);
    try {
      final path = await _driveHelper.saveBackupLocally();
      if (mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Архивът е записан в папка\nИзтегляния/my_memo_backups', style: TextStyle(fontSize: 12)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Грешка при записване'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Грешка: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSavingLocal = false);
    }
  }

  Future<void> _performLocalRestore() async {
    if (!mounted) return;
    setState(() => _isRestoringLocal = true);
    try {
      final localBackups = _driveHelper.listLocalBackups();
      if (!mounted) return;
      if (localBackups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Няма намерени локални архиви в Downloads'), backgroundColor: Colors.orange));
        setState(() => _isRestoringLocal = false);
        return;
      }
      final selectedPath = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Color(_appBgColor),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Text('Избор на архив', style: TextStyle(color: _textColor)),
          contentPadding: EdgeInsets.zero,
          content: StatefulBuilder(
            builder: (ctx, setDialogState) => SizedBox(
              width: MediaQuery.of(context).size.width * 0.95,
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: localBackups.length,
                itemBuilder: (ctx, index) {
                  final file = localBackups[index];
                  final name = p.basename(file.path);
                  final modDate = file.lastModifiedSync();
                  final dateStr = '${modDate.year}-${modDate.month.toString().padLeft(2, '0')}-${modDate.day.toString().padLeft(2, '0')} ${modDate.hour.toString().padLeft(2, '0')}:${modDate.minute.toString().padLeft(2, '0')}';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    title: Text(name, style: TextStyle(color: _textColor, fontSize: 13)),
                    subtitle: Text(dateStr, style: TextStyle(color: _secondaryTextColor, fontSize: 11)),
                    dense: true,
                    onTap: () => Navigator.pop(ctx, file.path),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final del = await showDialog<bool>(
                          context: context,
                          builder: (d) => AlertDialog(
                            backgroundColor: Color(_appBgColor),
                            title: Text('Изтриване', style: TextStyle(color: _textColor)),
                            content: Text('Изтрий $name?', style: TextStyle(color: _secondaryTextColor)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(d, false), child: Text('Отказ', style: TextStyle(color: _secondaryTextColor))),
                              TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Изтрий', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ) ?? false;
                        if (del) {
                          try { await file.delete(); } catch (e) {}
                          setDialogState(() => localBackups.removeAt(index));
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отказ', style: TextStyle(color: _secondaryTextColor))),
          ],
        ),
      );
      if (selectedPath == null) {
        setState(() => _isRestoringLocal = false);
        return;
      }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Color(_appBgColor),
          title: Text('Възстановяване', style: TextStyle(color: _textColor)),
          content: Text('Това ще замести всички текущи бележки с данни от архива. Продължи?', style: TextStyle(color: _secondaryTextColor)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Отказ', style: TextStyle(color: _secondaryTextColor))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Възстанови', style: TextStyle(color: Colors.blue))),
          ],
        ),
      ) ?? false;
      if (!confirm) {
        setState(() => _isRestoringLocal = false);
        return;
      }
      final success = await _driveHelper.restoreFromLocal(selectedPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Възстановяването е успешно!' : 'Грешка при възстановяване'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
        if (success) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Грешка: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isRestoringLocal = false);
    }
  }

  Future<void> _performRestore() async {
    if (_googleAccountEmail == null) {
      await _signInGoogle();
      if (_googleAccountEmail == null) return;
    }
    if (!mounted) return;
    setState(() => _isRestoring = true);
    try {
      final backups = await _driveHelper.listBackups();
      if (!mounted) return;
      if (backups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Няма намерени архиви в Google Drive'), backgroundColor: Colors.orange));
        setState(() => _isRestoring = false);
        return;
      }
      final selectedId = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Color(_appBgColor),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Text('Избор на архив', style: TextStyle(color: _textColor)),
          contentPadding: EdgeInsets.zero,
          content: StatefulBuilder(
            builder: (ctx, setDialogState) => SizedBox(
              width: MediaQuery.of(context).size.width * 0.95,
              child: backups.isEmpty
                  ? const Center(child: Text('Няма архиви'))
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: backups.length,
                      itemBuilder: (ctx, index) {
                        final backup = backups[index];
                        final utcDate = DateTime.parse(backup['date']!);
                        final localDate = utcDate.toLocal();
                        final date = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
                        final time = '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          title: Text(backup['name']!, style: TextStyle(color: _textColor, fontSize: 14)),
                          subtitle: Text('$date $time', style: TextStyle(color: _secondaryTextColor, fontSize: 12)),
                          dense: true,
                          onTap: () => Navigator.pop(ctx, backup['id']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final del = await showDialog<bool>(
                                context: context,
                                builder: (d) => AlertDialog(
                                  backgroundColor: Color(_appBgColor),
                                  title: Text('Изтриване', style: TextStyle(color: _textColor)),
                                  content: Text('Изтрий архива ${backup['name']}?', style: TextStyle(color: _secondaryTextColor)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(d, false), child: Text('Отказ', style: TextStyle(color: _secondaryTextColor))),
                                    TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Изтрий', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ) ?? false;
                              if (del) {
                                await _driveHelper.deleteBackup(backup['id']!);
                                setDialogState(() => backups.removeAt(index));
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отказ', style: TextStyle(color: _secondaryTextColor))),
          ],
        ),
      );
      if (selectedId == null) {
        setState(() => _isRestoring = false);
        return;
      }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Color(_appBgColor),
          title: Text('Възстановяване', style: TextStyle(color: _textColor)),
          content: Text('Това ще замести всички текущи бележки с данни от архива. Продължи?', style: TextStyle(color: _secondaryTextColor)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Отказ', style: TextStyle(color: _secondaryTextColor))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Възстанови', style: TextStyle(color: Colors.blue))),
          ],
        ),
      ) ?? false;
      if (!confirm) {
        setState(() => _isRestoring = false);
        return;
      }
      final success = await _driveHelper.restoreFromDrive(fileId: selectedId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Възстановяването е успешно!' : 'Грешка при възстановяване'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
        if (success) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Грешка: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  void dispose() {
    _listLinesController.dispose(); _gridLinesController.dispose();
    _listColumnsController.dispose(); _gridColumnsController.dispose();
    _listTitleSizeController.dispose(); _listContentSizeController.dispose();
    _formTitleSizeController.dispose(); _formContentSizeController.dispose();
    _maxTitleLengthController.dispose(); _alignmentColumnController.dispose();
    _gridWidthOffsetController.dispose(); _backupPeriodController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings({bool updateControllers = true}) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appBgColor = prefs.getInt('bg_color') ?? Colors.white.toARGB32();
      _defaultNoteColor = prefs.getInt('default_note_color') ?? Colors.white.toARGB32();
      _filterMatchAll = prefs.getBool('filter_match_all') ?? false;
      _confirmDelete = prefs.getBool('confirm_delete') ?? true;
      _compactGridView = prefs.getBool('compact_grid_view') ?? false;
      _showDate = prefs.getBool('show_date') ?? false;
      _listColumns = prefs.getInt('list_columns') ?? 1;
      _gridColumns = prefs.getInt('grid_columns') ?? 2;
      _maxLinesList = prefs.getInt('max_lines_list') ?? 5;
      _maxLinesGrid = prefs.getInt('max_lines_grid') ?? 5;
      _fontSizeListTitle = prefs.getDouble('list_title_size') ?? 14;
      _fontSizeListContent = prefs.getDouble('list_content_size') ?? 13;
      _fontSizeFormTitle = prefs.getDouble('form_title_size') ?? 18;
      _fontSizeFormContent = prefs.getDouble('form_content_size') ?? 16;
      _maxTitleLength = prefs.getInt('max_title_length') ?? 70;
      _alignmentColumn = prefs.getInt('alignment_column') ?? 30;
      _gridWidthOffset = prefs.getInt('grid_width_offset') ?? 10;
      _backupPeriodDays = prefs.getInt('backup_period_days') ?? 0;
      final customList = prefs.getStringList('custom_palette') ?? [];
      _customPalette = customList.map((s) => Color(int.parse(s))).toList();
      if (updateControllers) {
        _backupPeriodController.text = _backupPeriodDays.toString();
        _listLinesController.text = _maxLinesList.toString();
        _gridLinesController.text = _maxLinesGrid.toString();
        _listColumnsController.text = _listColumns.toString();
        _gridColumnsController.text = _gridColumns.toString();
        _listTitleSizeController.text = _fontSizeListTitle.toInt().toString();
        _listContentSizeController.text = _fontSizeListContent.toInt().toString();
        _formTitleSizeController.text = _fontSizeFormTitle.toInt().toString();
        _formContentSizeController.text = _fontSizeFormContent.toInt().toString();
        _maxTitleLengthController.text = _maxTitleLength.toString();
        _alignmentColumnController.text = _alignmentColumn.toString();
        _gridWidthOffsetController.text = _gridWidthOffset.toString();
      }
      if (!_availableColors.contains(Color(_appBgColor))) _availableColors.add(Color(_appBgColor));
      if (!_availableColors.contains(Color(_defaultNoteColor))) _availableColors.add(Color(_defaultNoteColor));
    });
  }

  Future<void> _saveAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bg_color', _appBgColor);
    await prefs.setInt('default_note_color', _defaultNoteColor);
    await prefs.setBool('filter_match_all', _filterMatchAll);
    await prefs.setBool('confirm_delete', _confirmDelete);
    await prefs.setBool('compact_grid_view', _compactGridView);
    await prefs.setBool('show_date', _showDate);
    await prefs.setInt('list_columns', _listColumns);
    await prefs.setInt('grid_columns', _gridColumns);
    await prefs.setInt('max_lines_list', _maxLinesList);
    await prefs.setInt('max_lines_grid', _maxLinesGrid);
    await prefs.setDouble('list_title_size', _fontSizeListTitle);
    await prefs.setDouble('list_content_size', _fontSizeListContent);
    await prefs.setDouble('form_title_size', _fontSizeFormTitle);
    await prefs.setDouble('form_content_size', _fontSizeFormContent);
    await prefs.setInt('max_title_length', _maxTitleLength);
    await prefs.setInt('alignment_column', _alignmentColumn);
    await prefs.setInt('grid_width_offset', _gridWidthOffset);
    await prefs.setInt('backup_period_days', _backupPeriodDays);
    await prefs.setStringList('custom_palette', _customPalette.map((c) => c.toARGB32().toString()).toList());
    if (mounted) Navigator.pop(context);
  }

  void _revertAndExit() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(_appBgColor),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Color(_appBgColor),
        foregroundColor: _textColor,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset('assets/app_icon_0.png', fit: BoxFit.contain),
        ),
        leadingWidth: 46,
        title: Text('Настройки', style: TextStyle(color: _textColor)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: _revertAndExit, tooltip: 'Отказ'),
          IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _saveAllSettings, tooltip: 'Потвърждение'),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(10, 10, 5, 10),
            children: [
              _buildSectionTitle('Фон на приложението'),
              const SizedBox(height: 10),
              _buildColorPicker(selectedColor: _appBgColor, onColorSelected: (color) => setState(() => _appBgColor = color.toARGB32())),
              Divider(height: 30, color: _secondaryTextColor.withValues(alpha: 0.2)),
              _buildSectionTitle('Фон на бележките'),
              const SizedBox(height: 10),
              _buildColorPicker(selectedColor: _defaultNoteColor, onColorSelected: (color) => setState(() => _defaultNoteColor = color.toARGB32())),
              Divider(height: 30, color: _secondaryTextColor.withValues(alpha: 0.2)),
              _buildSectionTitle('Списък'),
              _buildNumberInput(title: 'Брой колони', controller: _listColumnsController, min: 1, max: 10, onChanged: (val) => setState(() => _listColumns = val)),
              _buildNumberInput(title: 'Брой редове текст', controller: _listLinesController, min: 1, max: 20, onChanged: (val) => setState(() => _maxLinesList = val)),
              _buildSectionTitle('Матрица'),
              _buildNumberInput(title: 'Брой колони', controller: _gridColumnsController, min: 1, max: 10, onChanged: (val) => setState(() => _gridColumns = val)),
              _buildNumberInput(title: 'Брой редове текст', controller: _gridLinesController, min: 1, max: 20, onChanged: (val) => setState(() => _maxLinesGrid = val)),
              _buildSwitchInput(title: 'Компактен вид', value: _compactGridView, onChanged: (val) => setState(() => _compactGridView = val)),
              _buildNumberInput(title: 'Таб стоп', controller: _gridWidthOffsetController, min: 0, max: 50, onChanged: (val) => setState(() => _gridWidthOffset = val)),
              const SizedBox(height: 10),
              Divider(height: 30, color: _secondaryTextColor.withValues(alpha: 0.2)),
              _buildSectionTitle('Бележки на основния екран'),
              _buildNumberInput(title: 'Размер шрифт заглавие', controller: _listTitleSizeController, min: 10, max: 30, onChanged: (val) => setState(() => _fontSizeListTitle = val.toDouble())),
              _buildNumberInput(title: 'Размер шрифт текст', controller: _listContentSizeController, min: 8, max: 25, onChanged: (val) => setState(() => _fontSizeListContent = val.toDouble())),
              _buildSwitchInput(title: 'Показване на датата', value: _showDate, onChanged: (val) => setState(() => _showDate = val)),
              Divider(height: 30, color: _secondaryTextColor.withValues(alpha: 0.2)),
              _buildSectionTitle('Редактор'),
              _buildNumberInput(title: 'Размер шрифт заглавие', controller: _formTitleSizeController, min: 14, max: 40, onChanged: (val) => setState(() => _fontSizeFormTitle = val.toDouble())),
              _buildNumberInput(title: 'Размер шрифт текст', controller: _formContentSizeController, min: 10, max: 35, onChanged: (val) => setState(() => _fontSizeFormContent = val.toDouble())),
              _buildNumberInput(title: 'Подравняване в колона', controller: _alignmentColumnController, min: 10, max: 100, onChanged: (val) => setState(() => _alignmentColumn = val)),
              Divider(height: 30, color: _secondaryTextColor.withValues(alpha: 0.2)),
              _buildSectionTitle('Филтриране по етикети'),
              _buildSwitchInput(
                title: _filterMatchAll ? 'ВСИЧКИ избрани' : 'ПОНЕ ЕДИН от избраните',
                value: _filterMatchAll,
                onChanged: (val) => setState(() => _filterMatchAll = val),
              ),
              Divider(height: 30, color: _secondaryTextColor.withValues(alpha: 0.2)),
              _buildSectionTitle('Потвърждение при изтриване'),
              _buildSwitchInput(
                title: _confirmDelete ? 'Включено' : 'Изключено',
                value: _confirmDelete,
                onChanged: (val) => setState(() => _confirmDelete = val),
              ),
              Divider(height: 30, color: _secondaryTextColor.withValues(alpha: 0.2)),
              _buildSectionTitle('Споделяне'),
              _buildNumberInput(title: 'Дължина на заглавие', controller: _maxTitleLengthController, min: 10, max: 500, onChanged: (val) => setState(() => _maxTitleLength = val)),
              Divider(height: 30, color: _secondaryTextColor.withValues(alpha: 0.2)),
              _buildSectionTitle('Архивиране в Google Drive'),
              if (_googleAccountEmail != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.account_circle, size: 18, color: _secondaryTextColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_googleAccountEmail!, style: TextStyle(fontSize: 12, color: _secondaryTextColor), overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: Icon(Icons.logout, size: 18, color: _textColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _signOutGoogle,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.account_circle_outlined, size: 18, color: _secondaryTextColor),
                      const SizedBox(width: 8),
                      Text('Няма свързан акаунт', style: TextStyle(fontSize: 12, color: _secondaryTextColor)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.login, size: 18, color: _textColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _signInGoogle,
                      ),
                    ],
                  ),
                ),
              ],
              _buildNumberInput(title: 'Напомняне (дни)', controller: _backupPeriodController, min: 0, max: 365, onChanged: (val) => setState(() => _backupPeriodDays = val)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Text(_backupPeriodDays == 0 ? 'Изключено' : 'Напомняне на всеки $_backupPeriodDays дни', style: TextStyle(fontSize: 11, color: _secondaryTextColor)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isBackingUp ? null : _performBackup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(_appBgColor).computeLuminance() > 0.5 ? Colors.blue : Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: _isBackingUp
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload, size: 16), SizedBox(width: 4), Text('Архивирай')]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRestoring ? null : _performRestore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(_appBgColor).computeLuminance() > 0.5 ? Colors.orange : Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: _isRestoring
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_download, size: 16), SizedBox(width: 4), Text('Възстанови')]),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 30, color: _secondaryTextColor.withValues(alpha: 0.2)),
              _buildSectionTitle('Локален архив'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSavingLocal ? null : _performLocalBackup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(_appBgColor).computeLuminance() > 0.5 ? Colors.teal : Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: _isSavingLocal
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.save_alt, size: 16), SizedBox(width: 4), Text('Архивирай')]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRestoringLocal ? null : _performLocalRestore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(_appBgColor).computeLuminance() > 0.5 ? Colors.teal : Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: _isRestoringLocal
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.restore, size: 16), SizedBox(width: 4), Text('Възстанови')]),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 30, color: _secondaryTextColor.withValues(alpha: 0.2)),
              ListTile(
                leading: Icon(Icons.broken_image_outlined, size: 20, color: _textColor),
                title: Text('Неизползвани снимки', style: TextStyle(color: _textColor)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrphanedImagesScreen())),
              ),
              ListTile(leading: Icon(Icons.storage, size: 20, color: _textColor), title: Text('База данни', style: TextStyle(color: _textColor)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DbViewerScreen()))),
              ListTile(leading: Icon(Icons.folder_open, size: 20, color: _textColor), title: Text('Файлове', style: TextStyle(color: _textColor)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LocalFilesViewerScreen()))),
              const SizedBox(height: 80),
            ],
          ),
          FlyMenu(
            actions: [
              FlyAction(icon: Icons.close, onTap: _revertAndExit, label: "Отказ"),
              FlyAction(icon: Icons.check, onTap: _saveAllSettings, label: "Запази"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({required String title, required TextEditingController controller, required int min, required int max, required Function(int) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: _textColor)),
          SizedBox(
            width: 50,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textColor),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: _secondaryTextColor.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.blue)),
              ),
              onChanged: (val) {
                int? parsed = int.tryParse(val);
                if (parsed != null) onChanged(parsed.clamp(min, max));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchInput({required String title, required bool value, required Function(bool) onChanged}) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: TextStyle(fontSize: 13, color: _textColor))),
            SizedBox(
              width: 50,
              child: Transform.scale(
                scale: 0.8, // Намаляваме малко мащаба, за да пасне на компактния вид на полетата
                child: Switch(
                  value: value,
                  activeThumbColor: Colors.blue,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 8, top: 12), child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(_appBgColor).computeLuminance() > 0.5 ? Colors.blueGrey : Colors.blueAccent)));

  Widget _buildColorPicker({required int selectedColor, required Function(Color) onColorSelected}) {
    final List<Color> allColors = [..._availableColors, ..._customPalette];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        ...allColors.map((color) {
          bool isSelected = selectedColor == color.toARGB32();
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.blue : (_textColor.withValues(alpha: 0.2)), width: isSelected ? 2 : 1),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.blue, size: 20) : null,
            ),
          );
        }),
        GestureDetector(
          onTap: () async {
            final picked = await showCustomColorPicker(context, Color(selectedColor));
            if (picked != null) {
              setState(() { 
                if (!_availableColors.contains(picked) && !_customPalette.contains(picked)) {
                  _customPalette.insert(0, picked);
                  if (_customPalette.length > 8) _customPalette.removeLast();
                }
              });
              onColorSelected(picked);
            }
          },
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: isSelectedColorBright(selectedColor) ? Colors.white : Colors.grey[800], shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]),
            child: const Icon(Icons.colorize, color: Colors.blue, size: 18),
          ),
        ),
      ],
    );
  }
  bool isSelectedColorBright(int color) => Color(color).computeLuminance() > 0.5;
}

class OrphanedImagesScreen extends StatefulWidget {
  const OrphanedImagesScreen({super.key});
  @override
  State<OrphanedImagesScreen> createState() => _OrphanedImagesScreenState();
}

class _OrphanedImagesScreenState extends State<OrphanedImagesScreen> {
  final GoogleDriveHelper _driveHelper = GoogleDriveHelper();
  List<String> _orphanPaths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrphans();
  }

  Future<void> _loadOrphans() async {
    setState(() => _isLoading = true);
    final paths = await _driveHelper.getOrphanedImagePaths();
    if (mounted) setState(() { _orphanPaths = paths; _isLoading = false; });
  }

  Future<void> _deleteSingle(String path) async {
    try { await File(path).delete(); } catch (e) {}
    setState(() => _orphanPaths.remove(path));
  }

  Future<void> _deleteAll() async {
    for (final path in _orphanPaths) {
      try { await File(path).delete(); } catch (e) {}
    }
    setState(() => _orphanPaths.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Неизползвани снимки (${_orphanPaths.length})'),
        actions: [
          if (_orphanPaths.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Изтриване на всички'),
                    content: Text('Изтрий ${_orphanPaths.length} неизползвани снимки?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отказ')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Изтрий', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ) ?? false;
                if (confirm) await _deleteAll();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orphanPaths.isEmpty
                  ? const Center(child: Text('Няма неизползвани снимки'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _orphanPaths.length,
                      itemBuilder: (ctx, index) {
                        final path = _orphanPaths[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(File(path), width: 56, height: 56, fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                            ), // title: Text(path.split(Platform.pathSeparator).last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                            title: Text(path.split(Platform.pathSeparator).last, maxLines: 2, style: const TextStyle(fontSize: 13)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteSingle(path),
                            ),
                          ),
                        );
                      },
                    ),
          FlyMenu(
            actions: [
              FlyAction(icon: Icons.arrow_back, onTap: () => Navigator.pop(context), label: "Назад"),
            ],
          ),
        ],
      ),
    );
  }
}

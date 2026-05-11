import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color_picker_helper.dart';
import 'db_viewer.dart';
import 'fly_menu.dart';
import 'local_files_viewer.dart';

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
  int _maxLinesList = 5;
  int _maxLinesGrid = 5;
  double _fontSizeListTitle = 14;
  double _fontSizeListContent = 13;
  double _fontSizeFormTitle = 18;
  double _fontSizeFormContent = 16;
  int _maxTitleLength = 70;
  final TextEditingController _listLinesController = TextEditingController();
  final TextEditingController _gridLinesController = TextEditingController();
  final TextEditingController _listTitleSizeController = TextEditingController();
  final TextEditingController _listContentSizeController = TextEditingController();
  final TextEditingController _formTitleSizeController = TextEditingController();
  final TextEditingController _formContentSizeController = TextEditingController();
  final TextEditingController _maxTitleLengthController = TextEditingController();
  final List<Color> _availableColors = [
    Colors.white, const Color(0xFF0A1931), const Color(0xFFFF5E00), 
    const Color(0xFFFFC93C), const Color(0xFF6A2C70), const Color(0xFFB83B5E), 
    const Color(0xFF005082), Colors.black,
  ];
  List<Color> _customPalette = [];

  Color get _textColor => Color(_appBgColor).computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  Color get _secondaryTextColor => Color(_appBgColor).computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _listLinesController.dispose(); _gridLinesController.dispose();
    _listTitleSizeController.dispose(); _listContentSizeController.dispose();
    _formTitleSizeController.dispose(); _formContentSizeController.dispose();
    _maxTitleLengthController.dispose();
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
      _maxLinesList = prefs.getInt('max_lines_list') ?? 5;
      _maxLinesGrid = prefs.getInt('max_lines_grid') ?? 5;
      _fontSizeListTitle = prefs.getDouble('list_title_size') ?? 14;
      _fontSizeListContent = prefs.getDouble('list_content_size') ?? 13;
      _fontSizeFormTitle = prefs.getDouble('form_title_size') ?? 18;
      _fontSizeFormContent = prefs.getDouble('form_content_size') ?? 16;
      _maxTitleLength = prefs.getInt('max_title_length') ?? 70;
      final customList = prefs.getStringList('custom_palette') ?? [];
      _customPalette = customList.map((s) => Color(int.parse(s))).toList();
      if (updateControllers) {
        _listLinesController.text = _maxLinesList.toString();
        _gridLinesController.text = _maxLinesGrid.toString();
        _listTitleSizeController.text = _fontSizeListTitle.toInt().toString();
        _listContentSizeController.text = _fontSizeListContent.toInt().toString();
        _formTitleSizeController.text = _fontSizeFormTitle.toInt().toString();
        _formContentSizeController.text = _fontSizeFormContent.toInt().toString();
        _maxTitleLengthController.text = _maxTitleLength.toString();
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
    await prefs.setInt('max_lines_list', _maxLinesList);
    await prefs.setInt('max_lines_grid', _maxLinesGrid);
    await prefs.setDouble('list_title_size', _fontSizeListTitle);
    await prefs.setDouble('list_content_size', _fontSizeListContent);
    await prefs.setDouble('form_title_size', _fontSizeFormTitle);
    await prefs.setDouble('form_content_size', _fontSizeFormContent);
    await prefs.setInt('max_title_length', _maxTitleLength);
    await prefs.setStringList('custom_palette', _customPalette.map((c) => c.toARGB32().toString()).toList());
    if (mounted) Navigator.pop(context);
  }

  void _revertAndExit() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(_appBgColor),
      appBar: AppBar(
        backgroundColor: Color(_appBgColor),
        foregroundColor: _textColor,
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
              _buildNumberInput(title: 'Брой редове текст', controller: _listLinesController, min: 1, max: 20, onChanged: (val) => setState(() => _maxLinesList = val)),
              _buildSectionTitle('Матрица'),
              _buildNumberInput(title: 'Брой редове текст', controller: _gridLinesController, min: 1, max: 20, onChanged: (val) => setState(() => _maxLinesGrid = val)),
              _buildSwitchInput(title: 'Компактен вид', value: _compactGridView, onChanged: (val) => setState(() => _compactGridView = val)),
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
                  activeColor: Colors.blue,
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

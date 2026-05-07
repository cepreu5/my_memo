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
  int _maxLinesList = 5;
  int _maxLinesGrid = 5;
  double _fontSizeListTitle = 14;
  double _fontSizeListContent = 13;
  double _fontSizeFormTitle = 18;
  double _fontSizeFormContent = 16;
  final TextEditingController _listLinesController = TextEditingController();
  final TextEditingController _gridLinesController = TextEditingController();
  final TextEditingController _listTitleSizeController = TextEditingController();
  final TextEditingController _listContentSizeController = TextEditingController();
  final TextEditingController _formTitleSizeController = TextEditingController();
  final TextEditingController _formContentSizeController = TextEditingController();
  final List<Color> _availableColors = [
    Colors.white, const Color(0xFFF5F5F5), const Color(0xFFFFF9C4), 
    const Color(0xFFFFCCBC), const Color(0xFFC8E6C9), const Color(0xFFB3E5FC), 
    const Color(0xFFF8BBD0), const Color(0xFFE1BEE7), const Color(0xFFD7CCC8), Colors.black,
  ];

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
    super.dispose();
  }

  Future<void> _loadSettings({bool updateControllers = true}) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appBgColor = prefs.getInt('bg_color') ?? Colors.white.toARGB32();
      _defaultNoteColor = prefs.getInt('default_note_color') ?? Colors.white.toARGB32();
      _filterMatchAll = prefs.getBool('filter_match_all') ?? false;
      _confirmDelete = prefs.getBool('confirm_delete') ?? true;
      _maxLinesList = prefs.getInt('max_lines_list') ?? 5;
      _maxLinesGrid = prefs.getInt('max_lines_grid') ?? 5;
      _fontSizeListTitle = prefs.getDouble('list_title_size') ?? 14;
      _fontSizeListContent = prefs.getDouble('list_content_size') ?? 13;
      _fontSizeFormTitle = prefs.getDouble('form_title_size') ?? 18;
      _fontSizeFormContent = prefs.getDouble('form_content_size') ?? 16;
      if (updateControllers) {
        _listLinesController.text = _maxLinesList.toString();
        _gridLinesController.text = _maxLinesGrid.toString();
        _listTitleSizeController.text = _fontSizeListTitle.toInt().toString();
        _listContentSizeController.text = _fontSizeListContent.toInt().toString();
        _formTitleSizeController.text = _fontSizeFormTitle.toInt().toString();
        _formContentSizeController.text = _fontSizeFormContent.toInt().toString();
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
    await prefs.setInt('max_lines_list', _maxLinesList);
    await prefs.setInt('max_lines_grid', _maxLinesGrid);
    await prefs.setDouble('list_title_size', _fontSizeListTitle);
    await prefs.setDouble('list_content_size', _fontSizeListContent);
    await prefs.setDouble('form_title_size', _fontSizeFormTitle);
    await prefs.setDouble('form_content_size', _fontSizeFormContent);
    if (mounted) Navigator.pop(context);
  }

  void _revertAndExit() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(_appBgColor),
      appBar: AppBar(
        backgroundColor: Color(_appBgColor),
        title: const Text('Настройки'),
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
              const Divider(height: 30),
              _buildSectionTitle('Фон на бележките'),
              const SizedBox(height: 10),
              _buildColorPicker(selectedColor: _defaultNoteColor, onColorSelected: (color) => setState(() => _defaultNoteColor = color.toARGB32())),
              const Divider(height: 30),
              _buildSectionTitle('Текст и оформление'),
              _buildNumberInput(title: 'Редове в списък', controller: _listLinesController, min: 1, max: 20, onChanged: (val) => setState(() => _maxLinesList = val)),
              _buildNumberInput(title: 'Редове в матрица', controller: _gridLinesController, min: 1, max: 20, onChanged: (val) => setState(() => _maxLinesGrid = val)),
              const SizedBox(height: 10),
              _buildNumberInput(title: 'Шрифт заглавие (списък)', controller: _listTitleSizeController, min: 10, max: 30, onChanged: (val) => setState(() => _fontSizeListTitle = val.toDouble())),
              _buildNumberInput(title: 'Шрифт текст (списък)', controller: _listContentSizeController, min: 8, max: 25, onChanged: (val) => setState(() => _fontSizeListContent = val.toDouble())),
              _buildNumberInput(title: 'Шрифт заглавие (редактор)', controller: _formTitleSizeController, min: 14, max: 40, onChanged: (val) => setState(() => _fontSizeFormTitle = val.toDouble())),
              _buildNumberInput(title: 'Шрифт текст (редактор)', controller: _formContentSizeController, min: 10, max: 35, onChanged: (val) => setState(() => _fontSizeFormContent = val.toDouble())),
              const Divider(height: 30),
              _buildSectionTitle('Филтриране по етикети'),
              SwitchListTile(title: Text(_filterMatchAll ? 'ВСИЧКИ избрани' : 'ПОНЕ ЕДИН от избраните'), value: _filterMatchAll, onChanged: (val) => setState(() => _filterMatchAll = val)),
              const Divider(height: 30),
              _buildSectionTitle('Потвърждение при изтриване'),
              SwitchListTile(title: Text(_confirmDelete ? 'Включено' : 'Изключено'), value: _confirmDelete, onChanged: (val) => setState(() => _confirmDelete = val)),
              const Divider(height: 30),
              ListTile(leading: const Icon(Icons.storage, size: 20), title: const Text('База данни'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DbViewerScreen()))),
              ListTile(leading: const Icon(Icons.folder_open, size: 20), title: const Text('Файлове'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LocalFilesViewerScreen()))),
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
          Text(title, style: const TextStyle(fontSize: 13)),
          SizedBox(
            width: 50,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
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

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey)));

  Widget _buildColorPicker({required int selectedColor, required Function(Color) onColorSelected}) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        ..._availableColors.map((color) {
          bool isSelected = selectedColor == color.toARGB32();
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.blue : Colors.black12, width: isSelected ? 2 : 1),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.blue, size: 20) : null,
            ),
          );
        }),
        GestureDetector(
          onTap: () async {
            final picked = await showCustomColorPicker(context, Color(selectedColor));
            if (picked != null) {
              setState(() { if (!_availableColors.contains(picked)) _availableColors.add(picked); });
              onColorSelected(picked);
            }
          },
          child: Container(
            width: 38, height: 38,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
            child: const Icon(Icons.colorize, color: Colors.blue, size: 18),
          ),
        ),
      ],
    );
  }
}

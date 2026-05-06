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
  final TextEditingController _listLinesController = TextEditingController();
  final TextEditingController _gridLinesController = TextEditingController();
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
    _listLinesController.dispose();
    _gridLinesController.dispose();
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
      if (updateControllers) {
        _listLinesController.text = _maxLinesList.toString();
        _gridLinesController.text = _maxLinesGrid.toString();
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
              const Divider(height: 40),
              _buildSectionTitle('Фон на бележките'),
              const SizedBox(height: 10),
              _buildColorPicker(selectedColor: _defaultNoteColor, onColorSelected: (color) => setState(() => _defaultNoteColor = color.toARGB32())),
              const Divider(height: 40),
              _buildSectionTitle('Филтриране по етикети'),
              SwitchListTile(title: Text(_filterMatchAll ? 'ВСИЧКИ избрани' : 'ПОНЕ ЕДИН от избраните'), value: _filterMatchAll, onChanged: (val) => setState(() => _filterMatchAll = val)),
              const Divider(height: 40),
              _buildSectionTitle('Потвърждение при изтриване'),
              SwitchListTile(title: Text(_confirmDelete ? 'Включено' : 'Изключено'), value: _confirmDelete, onChanged: (val) => setState(() => _confirmDelete = val)),
              const Divider(height: 40),
              _buildSectionTitle('Брой редове текст'),
              const SizedBox(height: 10),
              _buildNumberInput(title: 'Списък', controller: _listLinesController, keyName: 'max_lines_list', onChanged: (val) => setState(() => _maxLinesList = val)),
              const SizedBox(height: 10),
              _buildNumberInput(title: 'Матрица', controller: _gridLinesController, keyName: 'max_lines_grid', onChanged: (val) => setState(() => _maxLinesGrid = val)),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Преглед на сурови данни'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DbViewerScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Преглед на локални файлове'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LocalFilesViewerScreen())),
              ),
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

  Widget _buildNumberInput({required String title, required TextEditingController controller, required String keyName, required Function(int) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          SizedBox(
            width: 80,
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  int finalValue = (int.tryParse(controller.text) ?? 2).clamp(2, 20);
                  controller.text = finalValue.toString();
                  onChanged(finalValue);
                }
              },
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8)),
                onChanged: (val) {
                  int? parsed = int.tryParse(val);
                  onChanged(parsed != null ? parsed.clamp(2, 20) : 2);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey));

  Widget _buildColorPicker({required int selectedColor, required Function(Color) onColorSelected}) {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: [
        ..._availableColors.map((color) {
          bool isSelected = selectedColor == color.toARGB32();
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 45, height: 45,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.blue : Colors.black12, width: isSelected ? 3 : 1),
                boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 8)] : null,
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
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
            width: 45, height: 45,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: const Icon(Icons.colorize, color: Colors.blue),
          ),
        ),
      ],
    );
  }
}

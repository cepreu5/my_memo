import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color_picker_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _appBgColor = Colors.white.toARGB32();
  int _defaultNoteColor = Colors.white.toARGB32();
  bool _filterMatchAll = false; // Логика за тагове: false = OR, true = AND
  bool _confirmDelete = true;
  int _maxLinesList = 5;
  int _maxLinesGrid = 5;
  final TextEditingController _listLinesController = TextEditingController();
  final TextEditingController _gridLinesController = TextEditingController();

  final List<Color> _availableColors = [
    Colors.white,
    const Color(0xFFF5F5F5), // Светло сиво
    const Color(0xFFFFF9C4), // Светло жълто
    const Color(0xFFFFCCBC), // Светло оранжево
    const Color(0xFFC8E6C9), // Светло зелено
    const Color(0xFFB3E5FC), // Светло синьо
    const Color(0xFFF8BBD0), // Светло розово
    const Color(0xFFE1BEE7), // Светло лилаво
    const Color(0xFFD7CCC8), // Светло кафяво
    Colors.black,
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

      if (!_availableColors.contains(Color(_appBgColor))) {
        _availableColors.add(Color(_appBgColor));
      }
      if (!_availableColors.contains(Color(_defaultNoteColor))) {
        _availableColors.add(Color(_defaultNoteColor));
      }
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
    _loadSettings(updateControllers: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 5, 10),
        children: [
          _buildSectionTitle('Фон на приложението'),
          const SizedBox(height: 10),
          _buildColorPicker(
            selectedColor: _appBgColor,
            onColorSelected: (color) => _saveSetting('bg_color', color.toARGB32()),
          ),
          const Divider(height: 40),
          _buildSectionTitle('Фон на бележките'),
          const SizedBox(height: 10),
          _buildColorPicker(
            selectedColor: _defaultNoteColor,
            onColorSelected: (color) => _saveSetting('default_note_color', color.toARGB32()),
          ),
          const Divider(height: 40),
          _buildSectionTitle('Филтриране по етикети'),
          SwitchListTile(
            // title: const Text('Стриктно филтриране (AND)'),
            title: Text(_filterMatchAll 
              ? 'ВСИЧКИ избрани' 
              : 'ПОНЕ ЕДИН от избраните'),
            value: _filterMatchAll,
            onChanged: (val) => _saveSetting('filter_match_all', val),
          ),
          const Divider(height: 40),
          _buildSectionTitle('Потвърждение при изтриване'),
          SwitchListTile(
            // title: const Text('Потвърждение при изтриване'),
            // subtitle: const Text('Изисква потвърждение преди изтриване на бележка'),
            title: Text(_confirmDelete 
              ? 'Включено' 
              : 'Изключено'),
            value: _confirmDelete,
            onChanged: (val) => _saveSetting('confirm_delete', val),
          ),
          const Divider(height: 40),
          _buildSectionTitle('Брой редове текст'),
          const SizedBox(height: 10),
          _buildNumberInput(
            title: 'Списък',
            controller: _listLinesController,
            keyName: 'max_lines_list',
            onChanged: (val) => setState(() => _maxLinesList = val),
          ),
          const SizedBox(height: 10),
          _buildNumberInput(
            title: 'Матрица',
            controller: _gridLinesController,
            keyName: 'max_lines_grid',
            onChanged: (val) => setState(() => _maxLinesGrid = val),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required String title,
    required TextEditingController controller,
    required String keyName,
    required Function(int) onChanged,
  }) {
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
                  int? parsed = int.tryParse(controller.text);
                  int finalValue = (parsed ?? 2).clamp(2, 20);
                  controller.text = finalValue.toString();
                  _saveSetting(keyName, finalValue);
                  onChanged(finalValue);
                }
              },
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
                onChanged: (val) {
                  int? parsed = int.tryParse(val);
                  if (parsed != null) {
                    int clamped = parsed.clamp(2, 20);
                    _saveSetting(keyName, clamped);
                    onChanged(clamped);
                  } else {
                    _saveSetting(keyName, 2);
                    onChanged(2);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    );
  }

  Widget _buildColorPicker({required int selectedColor, required Function(Color) onColorSelected}) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._availableColors.map((color) {
          bool isSelected = selectedColor == color.toARGB32();
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.black12,
                  width: isSelected ? 3 : 1,
                ),
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
              setState(() {
                if (!_availableColors.contains(picked)) {
                  _availableColors.add(picked);
                }
              });
              onColorSelected(picked);
            }
          },
          child: Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: const Icon(Icons.colorize, color: Colors.blue),
          ),
        ),
      ],
    );
  }
}

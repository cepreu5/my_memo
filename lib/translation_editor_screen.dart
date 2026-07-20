import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'translation_service.dart';
import 'l10n/app_localizations.dart';
import 'base_strings.dart';

class TranslationEditorScreen extends StatefulWidget {
  final String initialLanguage;
  const TranslationEditorScreen({super.key, this.initialLanguage = 'en'});

  @override
  State<TranslationEditorScreen> createState() => _TranslationEditorScreenState();
}

class _TranslationEditorScreenState extends State<TranslationEditorScreen> {
  late String _selectedLanguage;
  Map<String, String> _baseStrings = {};
  Map<String, String> _translatedStrings = {};
  List<String> _filteredKeys = [];
  String _searchQuery = '';
  int _currentIndex = 0;
  bool _isLoading = true;

  int _appColor = const Color(0xFFFF5E00).toARGB32();

  Color get _bgColor => Color(_appColor);
  Color get _textColor => Color(_appColor).computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  Color get _secondaryTextColor => Color(_appColor).computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

  String _langName(String code) {
    return TranslationService.supportedLanguages[code] ?? code;
  }

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;
    _loadColors();
    _loadStrings();
  }

  Future<void> _loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _appColor = prefs.getInt('bg_color') ?? const Color(0xFFFF5E00).toARGB32());
    }
  }

  Future<void> _loadStrings() async {
    setState(() => _isLoading = true);

    _baseStrings = getBaseStrings();
    _translatedStrings = await _loadArbFile(_selectedLanguage);

    for (final key in _baseStrings.keys) {
      if (!_translatedStrings.containsKey(key)) {
        _translatedStrings[key] = _baseStrings[key] ?? '';
      }
    }

    _filteredKeys = _baseStrings.keys.toList();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: _textColor,
        title: Text(loc.translationEditInterface),
        actions: [
          // Language selector button
          TextButton.icon(
            icon: Icon(Icons.language, color: _textColor),
            label: Text(_langName(_selectedLanguage),
                style: TextStyle(color: _textColor)),
            onPressed: () async {
              final selected = await TranslationService.showLanguagePicker(
                context,
                currentLanguage: _selectedLanguage,
                title: loc.translationEditInterface,
              );
              if (selected != null) {
                setState(() => _selectedLanguage = selected);
                _loadStrings();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.save, color: _textColor),
            onPressed: _saveTranslation,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _textColor))
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    style: TextStyle(color: _textColor),
                    decoration: InputDecoration(
                      hintText: loc.translationSearchStrings,
                      hintStyle: TextStyle(color: _secondaryTextColor),
                      prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _secondaryTextColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                        _filteredKeys = _baseStrings.keys
                            .where((key) =>
                                key.toLowerCase().contains(_searchQuery) ||
                                (_baseStrings[key]?.toLowerCase().contains(_searchQuery) ?? false) ||
                                (_translatedStrings[key]?.toLowerCase().contains(_searchQuery) ?? false))
                            .toList();
                        _currentIndex = 0;
                      });
                    },
                  ),
                ),

                // Navigation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _filteredKeys.isNotEmpty
                            ? '${_currentIndex + 1} / ${_filteredKeys.length}'
                            : '0 / 0',
                        style: TextStyle(fontSize: 14, color: _textColor),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: _textColor),
                            onPressed: _currentIndex > 0
                                ? () => setState(() => _currentIndex--)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: _currentIndex < _filteredKeys.length - 1
                                ? () => setState(() => _currentIndex++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Current string editor
                if (_filteredKeys.isNotEmpty)
                  Expanded(
                    child: _buildStringEditor(_filteredKeys[_currentIndex]),
                  ),
              ],
            ),
    );
  }

  Widget _buildStringEditor(String key) {
    final baseValue = _baseStrings[key] ?? '';
    final translatedValue = _translatedStrings[key] ?? '';

    return Card(
      color: _bgColor.computeLuminance() > 0.5 ? Colors.white : Colors.grey[800],
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key name
            Text(
              key,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),

            // Base language value
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bgColor.computeLuminance() > 0.5 ? Colors.grey[100] : Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'BG: $baseValue',
                style: TextStyle(fontSize: 14, color: _textColor),
              ),
            ),
            const SizedBox(height: 12),

            // Translated value editor
            Expanded(
              child: TextField(
                controller: TextEditingController(text: translatedValue),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _secondaryTextColor),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  labelText: _selectedLanguage.toUpperCase(),
                  labelStyle: TextStyle(color: _secondaryTextColor),
                ),
                onChanged: (value) {
                  _translatedStrings[key] = value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>> _loadArbFile(String locale) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = p.join(directory.path, 'l10n', 'app_$locale.arb');
      final file = File(filePath);

      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(content);

        final filteredEntries = json.entries
            .where((e) => !e.key.startsWith('@'))
            .map((e) => MapEntry(e.key, e.value.toString()));
        return Map<String, String>.fromEntries(filteredEntries);
      }
    } catch (e) {
      print('Error loading ARB file: $e');
    }

    return {};
  }

  Future<void> _saveTranslation() async {
    try {
      final arbContent = TranslationService.generateArbContent(
        locale: _selectedLanguage,
        translations: _translatedStrings,
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = p.join(directory.path, 'l10n', 'app_$_selectedLanguage.arb');
      final file = File(filePath);

      await file.parent.create(recursive: true);
      await file.writeAsString(arbContent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Translation saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

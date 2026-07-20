import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'translation_service.dart';
import 'l10n/app_localizations.dart';
import 'base_strings.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  String _sourceLanguage = 'bg';
  String _targetLanguage = 'en';
  bool _isTranslating = false;
  double _progress = 0;
  int _currentString = 0;
  int _totalStrings = 0;
  int _skippedCount = 0;
  Map<String, String> _translations = {};

  int _appColor = const Color(0xFFFF5E00).toARGB32();

  Color get _bgColor => Color(_appColor);
  Color get _textColor => Color(_appColor).computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  Color get _secondaryTextColor => Color(_appColor).computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

  @override
  void initState() {
    super.initState();
    _loadColors();
  }

  Future<void> _loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _appColor = prefs.getInt('bg_color') ?? const Color(0xFFFF5E00).toARGB32());
    }
  }

  String _langName(String code) {
    return TranslationService.supportedLanguages[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: _textColor,
        title: Text(loc.translationTranslateInterface),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Source language selector
            Card(
              color: _bgColor.computeLuminance() > 0.5 ? Colors.white : Colors.grey[800],
              child: ListTile(
                title: Text(loc.translationSelectBaseLanguage, style: TextStyle(color: _textColor)),
                subtitle: Text(_langName(_sourceLanguage),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _secondaryTextColor)),
                trailing: Icon(Icons.chevron_right, color: _textColor),
                onTap: () async {
                  final selected = await TranslationService.showLanguagePicker(
                    context,
                    currentLanguage: _sourceLanguage,
                    title: loc.translationSelectBaseLanguage,
                  );
                  if (selected != null) {
                    setState(() => _sourceLanguage = selected);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Target language selector
            Card(
              color: _bgColor.computeLuminance() > 0.5 ? Colors.white : Colors.grey[800],
              child: ListTile(
                title: Text(loc.translationSelectTargetLanguage, style: TextStyle(color: _textColor)),
                subtitle: Text(_langName(_targetLanguage),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _secondaryTextColor)),
                trailing: Icon(Icons.chevron_right, color: _textColor),
                onTap: () async {
                  final selected = await TranslationService.showLanguagePicker(
                    context,
                    currentLanguage: _targetLanguage,
                    excludeLanguage: _sourceLanguage,
                    title: loc.translationSelectTargetLanguage,
                  );
                  if (selected != null) {
                    setState(() => _targetLanguage = selected);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // Translate button
            ElevatedButton.icon(
              onPressed: _isTranslating ? null : _startTranslation,
              icon: _isTranslating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _textColor),
                    )
                  : Icon(Icons.translate, color: _textColor),
              label: Text(loc.translationTranslateAll, style: TextStyle(color: _textColor)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _bgColor.computeLuminance() > 0.5 ? Colors.blue : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 24),

            // Progress indicator
            if (_isTranslating) ...[
              Text(
                loc.translationProgress(_currentString.toString(), _totalStrings.toString()),
                style: TextStyle(fontSize: 14, color: _textColor),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _totalStrings > 0 ? _progress / _totalStrings : 0,
                minHeight: 8,
              ),
              const SizedBox(height: 16),
            ],

            // Translation results
            if (_translations.isNotEmpty) ...[
              Card(
                color: _bgColor.computeLuminance() > 0.5 ? Colors.white : Colors.grey[800],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translationComplete,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_translations.length} strings translated',
                        style: TextStyle(fontSize: 14, color: _textColor),
                      ),
                      if (_skippedCount > 0)
                        Text(
                          '($_skippedCount already translated, skipped)',
                          style: TextStyle(fontSize: 12, color: _secondaryTextColor),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Save button
              ElevatedButton.icon(
                onPressed: _saveTranslation,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(loc.translationSaveArb, style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
              ),
              const SizedBox(height: 12),

              // Export instructions
              Card(
                color: _bgColor.computeLuminance() > 0.5 ? Colors.grey[100] : Colors.grey[800],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'За вграждане в APK:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _textColor, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Запази ARB файла (горния бутон)',
                        style: TextStyle(fontSize: 12, color: _secondaryTextColor),
                      ),
                      Text(
                        '2. На компютъра изтегли файла:',
                        style: TextStyle(fontSize: 12, color: _secondaryTextColor),
                      ),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'adb pull /data/data/com.example.my_scr/app_flutter/l10n/app_$_targetLanguage.arb lib/l10n/',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.greenAccent),
                        ),
                      ),
                      Text(
                        '3. flutter gen-l10n && flutter build apk',
                        style: TextStyle(fontSize: 12, color: _secondaryTextColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startTranslation() async {
    setState(() {
      _isTranslating = true;
      _progress = 0;
      _currentString = 0;
      _skippedCount = 0;
      _translations = {};
    });

    try {
      final sourceStrings = getBaseStrings();

      // Load existing translations for the target language
      final existingTranslations = await _loadArbFile(_targetLanguage);
      _skippedCount = 0;

      // Filter out strings that already exist in the target language
      final stringsToTranslate = <String, String>{};
      for (final entry in sourceStrings.entries) {
        if (existingTranslations.containsKey(entry.key) &&
            existingTranslations[entry.key]!.isNotEmpty) {
          // Already translated — keep it, don't retranslate
          _translations[entry.key] = existingTranslations[entry.key]!;
          _skippedCount++;
        } else {
          stringsToTranslate[entry.key] = entry.value;
        }
      }

      _totalStrings = stringsToTranslate.length;

      if (_totalStrings == 0) {
        // Everything already translated
        setState(() {
          _isTranslating = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All ${_translations.length} strings already translated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Translate only the missing strings
      final newTranslations = await TranslationService.translateAll(
        sourceStrings: stringsToTranslate,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        onProgress: (current, total) {
          setState(() {
            _currentString = current;
            _progress = current.toDouble();
          });
        },
      );

      // Merge: existing + new
      _translations.addAll(newTranslations);

      setState(() {
        _isTranslating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newTranslations.length} new, $_skippedCount skipped, ${_translations.length} total'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isTranslating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        locale: _targetLanguage,
        translations: _translations,
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = p.join(directory.path, 'l10n', 'app_$_targetLanguage.arb');
      final file = File(filePath);

      await file.parent.create(recursive: true);
      await file.writeAsString(arbContent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ARB file saved to: $filePath'),
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

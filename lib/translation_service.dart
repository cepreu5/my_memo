import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'l10n/app_localizations.dart';

class TranslationService {
  /// Translates all strings from source language to target language using Google Translate API
  static Future<Map<String, String>> translateAll({
    required Map<String, String> sourceStrings,
    required String targetLanguage,
    required String sourceLanguage,
    void Function(int current, int total)? onProgress,
  }) async {
    final translations = <String, String>{};
    final total = sourceStrings.length;
    int current = 0;

    for (final entry in sourceStrings.entries) {
      final translated = await _translateText(
        entry.value,
        sourceLanguage,
        targetLanguage,
      );
      translations[entry.key] = translated;
      current++;
      onProgress?.call(current, total);
    }

    return translations;
  }

  /// Translates a single text string
  static Future<String> _translateText(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    if (text.isEmpty) return text;

    try {
      // Google Translate free API
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?client=gtx&sl=$sourceLang&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data is List && data.isNotEmpty) {
          final sentences = data[0] as List;
          if (sentences.isNotEmpty) {
            final translatedText = sentences
                .where((s) => s != null && s is List && s.length > 0)
                .map((s) => s[0] as String)
                .join();
            return translatedText;
          }
        }
      }
    } catch (e) {
      print('Translation error for "$text": $e');
    }

    return text; // Fallback to original
  }

  /// Generates an ARB file content from translations
  static String generateArbContent({
    required String locale,
    required Map<String, String> translations,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('{');
    buffer.writeln('  "@@locale": "$locale",');

    final entries = translations.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final comma = i < entries.length - 1 ? ',' : '';
      buffer.writeln('  "${entry.key}": "${_escapeString(entry.value)}"$comma');
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Escapes special characters for JSON
  static String _escapeString(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// Gets the list of supported language codes (with English names and codes for searchability)
  static Map<String, String> get supportedLanguages => {
    'bg': 'Български Bulgarian (bg)',
    'en': 'English (en)',
    'de': 'Deutsch German (de)',
    'fr': 'Français French (fr)',
    'es': 'Español Spanish (es)',
    'it': 'Italiano Italian (it)',
    'pt': 'Português Portuguese (pt)',
    'ru': 'Русский Russian (ru)',
    'tr': 'Türkçe Turkish (tr)',
    'el': 'Ελληνικά Greek (el)',
    'ro': 'Română Romanian (ro)',
    'sr': 'Српски Serbian (sr)',
    'hr': 'Hrvatski Croatian (hr)',
    'sl': 'Slovenščina Slovenian (sl)',
    'sk': 'Slovenčina Slovak (sk)',
    'cs': 'Čeština Czech (cs)',
    'pl': 'Polski Polish (pl)',
    'hu': 'Magyar Hungarian (hu)',
    'nl': 'Nederlands Dutch (nl)',
    'sv': 'Svenska Swedish (sv)',
    'da': 'Dansk Danish (da)',
    'fi': 'Suomi Finnish (fi)',
    'no': 'Norsk Norwegian (no)',
    'uk': 'Українська Ukrainian (uk)',
    'ar': 'العربية Arabic (ar)',
    'he': 'עברית Hebrew (he)',
    'zh': '中文 Chinese (zh)',
    'ja': '日本語 Japanese (ja)',
    'ko': '한국어 Korean (ko)',
    'vi': 'Tiếng Việt Vietnamese (vi)',
    'th': 'ไทย Thai (th)',
    'id': 'Bahasa Indonesia Indonesian (id)',
    'ms': 'Bahasa Melayu Malay (ms)',
    'hi': 'हिन्दी Hindi (hi)',
    'bn': 'বাংলা Bengali (bn)',
    'ta': 'தமிழ் Tamil (ta)',
    'te': 'తెలుగు Telugu (te)',
    'sw': 'Kiswahili Swahili (sw)',
    'af': 'Afrikaans (af)',
    'is': 'Íslenska Icelandic (is)',
    'ga': 'Gaeilge Irish (ga)',
    'cy': 'Cymraeg Welsh (cy)',
    'mk': 'Македонски Macedonian (mk)',
    'sq': 'Shqip Albanian (sq)',
    'bs': 'Bosanski Bosnian (bs)',
    'ka': 'ქართული Georgian (ka)',
    'hy': 'Հայերեն Armenian (hy)',
    'az': 'Azərbaycan Azerbaijani (az)',
    'kk': 'Қазақ Kazakh (kk)',
    'uz': "O'zbek Uzbek (uz)",
    'mn': 'Монгол Mongolian (mn)',
    'ne': 'नेपाली Nepali (ne)',
    'si': 'සිංහල Sinhala (si)',
    'my': 'မြန်မာ Myanmar (my)',
    'km': 'ខ្មែរ Khmer (km)',
    'lo': 'ລາວ Lao (lo)',
    'eu': 'Euskara Basque (eu)',
    'ca': 'Català Catalan (ca)',
    'gl': 'Galego Galician (gl)',
  };

  /// Shows a language picker dialog with search
  static Future<String?> showLanguagePicker(
    BuildContext context, {
    String? currentLanguage,
    String? excludeLanguage,
    String? title,
  }) async {
    final allLanguages = Map<String, String>.from(supportedLanguages);
    final queryController = TextEditingController();
    List<MapEntry<String, String>> filtered = allLanguages.entries.toList();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title ?? AppLocalizations.of(context)!.selectLanguage),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: queryController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchLanguage,
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final q = value.toLowerCase();
                        setState(() {
                          filtered = allLanguages.entries
                              .where((e) =>
                                  e.key != excludeLanguage &&
                                  (e.key.toLowerCase().contains(q) ||
                                      e.value.toLowerCase().contains(q)))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length + 1, // +1 for custom option
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Custom language option — opens a text input dialog
                            return ListTile(
                              leading: const Icon(Icons.edit),
                              title: Text(AppLocalizations.of(context)!.enterLanguageCode),
                              subtitle: Text(AppLocalizations.of(context)!.languageCodeHint),
                              onTap: () async {
                                Navigator.pop(context); // close the picker first
                                final code = await _showCustomCodeDialog(context);
                                if (code != null && context.mounted) {
                                  // Return the custom code via a second navigator pop isn't possible,
                                  // so we use a callback pattern instead
                                  Navigator.of(context, rootNavigator: true).pop(code);
                                }
                              },
                            );
                          }
                          final entry = filtered[index - 1];
                          final isSelected = entry.key == currentLanguage;
                          return ListTile(
                            selected: isSelected,
                            title: Text(entry.value),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.blue)
                                : null,
                            onTap: () => Navigator.pop(context, entry.key),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a simple dialog for entering a custom language code.
  static Future<String?> _showCustomCodeDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.enterLanguageCode),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.languageCodeHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final code = value.trim().toLowerCase();
            if (code.isNotEmpty) {
              Navigator.pop(context, code);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final code = controller.text.trim().toLowerCase();
              if (code.isNotEmpty) {
                Navigator.pop(context, code);
              }
            },
            child: Text(AppLocalizations.of(context)!.done),
          ),
        ],
      ),
    );
  }
}

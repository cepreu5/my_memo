import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'package:cross_platform_video_thumbnails/cross_platform_video_thumbnails.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'db_helper.dart';
import 'note_form.dart';
import 'settings_screen.dart';
import 'tag_scroll.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'fly_menu.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Входна точка на приложението, която инициализира Flutter средата и зарежда стартовия екран.
void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  runApp(const BusinessOrganizerApp());
}

// Главен StatelessWidget, който конфигурира темата и задава MainListScreen за начален екран.
class BusinessOrganizerApp extends StatelessWidget {
  const BusinessOrganizerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'my memo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MainListScreen(),
    );
  }
}

// StatefulWidget, който дефинира основния екран за списъка с бележки.
class MainListScreen extends StatefulWidget {
  const MainListScreen({super.key});
  @override
  State<MainListScreen> createState() => _MainListScreenState();
}

// Основният клас за състояние, управляващ данните, филтрите, настройките и жизнения цикъл на приложението.
class _MainListScreenState extends State<MainListScreen> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  Set<String> _allExistingTags = {};
  List<String> _selectedFilterTags = [];
  bool _isGridView = true;
  int _appBackgroundColor = const Color(0xFFFF5E00).toARGB32();
  bool _filterMatchAll = false;
  bool _confirmDelete = false;
  bool _compactGridView = false;
  int _maxLinesList = 5;
  int _maxLinesGrid = 5;
  double _fontSizeTitle = 14;
  double _fontSizeContent = 13;
  bool _showDate = false;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _filterColor;
  bool _filterTasksOnly = false;
  bool _reverseOrder = false;
  bool _sortById = false;
  bool _forceTwoDecimals = true;
  int _gridWidthOffset = 10;
  int _maxTitleLength = 70;
  int _appColor = const Color(0xFFFF5E00).toARGB32();
  // int _alignmentColumn = 30;
  List<Color> _noteColors = [
    Colors.white, const Color(0xFF0A1931), const Color(0xFFFF5E00), 
    const Color(0xFFFFC93C), const Color(0xFF6A2C70), const Color(0xFFB83B5E), 
    const Color(0xFF005082), Colors.black,
  ];
  // Помощен метод, който изчислява контрастен цвят на текста спрямо фоновия цвят на бележката.
  Color _contrast(Color background, Color ifBright, Color ifDark) {
    return background.computeLuminance() > 0.5 ? ifBright : ifDark;
  }
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _lastAutoSearch = '';
  List<String> _savedSearches = [];
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Инициализира системните компоненти, зарежда настройките и слуша за споделено съдържание от други приложения.
  Future<void> _initializeApp() async {
    try {
      await CrossPlatformVideoThumbnails.initialize();
      await _loadSettings();
      await _refreshItems();
      _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
        if (value.isNotEmpty) _handleSharedMedia(value);
      }, onError: (err) => debugPrint("Грешка при споделяне: $err"));
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
        if (initialMedia.isNotEmpty) {
          await _handleSharedMedia(initialMedia);
        }
        FlutterNativeSplash.remove();
      });
    } catch (e) {
      debugPrint("Грешка инициализация: $e");
      FlutterNativeSplash.remove();
    }
  }

  // Зарежда потребителските предпочитания (размери на шрифтове, цветове, изгледи) от SharedPreferences.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lastAutoSearch = prefs.getString('last_auto_search') ?? '';
      _savedSearches = prefs.getStringList('saved_searches') ?? [];
      _appBackgroundColor = prefs.getInt('bg_color') ?? const Color(0xFFFF5E00).toARGB32();
      _filterMatchAll = prefs.getBool('filter_match_all') ?? false;
      _maxLinesList = prefs.getInt('max_lines_list') ?? 5;
      _maxLinesGrid = prefs.getInt('max_lines_grid') ?? 5;
      _fontSizeTitle = prefs.getDouble('list_title_size') ?? 14;
      _fontSizeContent = prefs.getDouble('list_content_size') ?? 13;
      _confirmDelete = prefs.getBool('confirm_delete') ?? false;
      _isGridView = prefs.getBool('is_grid_view') ?? true;
      _compactGridView = prefs.getBool('compact_grid_view') ?? false;
      _showDate = prefs.getBool('show_date') ?? false;
      _maxTitleLength = prefs.getInt('max_title_length') ?? 70;
      _appColor = prefs.getInt('bg_color') ?? const Color(0xFFFF5E00).toARGB32();
      _reverseOrder = prefs.getBool('reverse_order') ?? false;
      _sortById = prefs.getBool('sort_by_id') ?? false;
      _forceTwoDecimals = prefs.getBool('force_two_decimals') ?? true;
      _gridWidthOffset = prefs.getInt('grid_width_offset') ?? 10;
      // _alignmentColumn = prefs.getInt('alignment_column') ?? 30;
      final customList = prefs.getStringList('custom_palette') ?? [];
      _noteColors = [
        Colors.white, const Color(0xFF0A1931), const Color(0xFFFF5E00), 
        const Color(0xFFFFC93C), const Color(0xFF6A2C70), const Color(0xFFB83B5E), 
        const Color(0xFF005082), Colors.black,
      ];
      if (customList.isNotEmpty) {
        _noteColors.addAll(customList.map((s) => Color(int.parse(s))));
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addAutoSearchTerm(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _lastAutoSearch = trimmed;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_auto_search', _lastAutoSearch);
  }

  Future<void> _saveExplicitSearch(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _savedSearches.remove(trimmed);
      _savedSearches.insert(0, trimmed);
      if (_savedSearches.length > 20) {
        _savedSearches = _savedSearches.sublist(0, 20);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_searches', _savedSearches);
    _searchController.value = _searchController.value.copyWith();
  }

  // Обработва входящи мултимедийни файлове (снимки, видео) при споделяне към приложението.
  Future<void> _handleSharedMedia(List<SharedMediaFile> media) async {
    if (!media.isNotEmpty) return;
    final sharedFile = media.first;
    if (sharedFile.type == SharedMediaType.text || sharedFile.type == SharedMediaType.url) { await _handleSharedText(sharedFile.path); } 
    else if (sharedFile.type == SharedMediaType.video) {
      _openNoteForm(initialData: { 'title': '🎬 ', 'content': sharedFile.path, 'imagePath': sharedFile.path, 'needsThumbnail': true, 'id': null, 'color': null, 'isCompleted': 0, 'tags': null });
    } else {
      _openNoteForm(initialData: { 'imagePath': sharedFile.path, 'title': '📷 ', 'content': '', 'id': null, 'color': null, 'isCompleted': 0, 'tags': null });
    }
  }

  String? _extractYoutubeId(String url) {
    final regExp = RegExp(r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|shorts\/|.*[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})', caseSensitive: false);
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Анализира споделен текст за линкове или YouTube ID и подготвя създаването на нова бележка.
  Future<void> _handleSharedText(String text) async {
    if (text.isEmpty) return;
    String? youtubeId = _extractYoutubeId(text);
    String? thumbPath;
    String title = '📝 ';
    if (youtubeId != null) {
      title = '🎬 ';
      try {
        final response = await http.get(Uri.parse('https://img.youtube.com/vi/$youtubeId/0.jpg'));
        if (response.statusCode == 200) {
          final appDir = await getApplicationDocumentsDirectory();
          thumbPath = p.join(appDir.path, 'yt_thumb_$youtubeId.jpg');
          await File(thumbPath).writeAsBytes(response.bodyBytes);
        }
      } catch (e) { debugPrint("Грешка при YouTube thumbnail: $e"); }
    } else if (text.contains('http://') || text.contains('https://') || text.contains('www.')) {
      title = '🔗 ';
    }
    String finalContent = text;
    String finalTitle = title;
    final urlRegExp = RegExp(r'(https?:\/\/[^\s]+|www\.[^\s]+)');
    final match = urlRegExp.firstMatch(text);
    if (match != null) {
      String urlPart = match.group(0)!;
      String beforeUrl = text.substring(0, match.start).trim();
      String afterUrl = text.substring(match.end).trim();
      
      if (beforeUrl.isEmpty && afterUrl.isEmpty) {
        finalContent = urlPart;
      } else if (beforeUrl.isNotEmpty && afterUrl.isEmpty) {
        if (beforeUrl.length > _maxTitleLength) {
          finalTitle = title;
          finalContent = '$beforeUrl\n$urlPart';
        } else {
          finalTitle = '$title$beforeUrl';
          finalContent = urlPart;
        }
      } else if (beforeUrl.isEmpty && afterUrl.isNotEmpty) {
        finalContent = '$urlPart\n$afterUrl';
      } else {
        // Both before and after are not empty
        if (beforeUrl.length > _maxTitleLength) {
          finalTitle = title;
          finalContent = '$beforeUrl\n$urlPart\n$afterUrl';
        } else {
          finalTitle = '$title$beforeUrl';
          finalContent = '$urlPart\n$afterUrl';
        }
      }
    } else {
      if (text.length > _maxTitleLength) {
        finalTitle = title;
        finalContent = text;
      } else {
        finalTitle = '$title$text';
        finalContent = '';
      }
    }
    _openNoteForm(initialData: { 'content': finalContent, 'title': finalTitle, 'imagePath': thumbPath, 'id': null, 'color': null, 'isCompleted': 0, 'tags': null });
  }

  // Обновява списъка с бележки чрез заявка към локалната база данни SQLite.
  Future<void> _refreshItems() async {
    try {
      final data = await dbHelper.queryAllRows();
      if (!mounted) return;
      setState(() { _allItems = data; _updateUniqueTags(); _filterItems(_searchController.text); });
    } catch (e) { debugPrint("Грешка БД: $e"); }
  }

  // Събира и поддържа списък от всички уникални етикети, използвани в наличните бележки.
  void _updateUniqueTags() {
    final Set<String> tagsSet = {};
    tagsSet.add('📌'); // Кабърчето е системен етикет и винаги трябва да е наличен
    for (var item in _allItems) {
      final String rawTags = (item['tags'] ?? '').toString();
      if (rawTags.isNotEmpty) {
        final List<String> tagsList = rawTags.split(',');
        for (var tag in tagsList) {
          final trimmed = tag.trim();
          if (trimmed.isNotEmpty) tagsSet.add(trimmed);
        }
      }
    }
    setState(() { _allExistingTags = tagsSet; _selectedFilterTags.removeWhere((tag) => !tagsSet.contains(tag)); });
  }

  // Филтрира и сортира бележките според търсен текст, избрани етикети, период, цвят или статус на задача.
  void _filterItems(String query) {
    final lowercaseQuery = query.trim().toLowerCase();
    setState(() {
      _filteredItems = _allItems.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final content = (item['content'] ?? '').toString().toLowerCase();
        final List<String> noteTagsList = (item['tags'] ?? '').toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        bool matchesSearch = lowercaseQuery.isEmpty || title.contains(lowercaseQuery) || content.contains(lowercaseQuery);
        bool matchesTags = true;
        if (_selectedFilterTags.isNotEmpty) {
          if (_filterMatchAll) { matchesTags = _selectedFilterTags.every((t) => noteTagsList.contains(t)); } 
          else { matchesTags = _selectedFilterTags.any((t) => noteTagsList.contains(t)); }
        }
        bool matchesDate = true;
        if (_startDate != null && _endDate != null) {
          if (item['reminderTime'] != null) {
            final dt = DateTime.parse(item['reminderTime']);
            final checkDt = DateTime(dt.year, dt.month, dt.day);
            final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
            final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
            matchesDate = (checkDt.isAtSameMomentAs(start) || checkDt.isAfter(start)) && (checkDt.isAtSameMomentAs(end) || checkDt.isBefore(end));
          } else { matchesDate = false; }
        }
        bool matchesColor = _filterColor == null || item['color'] == _filterColor;
        bool matchesTasks = !_filterTasksOnly || (item['isCompleted'] == 1 || item['isCompleted'] == 2);
        return matchesSearch && matchesTags && matchesDate && matchesColor && matchesTasks;
      }).toList();

      _filteredItems.sort((a, b) {
        final aPinned = (a['tags'] ?? '').toString().contains('📌');
        final bPinned = (b['tags'] ?? '').toString().contains('📌');
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;

        if (_sortById) {
          final valA = (a['id'] ?? 0);
          final valB = (b['id'] ?? 0);
          return _reverseOrder ? valB.compareTo(valA) : valA.compareTo(valB);
        } else {
          final valA = (a['reminderTime'] ?? '').toString();
          final valB = (b['reminderTime'] ?? '').toString();
          return _reverseOrder ? valA.compareTo(valB) : valB.compareTo(valA);
        }
      });
    });
  }

  // Показва диалогов прозорец за детайлно филтриране и промяна на реда на сортиране.
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final Color contrastColor = _contrast(Color(_appColor), Colors.black, Colors.white);
            final Color secondaryContrast = _contrast(Color(_appColor), Colors.black54, Colors.white70);
            return AlertDialog(
              backgroundColor: Color(_appColor),
              title: Row(
                children: [
                  Text("Филтриране", style: TextStyle(color: contrastColor)),
                  const Spacer(),
                  IconButton(icon: Icon(Icons.close, color: contrastColor), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDateRange: (_startDate != null && _endDate != null) ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
                        );
                        if (picked != null) {
                          setState(() { _startDate = picked.start; _endDate = picked.end; });
                          _filterItems(_searchController.text);
                          setModalState(() {});
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.date_range, color: contrastColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Text("Период", style: TextStyle(color: contrastColor)),
                                  if (_startDate != null) ...[
                                    const SizedBox(width: 8),
                                    Text("${_startDate!.day}.${_startDate!.month.toString().padLeft(2, '0')}-${_endDate!.day}.${_endDate!.month.toString().padLeft(2, '0')}", style: TextStyle(color: secondaryContrast, fontSize: 12)),
                                  ],
                                ],
                              ),
                            ),
                            if (_startDate != null)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.clear, color: contrastColor, size: 20),
                                onPressed: () {
                                  setState(() { _startDate = null; _endDate = null; });
                                  _filterItems(_searchController.text);
                                  setModalState(() {});
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    Row(children: [Icon(Icons.palette, color: contrastColor), const SizedBox(width: 10), Text("Цвят", style: TextStyle(color: contrastColor))]),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 34),
                      child: Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _noteColors.map((c) {
                          final isSelected = _filterColor == c.toARGB32();
                          return GestureDetector(
                            onTap: () {
                              setState(() { _filterColor = isSelected ? null : c.toARGB32(); });
                              _filterItems(_searchController.text);
                              setModalState(() {});
                            },
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: c, shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: isSelected ? 3 : 1),
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 20, color: Colors.blue) : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() { _filterTasksOnly = !_filterTasksOnly; });
                        _filterItems(_searchController.text);
                        setModalState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.checklist, size: 20, color: contrastColor),
                            const SizedBox(width: 10),
                            Expanded(child: Text("Само задачи", style: TextStyle(color: contrastColor))),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: Icon(_filterTasksOnly ? Icons.check_box : Icons.check_box_outline_blank, size: 24, color: contrastColor),
                              onPressed: () {
                                setState(() { _filterTasksOnly = !_filterTasksOnly; });
                                _filterItems(_searchController.text);
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('sort_by_id', !_sortById);
                        if (!mounted) return;
                        setState(() { _sortById = !_sortById; });
                        _filterItems(_searchController.text);
                        setModalState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.format_list_numbered, color: contrastColor),
                            const SizedBox(width: 10),
                            Expanded(child: Text("Последователен ред", style: TextStyle(color: contrastColor))),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: Icon(_sortById ? Icons.check_box : Icons.check_box_outline_blank, size: 24, color: contrastColor),
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('sort_by_id', !_sortById);
                                if (!mounted) return;
                                setState(() { _sortById = !_sortById; });
                                _filterItems(_searchController.text);
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(color: contrastColor.withValues(alpha: 0.2)),
                    InkWell(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('reverse_order', !_reverseOrder);
                        if (!mounted) return;
                        setState(() { _reverseOrder = !_reverseOrder; });
                        _filterItems(_searchController.text);
                        setModalState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.sort, color: contrastColor),
                            const SizedBox(width: 10),
                            Expanded(child: Text("Обратно подреждане", style: TextStyle(color: contrastColor))),
                            Checkbox(
                              visualDensity: VisualDensity.compact,
                              value: _reverseOrder,
                              activeColor: contrastColor,
                              side: BorderSide(color: contrastColor, width: 2.0),
                              checkColor: Color(_appColor),
                              onChanged: (val) async {
                                final prefs = await SharedPreferences.getInstance();
                                final newVal = val ?? false;
                                await prefs.setBool('reverse_order', newVal);
                                if (!mounted) return;
                                setState(() { _reverseOrder = newVal; });
                                _filterItems(_searchController.text);
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () async {
                  final navigator = Navigator.of(ctx);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('sort_by_id', false);
                  await prefs.setBool('reverse_order', false);
                  if (!mounted) return;
                  setState(() { 
                    _startDate = null; _endDate = null; _filterColor = null; _filterTasksOnly = false; 
                    _reverseOrder = false; _sortById = false; _selectedFilterTags.clear(); 
                  });
                  _filterItems(_searchController.text);
                  navigator.pop();
                }, child: Text("Изчисти всички", style: TextStyle(color: secondaryContrast))),
                ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Готово")),
              ],
            );
          },
        );
      },
    );
  }

  // Модален прозорец за бързо добавяне и премахване на етикети към конкретна бележка.
  void _showTagsModal(Map<String, dynamic> item) {
    List<String> currentTags = (item['tags'] ?? '').toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final Color contrastColor = _contrast(Color(_appColor), Colors.black, Colors.white);
            final Color secondaryContrast = _contrast(Color(_appColor), Colors.black54, Colors.white70);
            List<String> allTags = _allExistingTags.toList()..sort((a, b) {
              if (a == '📌') return -1;
              if (b == '📌') return 1;
              return a.compareTo(b);
            });
            return AlertDialog(
              backgroundColor: Color(_appColor),
              title: Text('Етикети за "${item['title'] ?? 'Бележка'}"', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: contrastColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allTags.isNotEmpty) ...[
                      Text("Избери:", style: TextStyle(fontSize: 12, color: secondaryContrast)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4, runSpacing: 4,
                        children: allTags.map((tag) {
                          bool isSelected = currentTags.contains(tag);
                          return FilterChip(
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                            label: Text(tag, style: const TextStyle(fontSize: 10)),
                            selected: isSelected,
                            onSelected: (val) {
                              setModalState(() {
                                if (val) { if (!currentTags.contains(tag)) currentTags.add(tag); } 
                                else { currentTags.remove(tag); }
                              });
                            },
                            showCheckmark: false,
                            selectedColor: Colors.yellow[700],
                            backgroundColor: Colors.cyan[200],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: isSelected ? const BorderSide(color: Colors.cyan, width: 1) : BorderSide(color: Colors.cyan[400]!),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text("Нов етикет:", style: TextStyle(fontSize: 12, color: secondaryContrast)),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            style: TextStyle(color: contrastColor, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: "Име...", 
                              hintStyle: TextStyle(color: secondaryContrast.withValues(alpha: 0.4), fontSize: 13),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: secondaryContrast.withValues(alpha: 0.2))),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty && !currentTags.contains(val.trim())) {
                                setModalState(() { currentTags.add(val.trim()); if (!_allExistingTags.contains(val.trim())) _allExistingTags.add(val.trim()); });
                                _tagController.clear();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, size: 20, color: contrastColor),
                          onPressed: () {
                             final val = _tagController.text;
                             if (val.trim().isNotEmpty && !currentTags.contains(val.trim())) {
                                setModalState(() { currentTags.add(val.trim()); if (!_allExistingTags.contains(val.trim())) _allExistingTags.add(val.trim()); });
                                _tagController.clear();
                             }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Отказ", style: TextStyle(color: secondaryContrast))),
                ElevatedButton(
                  onPressed: () async {
                    Map<String, dynamic> updatedItem = Map.from(item);
                    updatedItem['tags'] = currentTags.join(', ');
                    await dbHelper.updateItem(updatedItem);
                    _refreshItems();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Запази'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Модален прозорец за глобално филтриране по избрани етикети.
  void _showGlobalTagsModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final Color contrastColor = _contrast(Color(_appColor), Colors.black, Colors.white);
            final Color secondaryContrast = _contrast(Color(_appColor), Colors.black54, Colors.white70);
            List<String> allTags = _allExistingTags.toList()..sort((a, b) {
              if (a == '📌') return -1;
              if (b == '📌') return 1;
              return a.compareTo(b);
            });
            return AlertDialog(
              backgroundColor: Color(_appColor),
              title: Text('Филтър по етикети', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: contrastColor)),
              content: allTags.isEmpty 
                ? Padding(padding: const EdgeInsets.all(20), child: Text('Няма налични етикети.', style: TextStyle(color: secondaryContrast)))
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 4, runSpacing: 4,
                      children: allTags.map((tag) {
                        bool isSelected = _selectedFilterTags.contains(tag);
                        return FilterChip(
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                          label: Text(tag, style: const TextStyle(fontSize: 10)),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) { if (!_selectedFilterTags.contains(tag)) _selectedFilterTags.add(tag); } 
                              else { _selectedFilterTags.remove(tag); }
                              _filterItems(_searchController.text);
                            });
                            setModalState(() {});
                          },
                          showCheckmark: false,
                          selectedColor: Colors.yellow[700],
                          backgroundColor: Colors.cyan[200],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: isSelected ? const BorderSide(color: Colors.cyan, width: 1) : BorderSide(color: Colors.cyan[400]!),
                        );
                      }).toList(),
                    ),
                  ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() { _selectedFilterTags.clear(); _filterItems(_searchController.text); });
                    setModalState(() {});
                  },
                  child: const Text('Изчисти', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Готово")),
              ],
            );
          },
        );
      },
    );
  }

  // Управлява навигацията към екрана за редактиране или преглед на бележка.
  void _openNoteForm({Map<String, dynamic>? initialData, int? index, bool startInEditMode = false}) async {
    FocusScope.of(context).unfocus();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (c) => NoteFormScreen(
      item: initialData, 
      onSaved: _refreshItems, 
      existingTags: _allExistingTags.toList(),
      allNotes: _filteredItems,
      initialIndex: index,
      startInEditMode: startInEditMode,
    )));
    if (mounted) _refreshItems();
  }

  // Отваря екрана с общи настройки на приложението.
  Future<void> _goToSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()));
    if (mounted) _loadSettings();
  }

  // Превключва между списъчен и матричен изглед на бележките и записва избора.
  Future<void> _toggleView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _isGridView = !_isGridView; prefs.setBool('is_grid_view', _isGridView); });
  }

  // Променя статуса на завършеност (checkbox) на бележки, които са маркирани като задачи.
  Future<void> _toggleComplete(Map<String, dynamic> item) async {
    final currentStatus = item['isCompleted'] ?? 0;
    int newStatus;
    if (currentStatus == 1) { newStatus = 2; }
    else if (currentStatus == 2) { newStatus = 1; }
    else { newStatus = 1; } // Fallback
    await dbHelper.updateItem({ ...item, 'isCompleted': newStatus });
    if (mounted) _refreshItems();
  }

  @override
  // Основният метод за изграждане на потребителския интерфейс, включващ търсачка, лента с етикети и списък с бележки.
  Widget build(BuildContext context) {
    final bgColor = Color(_appBackgroundColor);
    final isDarkBg = bgColor.computeLuminance() < 0.5;
    final appBarTextColor = isDarkBg ? Colors.white : Colors.black87;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: bgColor.withValues(alpha: 0.9),
        foregroundColor: appBarTextColor,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset('assets/app_icon_0.png', fit: BoxFit.contain),
        ),
        leadingWidth: 46,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: LayoutBuilder(
            builder: (context, constraints) => RawAutocomplete<String>(
              focusNode: _searchFocusNode,
              textEditingController: _searchController,
              optionsBuilder: (TextEditingValue textEditingValue) {
                List<String> combined = [];
                if (_lastAutoSearch.isNotEmpty) combined.add(_lastAutoSearch);
                for (var s in _savedSearches) {
                  if (s != _lastAutoSearch) combined.add(s);
                }
                if (textEditingValue.text.isEmpty) {
                  return combined;
                }
                return combined.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _searchController.text = selection;
                _filterItems(selection);
                _addAutoSearchTerm(selection);
                FocusScope.of(context).unfocus();
              },
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onChanged: (val) => _filterItems(val),
                  onSubmitted: (val) {
                    _filterItems(val);
                    _addAutoSearchTerm(val);
                    onFieldSubmitted();
                  },
                  style: TextStyle(color: appBarTextColor),
                  decoration: InputDecoration(
                    hintText: 'Търсене...',
                    hintStyle: TextStyle(color: appBarTextColor.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.search, color: appBarTextColor.withValues(alpha: 0.6)),
                    suffixIcon: textEditingController.text.isNotEmpty ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.save_outlined, size: 20, color: appBarTextColor),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _saveExplicitSearch(textEditingController.text),
                        ),
                        IconButton(
                          icon: Icon(Icons.clear, size: 20, color: appBarTextColor), 
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () { textEditingController.clear(); _filterItems(''); focusNode.unfocus(); }
                        ),
                      ],
                    ) : null,
                    filled: true,
                    fillColor: (isDarkBg ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    color: bgColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      width: constraints.maxWidth,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          final bool isAuto = option == _lastAutoSearch;
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Icon(isAuto ? Icons.history : Icons.save_outlined, size: 18, color: appBarTextColor.withValues(alpha: 0.6)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(option, style: TextStyle(color: appBarTextColor, fontStyle: isAuto ? FontStyle.italic : FontStyle.normal), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  IconButton(
                                    icon: Icon(Icons.close, size: 16, color: appBarTextColor.withValues(alpha: 0.5)),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () async {
                                      setState(() {
                                        if (isAuto) {
                                          _lastAutoSearch = '';
                                          SharedPreferences.getInstance().then((p) => p.setString('last_auto_search', ''));
                                        } else {
                                          _savedSearches.remove(option);
                                          SharedPreferences.getInstance().then((p) => p.setStringList('saved_searches', _savedSearches));
                                        }
                                      });
                                      _searchController.value = _searchController.value.copyWith();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _goToSettings),
          IconButton(icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view), onPressed: _toggleView),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Column(
              children: [
                TagScrollFilter(
                  allTags: _allExistingTags.where((t) => t != '📌').toList(),
                  selectedTags: _selectedFilterTags,
                  textColor: appBarTextColor,
                  startDate: _startDate,
                  endDate: _endDate,
                  filterColor: _filterColor,
                  tasksOnly: _filterTasksOnly,
                  reverseOrder: _reverseOrder,
                  sortById: _sortById,
                  onOpenFilterMenu: _showFilterDialog,
                  onSelectionChanged: (newList) {
                    setState(() { _selectedFilterTags = newList; });
                    _filterItems(_searchController.text);
                  },
                  onClearAll: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('sort_by_id', false);
                    await prefs.setBool('reverse_order', false);
                    if (!mounted) return;
                    setState(() {
                      _selectedFilterTags.clear();
                      _startDate = null;
                      _endDate = null;
                      _filterColor = null;
                      _filterTasksOnly = false;
                      _reverseOrder = false;
                      _sortById = false;
                    });
                    _filterItems(_searchController.text);
                  },
                ),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? Center(child: Text('Няма открити бележки.', style: TextStyle(color: appBarTextColor)))
                      : _isGridView ? _buildGrid() : _buildList(),
                ),
              ],
            ),
            FlyMenu(
              actions: [
                FlyAction(icon: _isGridView ? Icons.view_list : Icons.grid_view, onTap: _toggleView, label: "Изглед"),
                if (_searchController.text.isNotEmpty)
                  FlyAction(
                    icon: Icons.search_off,
                    onTap: () { _searchController.clear(); _filterItems(''); FocusScope.of(context).unfocus(); },
                    label: "Без търсене",
                  ),
                FlyAction(icon: Icons.filter_list, onTap: _showFilterDialog, label: "Филтри"),
                FlyAction(icon: Icons.label_outline, onTap: _showGlobalTagsModal, label: "Етикети"),
                if (_selectedFilterTags.isNotEmpty || _startDate != null || _filterColor != null || _filterTasksOnly || _reverseOrder || _sortById)
                  FlyAction(
                    icon: Icons.label_off_outlined,
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('sort_by_id', false);
                      await prefs.setBool('reverse_order', false);
                      if (!mounted) return;
                      setState(() {
                        _selectedFilterTags.clear();
                        _startDate = null;
                        _endDate = null;
                        _filterColor = null;
                        _filterTasksOnly = false;
                        _reverseOrder = false;
                        _sortById = false;
                      });
                      _filterItems(_searchController.text);
                    },
                    label: "Без филтри",
                  ),
                FlyAction(icon: Icons.add, onTap: () => _openNoteForm(), label: "Нова бележка"),
                FlyAction(icon: Icons.settings, onTap: _goToSettings, label: "Настройки"),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openNoteForm(), tooltip: 'Нова бележка', child: const Icon(Icons.add)),
    );
  }

  // Конструира вертикален списък от бележки за стандартния изглед.
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) => _buildNoteCard(_filteredItems[index], false),
    );
  }

  // Изгражда двуколонен "шахматен" изглед за бележките в режим матрица.
  Widget _buildGrid() {
    List<Map<String, dynamic>> leftColumn = [];
    List<Map<String, dynamic>> rightColumn = [];
    for (int i = 0; i < _filteredItems.length; i++) {
      if (i % 2 == 0) { leftColumn.add(_filteredItems[i]); } else { rightColumn.add(_filteredItems[i]); }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: leftColumn.map((item) => _buildNoteCard(item, true)).toList())),
          const SizedBox(width: 8),
          Expanded(child: Column(children: rightColumn.map((item) => _buildNoteCard(item, true)).toList())),
        ],
      ),
    );
  }

  // Премахва "📌" етикета от бележката, като по този начин я "откача".
  Future<void> _unpinNote(Map<String, dynamic> item) async {
    List<String> tags = (item['tags'] ?? '').toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    tags.remove('📌');
    await dbHelper.updateItem({ ...item, 'tags': tags.join(', ') });
    _refreshItems();
  }

  // Създава визуалната карта на всяка бележка, включваща заглавие, съдържание, изображения и жестове за изтриване.
  Widget _buildNoteCard(Map<String, dynamic> item, bool isGrid) {
    final bool isDone = item['isCompleted'] == 1;
    final bool isPinned = (item['tags'] ?? '').toString().contains('📌');
    final Color cardColor = item['color'] != null ? Color(item['color']) : Colors.white;
    final Color textColor = cardColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    final Color secondaryTextColor = cardColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;
    final Color bottomColor = cardColor == Colors.white ? Colors.grey[100]! : HSLColor.fromColor(cardColor).withLightness((HSLColor.fromColor(cardColor).lightness - 0.1).clamp(0.0, 1.0)).toColor();
    Widget cardContent = Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((item['title'] ?? '').toString().trim().isNotEmpty || item['isCompleted'] != 0 || isPinned)
            Row( // заглавие и чекбокс
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPinned)
                  GestureDetector(
                    onTap: () => _unpinNote(item),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text('📌', style: TextStyle(fontSize: _fontSizeTitle - 2)), // @@ кабърче
                    ),
                  ),
                if (item['isCompleted'] != 0) ...[ // отметки
                  GestureDetector(
                    onTap: () => _toggleComplete(item),
                    child: Icon(isDone ? Icons.check_box : Icons.check_box_outline_blank, size: 22, color: textColor),
                  ),
                ],
                if ((item['title'] ?? '').toString().trim().isNotEmpty)
                  Expanded(child: Text(item['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSizeTitle, color: textColor, decoration: isDone ? TextDecoration.lineThrough : null))),
              ],
            ),
          if ((item['content'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildContentWithLinks(item['content'] ?? '', secondaryTextColor, textColor, isGrid),
          ],
          if (item['reminderTime'] != null && _showDate)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: secondaryTextColor),
                  const SizedBox(width: 4),
                  Expanded(child: Text(_formatDateTime(item['reminderTime']), style: TextStyle(fontSize: 9, color: secondaryTextColor))), // FontWeight.bold @@ дата
                ],
              ),
            ),
        ],
      ),
    );
    final String? displayImagePath = item['imagePath'];
    if (!isGrid && displayImagePath != null) {
      cardContent = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100, alignment: Alignment.topCenter, margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 100, maxWidth: 100), child: Image.file(File(displayImagePath), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)))),
          ),
          Expanded(child: cardContent),
        ],
      );
    } else if (isGrid && displayImagePath != null) {
      cardContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(8)), child: NoteGridImage(imagePath: displayImagePath, backgroundColor: cardColor, compactView: _compactGridView)),
          cardContent,
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Dismissible(
        key: Key(item['id'].toString()),
        direction: DismissDirection.horizontal,
        background: Container(decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.delete, color: Colors.white)),
        secondaryBackground: Container(decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(8)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.label, color: Colors.white)),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            _showTagsModal(item);
            return false;
          }
          if (!_confirmDelete) return true;
          return await showDialog<bool>(context: context, builder: (c) => AlertDialog(
            backgroundColor: Color(_appColor),
            title: Text('Потвърждение', style: TextStyle(color: _contrast(Color(_appColor), Colors.black, Colors.white))), 
            content: Text('Сигурни ли сте, че искате да изтриете тази бележка?', style: TextStyle(color: _contrast(Color(_appColor), Colors.black87, Colors.white70))), 
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Отказ', style: TextStyle(color: _contrast(Color(_appColor), Colors.black54, Colors.white60)))), 
              TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Изтриване', style: TextStyle(color: _contrast(Color(_appColor), Colors.black54, Colors.white60))))
            ]
          )) ?? false;
        },
        onDismissed: (direction) async {
          if (item['isLocalCopy'] == 1 && item['imagePath'] != null) {
            bool isUsed = await dbHelper.isImagePathUsed(item['imagePath'], item['id']);
            if (!isUsed) { try { final f = File(item['imagePath']); if (await f.exists()) await f.delete(); } catch (e) { debugPrint("Грешка файл: $e"); } }
          }
          await dbHelper.deleteItem(item['id']);
          _refreshItems();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cardColor, bottomColor]),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8), 
              onTap: () => _openNoteForm(initialData: item, index: _filteredItems.indexOf(item)), 
              onLongPress: () {
                final copy = Map<String, dynamic>.from(item);
                copy.remove('id');
                copy.remove('tags');
                _openNoteForm(initialData: copy, startInEditMode: true);
              },
              child: cardContent
            ),
          ),
        ),
      ),
    );
  }

  // Специализиран метод за изобразяване на съдържанието, поддържащ линкове, чекбоксове и подравнени ценови списъци.
  Widget _buildContentWithLinks(String content, Color secondaryTextColor, Color textColor, bool isGrid) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final linkStyle = TextStyle(color: textColor == Colors.white ? Colors.lightBlueAccent : Colors.blue, decoration: TextDecoration.none);
        final priceExp = RegExp(r'^(.*?)(?:\s*\.{2,}\s*|\s{2,})(\d+(?:[\.,]\d+)?)\s*$');
        final checkPattern = RegExp(r'^([☐☑]|\[\s?[xXvV]?\s?\])\s+');
        
        final lines = content.split('\n');
        List<Widget> widgets = [];
        int displayLines = 0;
        int maxAllowedLines = isGrid ? _maxLinesGrid : _maxLinesList;
        
        // Calculate dynamic target width based on available pixels and char width
        final tp = TextPainter(
          text: TextSpan(text: '0', style: TextStyle(fontSize: _fontSizeContent, fontFamily: 'monospace')),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        double charWidth = tp.width;
        int baseTargetWidth = (constraints.maxWidth / charWidth).floor();

        for (var line in lines) {
          if (displayLines >= maxAllowedLines) break;
          
          Match? checkMatch = checkPattern.firstMatch(line);
          bool isChecked = false;
          String cleanLine = line;
          if (checkMatch != null) {
            isChecked = line.startsWith('☑') || checkMatch.group(1)!.contains(RegExp(r'[xXvV]'));
            cleanLine = line.substring(checkMatch.end);
          }

          String finalString = cleanLine;
          Match? m = priceExp.firstMatch(cleanLine);
          bool isPriceLine = m != null;
          
          if (isPriceLine) {
            if (isGrid) {
              String prefix = m.group(1)!.replaceAll(RegExp(r'\.+$'), '').trimRight();
              String price = m.group(2)!;
              if (_forceTwoDecimals) {
                double? val = double.tryParse(price.replaceAll(',', '.'));
                if (val != null) price = val.toStringAsFixed(2);
              }
              
              int priceLen = price.length;
              int targetWidth = baseTargetWidth - _gridWidthOffset;
              int availableForPrefix = targetWidth - priceLen - 1; // 1 space before price

              String filler;
              String truncatedPrefix;
              
              if (prefix.length + 2 <= availableForPrefix) {
                truncatedPrefix = prefix;
                filler = "." * (availableForPrefix - prefix.length);
              } else {
                truncatedPrefix = prefix.length > availableForPrefix ? prefix.substring(0, availableForPrefix) : prefix;
                filler = ""; 
              }
              finalString = filler.isEmpty ? "$truncatedPrefix $price" : "$truncatedPrefix$filler $price";
            } else {
              // LIST VIEW: No processing, just use raw line and monospace
              finalString = cleanLine;
            }
          }

      final hasLink = RegExp(r'https?://|www\.').hasMatch(finalString);
      
      widgets.add(Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (checkMatch != null)
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 1),
              child: Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: secondaryTextColor),
            ),
          Expanded(
            child: hasLink 
              ? Linkify(
                  text: finalString,
                  onOpen: (link) async {
                    final url = Uri.parse(link.url);
                    if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); }
                  },
                  maxLines: 1,
                  overflow: isPriceLine ? TextOverflow.clip : TextOverflow.ellipsis,
                  style: TextStyle(fontSize: _fontSizeContent, color: secondaryTextColor, decoration: isChecked ? TextDecoration.lineThrough : null, height: 1.0, fontFamily: 'monospace'),
                  linkStyle: linkStyle,
                )
              : Text(
                  finalString,
                  maxLines: 1,
                  overflow: isPriceLine ? TextOverflow.clip : TextOverflow.ellipsis,
                  style: TextStyle(fontSize: _fontSizeContent, color: secondaryTextColor, decoration: isChecked ? TextDecoration.lineThrough : null, height: 1.0, fontFamily: 'monospace'),
                ),
          ),
        ],
      ));
      
      displayLines++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widgets,
        if (isGrid) 
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "CW: ${constraints.maxWidth.toStringAsFixed(1)}, BW: $baseTargetWidth, Gh: ${charWidth.toStringAsFixed(1)}",
              style: TextStyle(fontSize: 8, color: secondaryTextColor.withValues(alpha: 0.5), fontFamily: 'monospace'),
            ),
          ),
      ],
    );
      }
    );
  }

  // Форматира ISO дата в четлив формат (ДД.ММ.ГГ ЧЧ:ММ) за показване в бележката.
  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year.toString().substring(2)} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) { return ''; }
  }
}

// Помощен widget за правилно изобразяване на изображения в матричния изглед според тяхната ориентация.
class NoteGridImage extends StatefulWidget {
  final String imagePath;
  final Color backgroundColor;
  final bool compactView;
  const NoteGridImage({super.key, required this.imagePath, required this.backgroundColor, this.compactView = false});
  @override
  State<NoteGridImage> createState() => _NoteGridImageState();
}

class _NoteGridImageState extends State<NoteGridImage> {
  bool _isPortrait = false;
  @override
  void initState() { super.initState(); _checkDimensions(); }
  void _checkDimensions() {
    final image = FileImage(File(widget.imagePath));
    image.resolve(const ImageConfiguration()).addListener(ImageStreamListener((info, sync) { if (mounted) setState(() { _isPortrait = info.image.height > info.image.width; }); }));
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, color: widget.backgroundColor,
      child: ConstrainedBox(constraints: BoxConstraints(maxHeight: widget.compactView ? 100 : 200), child: Padding(padding: EdgeInsets.only(top: (_isPortrait || widget.compactView) ? 3 : 0), child: Image.file(File(widget.imagePath), fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)))),
    );
  }
}

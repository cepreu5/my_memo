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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CrossPlatformVideoThumbnails.initialize();
  runApp(const BusinessOrganizerApp());
}

class BusinessOrganizerApp extends StatelessWidget {
  const BusinessOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'my memo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainListScreen(),
    );
  }
}

class MainListScreen extends StatefulWidget {
  const MainListScreen({super.key});

  @override
  State<MainListScreen> createState() => _MainListScreenState();
}

class _MainListScreenState extends State<MainListScreen> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  Set<String> _allExistingTags = {};
  List<String> _selectedFilterTags = [];

  bool _isGridView = true;
  int _appBackgroundColor = Colors.white.toARGB32();
  bool _filterMatchAll = false; // Декларирана променлива за режима на филтриране
  bool _confirmDelete = false;
  int _maxLinesList = 5;
  int _maxLinesGrid = 5;
  double _fontSizeTitle = 14;
  double _fontSizeContent = 13;
  final TextEditingController _searchController = TextEditingController();
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _refreshItems();

    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty) _handleSharedMedia(value);
    }, onError: (err) => debugPrint("Грешка: $err"));

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) _handleSharedMedia(value);
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appBackgroundColor = prefs.getInt('bg_color') ?? Colors.white.toARGB32();
      _filterMatchAll = prefs.getBool('filter_match_all') ?? false;
      _maxLinesList = prefs.getInt('max_lines_list') ?? 5;
      _maxLinesGrid = prefs.getInt('max_lines_grid') ?? 5;
      _fontSizeTitle = prefs.getDouble('list_title_size') ?? 14;
      _fontSizeContent = prefs.getDouble('list_content_size') ?? 13;
      _confirmDelete = prefs.getBool('confirm_delete') ?? false;
      _isGridView = prefs.getBool('is_grid_view') ?? true;
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> media) async {
    final sharedFile = media.first;
    print("DEBUG: Shared Type: ${sharedFile.type}, Path: ${sharedFile.path}");
    if (sharedFile.type == SharedMediaType.text || sharedFile.type == SharedMediaType.url) {
      await _handleSharedText(sharedFile.path);
    } else if (sharedFile.type == SharedMediaType.video) {
      String? thumbnailPath;
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'vid_thumb_${DateTime.now().millisecondsSinceEpoch}.png';
        final targetPath = p.join(appDir.path, fileName);

        // Уверяваме се, че директорията съществува
        final directory = Directory(appDir.path);
        if (!await directory.exists()) await directory.create(recursive: true);
        final thumbnail = await CrossPlatformVideoThumbnails.generateThumbnail(
          sharedFile.path,
          const ThumbnailOptions(
            timePosition: 1.0, width: 320, height: 240,
            quality: 0.8, format: ThumbnailFormat.png,
          ),
        );
        await File(targetPath).writeAsBytes(thumbnail.data);
        thumbnailPath = targetPath;
      } catch (e) {
        debugPrint("Error generating video thumbnail: $e");
      }
      _openNoteForm(initialData: {
        'title': 'Споделено видео',
        'content': 'Видео файл: ${sharedFile.path}',
        'imagePath': thumbnailPath,
        'id': null, 'color': null, 'isCompleted': 0, 'tags': null,
      });
    } else {
      _openNoteForm(initialData: {
        'imagePath': sharedFile.path,
        'title': 'Споделено изображение',
        'content': '',
        'id': null, 'color': null, 'isCompleted': 0, 'tags': null,
      });
    }
  }

  String? _extractYoutubeId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|shorts\/|.*[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  Future<void> _handleSharedText(String text) async {
    if (text.isEmpty) return;
    print("DEBUG: Получен текст за споделяне: '$text'");
    String? youtubeId = _extractYoutubeId(text);
    print("DEBUG: Извлечено YouTube ID: '$youtubeId'");
    String? thumbPath;
    String title = 'Споделен текст';
    if (youtubeId != null) {
      title = 'YouTube Видео';
      try {
        final response = await http.get(Uri.parse('https://img.youtube.com/vi/$youtubeId/0.jpg'));
        print("DEBUG: YouTube Thumbnail статус: ${response.statusCode}");
        if (response.statusCode == 200) {
          final appDir = await getApplicationDocumentsDirectory();
          thumbPath = p.join(appDir.path, 'yt_thumb_$youtubeId.jpg');
          await File(thumbPath).writeAsBytes(response.bodyBytes);
          print("DEBUG: Thumbnail записан в: $thumbPath");
        }
      } catch (e) {
        print("DEBUG: Грешка при теглене на thumbnail: $e");
      }
    }
    _openNoteForm(initialData: {
      'content': text,
      'title': title,
      'imagePath': thumbPath,
      'id': null, 'color': null, 'isCompleted': 0, 'tags': null,
    });
  }

  Future<void> _refreshItems() async {
    final data = await dbHelper.queryAllRows();
    if (!mounted) return;
    setState(() {
      _allItems = data;
      _updateUniqueTags();
      _filterItems(_searchController.text);
    });
  }

  void _updateUniqueTags() {
    final Set<String> tagsSet = {};
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
    setState(() {
      _allExistingTags = tagsSet;
      _selectedFilterTags.removeWhere((tag) => !tagsSet.contains(tag));
    });
  }

  void _filterItems(String query) {
    final lowercaseQuery = query.trim().toLowerCase();
    
    print("------------------------------------------");
    print("DEBUG: СТАРТ ФИЛТРИРАНЕ (Режим: ${_filterMatchAll ? 'AND' : 'OR'})");
    print("DEBUG: Текст за търсене: '$lowercaseQuery'");
    print("DEBUG: Избрани тагове: $_selectedFilterTags");

    setState(() {
      _filteredItems = _allItems.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final content = (item['content'] ?? '').toString().toLowerCase();
        final String rawTags = (item['tags'] ?? '').toString();
        
        final List<String> noteTagsList = rawTags
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        // 1. Текстово търсене
        bool matchesSearch = lowercaseQuery.isEmpty || 
                            title.contains(lowercaseQuery) || 
                            content.contains(lowercaseQuery);

        // 2. Филтриране по тагове
        bool matchesTags = true;
        if (_selectedFilterTags.isNotEmpty) {
          if (_filterMatchAll) {
            // AND логика: трябва да съдържа ВСИЧКИ избрани тагове
            matchesTags = _selectedFilterTags.every((String selectedTag) {
              return noteTagsList.contains(selectedTag);
            });
          } else {
            // OR логика: трябва да съдържа ПОНЕ ЕДИН от избраните
            matchesTags = _selectedFilterTags.any((String selectedTag) {
              return noteTagsList.contains(selectedTag);
            });
          }
        }

        return matchesSearch && matchesTags;
      }).toList();
    });
    
    print("DEBUG: КРАЙ. Намерени: ${_filteredItems.length}");
    print("------------------------------------------");
  }

  void _openNoteForm({Map<String, dynamic>? initialData}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteFormScreen(
          item: initialData,
          onSaved: _refreshItems,
          existingTags: _allExistingTags.toList(),
        ),
      ),
    );
    // Корекция за BuildContext в async: проверяваме mounted преди да викаме методи на State
    if (mounted) _refreshItems();
  }

  Future<void> _goToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    if (mounted) _loadSettings();
  }

  Future<void> _toggleView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = !_isGridView;
      prefs.setBool('is_grid_view', _isGridView);
    });
  }

  Future<void> _toggleComplete(Map<String, dynamic> item) async {
    final newStatus = item['isCompleted'] == 1 ? 0 : 1;
    await dbHelper.updateItem({
      ...item,
      'isCompleted': newStatus,
    });
    if (mounted) _refreshItems();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(_appBackgroundColor);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Color(_appBackgroundColor).withValues(alpha: 0.9),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => _filterItems(val),
            decoration: InputDecoration(
              hintText: 'Търсене...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _filterItems('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToSettings,
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleView,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              TagScrollFilter(
                allTags: _allExistingTags.toList(),
                selectedTags: _selectedFilterTags,
                onSelectionChanged: (newList) {
                  setState(() {
                    _selectedFilterTags = newList;
                  });
                  _filterItems(_searchController.text);
                },
              ),
              Expanded(
                child: _filteredItems.isEmpty
                    ? const Center(child: Text('Няма открити бележки.'))
                    : _isGridView ? _buildGrid() : _buildList(),
              ),
            ],
          ),
          FlyMenu(
            actions: [
              FlyAction(
                icon: _isGridView ? Icons.view_list : Icons.grid_view,
                onTap: _toggleView,
                label: "Изглед"
              ),
              FlyAction(
                icon: Icons.settings, 
                onTap: _goToSettings,
                label: "Настройки"
              ),
              FlyAction(
                icon: Icons.add, 
                onTap: () => _openNoteForm(),
                label: "Нова бележка"
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNoteForm(),
        tooltip: 'Нова бележка',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) => _buildNoteCard(_filteredItems[index], false),
    );
  }

  Widget _buildGrid() {
    List<Map<String, dynamic>> leftColumn = [];
    List<Map<String, dynamic>> rightColumn = [];

    for (int i = 0; i < _filteredItems.length; i++) {
      if (i % 2 == 0) {
        leftColumn.add(_filteredItems[i]);
      } else {
        rightColumn.add(_filteredItems[i]);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftColumn.map((item) => _buildNoteCard(item, true)).toList(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: rightColumn.map((item) => _buildNoteCard(item, true)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> item, bool isGrid) {
    final bool isDone = item['isCompleted'] == 1;
    final Color cardColor = item['color'] != null ? Color(item['color']) : Colors.white;

    Widget content = Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isDone,
                  onChanged: (_) => _toggleComplete(item),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item['title'] ?? 'Без заглавие',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _fontSizeTitle,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Linkify(
            text: item['content'] ?? '',
            onOpen: (link) async {
              final url = Uri.parse(link.url);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            maxLines: (item['content'] != null && (item['content'].contains('http://') || item['content'].contains('https://') || item['content'].contains('www.'))) ? 1 : (isGrid ? _maxLinesGrid : _maxLinesList), 
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _fontSizeContent,
              color: Colors.black87,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
            linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.none),
          ),
          if (item['reminderTime'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDateTime(item['reminderTime']),
                      style: const TextStyle(
                        fontSize: 10, 
                        color: Colors.redAccent, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final String? displayImagePath = item['imagePath'] ?? item['videoThumbnailPath'];

    if (!isGrid && displayImagePath != null) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            alignment: Alignment.topCenter,
            margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 100, maxWidth: 100),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(
                      File(displayImagePath), 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                    if (item['videoThumbnailPath'] != null)
                      const Icon(Icons.play_circle_fill, size: 30, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: content),
        ],
      );
    } else if (isGrid && displayImagePath != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: NoteGridImage(
              imagePath: displayImagePath,
              videoThumbnailPath: item['videoThumbnailPath'],
              backgroundColor: cardColor,
            ),
          ),
          content,
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Dismissible(
        key: Key(item['id'].toString()),
        direction: DismissDirection.startToEnd,
        background: Container(
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          if (!_confirmDelete) return true;
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Потвърждение'),
              content: const Text('Сигурни ли сте, че искате да изтриете тази бележка?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отказ'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Изтриване', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (direction) async {
          // Проверка дали бележката има локално копие на файл и го изтриваме
          final String? imagePath = item['imagePath'];
          final bool isLocal = item['isLocalCopy'] == 1;

          if (isLocal && imagePath != null) {
            try {
              final file = File(imagePath);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (e) {
              debugPrint("Грешка при изтриване на локален файл: $e");
            }
          }
          // Проверка дали бележката има миниатюра на видео и я изтриваме
          final String? videoThumbnailPath = item['videoThumbnailPath'];
          if (videoThumbnailPath != null) {
            try {
              final file = File(videoThumbnailPath);
              if (await file.exists()) await file.delete();
            } catch (e) {
              debugPrint("Грешка при изтриване на локален файл: $e");
            }
          }
          await dbHelper.deleteItem(item['id']);
          _refreshItems();
        },
        child: Card(
          margin: EdgeInsets.zero,
          color: cardColor,
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openNoteForm(initialData: item),
            child: content,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.day}.${dt.month.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }
}

class NoteGridImage extends StatefulWidget {
  final String imagePath;
  final String? videoThumbnailPath;
  final Color backgroundColor;
  const NoteGridImage({super.key, required this.imagePath, this.videoThumbnailPath, required this.backgroundColor});
  @override
  State<NoteGridImage> createState() => _NoteGridImageState();
}

class _NoteGridImageState extends State<NoteGridImage> {
  bool _isPortrait = false;
  @override
  void initState() {
    super.initState();
    _checkDimensions();
  }

  void _checkDimensions() {
    final image = FileImage(File(widget.imagePath));
    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool synchronousCall) {
        if (mounted) {
          setState(() {
            _isPortrait = info.image.height > info.image.width;
          });
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: widget.backgroundColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: EdgeInsets.only(top: _isPortrait ? 3 : 0),
              child: Image.file(
                File(widget.imagePath), 
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            if (widget.videoThumbnailPath != null)
              const Positioned.fill(
                child: Center(
                  child: Icon(Icons.play_circle_fill, size: 60, color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  runApp(const BusinessOrganizerApp());
}

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
  int _appBackgroundColor = const Color(0xFFFF5E00).toARGB32();
  bool _filterMatchAll = false;
  bool _confirmDelete = false;
  bool _compactGridView = false;
  int _maxLinesList = 5;
  int _maxLinesGrid = 5;
  double _fontSizeTitle = 14;
  double _fontSizeContent = 13;
  bool _showDate = false;
  bool _showFlyMenuLabels = false;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _appBackgroundColor = prefs.getInt('bg_color') ?? const Color(0xFFFF5E00).toARGB32();
      _filterMatchAll = prefs.getBool('filter_match_all') ?? false;
      _maxLinesList = prefs.getInt('max_lines_list') ?? 5;
      _maxLinesGrid = prefs.getInt('max_lines_grid') ?? 5;
      _fontSizeTitle = prefs.getDouble('list_title_size') ?? 14;
      _fontSizeContent = prefs.getDouble('list_content_size') ?? 13;
      _confirmDelete = prefs.getBool('confirm_delete') ?? false;
      _compactGridView = prefs.getBool('compact_grid_view') ?? false;
      _showDate = prefs.getBool('show_date') ?? false;
      _showFlyMenuLabels = prefs.getBool('show_fly_menu_labels') ?? false;
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
      String textPart = text.substring(0, match.start).trim();
      String urlPart = text.substring(match.start).trim();
      if (textPart.isNotEmpty) {
        finalTitle = '🔗 $textPart';
        finalContent = urlPart;
      } else {
        finalContent = urlPart;
      }
    }

    _openNoteForm(initialData: { 'content': finalContent, 'title': finalTitle, 'imagePath': thumbPath, 'id': null, 'color': null, 'isCompleted': 0, 'tags': null });
  }

  Future<void> _refreshItems() async {
    try {
      final data = await dbHelper.queryAllRows();
      if (!mounted) return;
      setState(() { _allItems = data; _updateUniqueTags(); _filterItems(_searchController.text); });
    } catch (e) { debugPrint("Грешка БД: $e"); }
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
    setState(() { _allExistingTags = tagsSet; _selectedFilterTags.removeWhere((tag) => !tagsSet.contains(tag)); });
  }

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
        return matchesSearch && matchesTags && matchesDate;
      }).toList();
    });
  }

  void _openNoteForm({Map<String, dynamic>? initialData}) async {
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (c) => NoteFormScreen(item: initialData, onSaved: _refreshItems, existingTags: _allExistingTags.toList())));
    if (mounted) _refreshItems();
  }

  Future<void> _goToSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()));
    if (mounted) _loadSettings();
  }

  Future<void> _toggleView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _isGridView = !_isGridView; prefs.setBool('is_grid_view', _isGridView); });
  }

  Future<void> _toggleComplete(Map<String, dynamic> item) async {
    final newStatus = item['isCompleted'] == 1 ? 0 : 1;
    await dbHelper.updateItem({ ...item, 'isCompleted': newStatus });
    if (mounted) _refreshItems();
  }

  @override
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
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => _filterItems(val),
            style: TextStyle(color: appBarTextColor),
            decoration: InputDecoration(
              hintText: 'Търсене...',
              hintStyle: TextStyle(color: appBarTextColor.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.search, color: appBarTextColor.withValues(alpha: 0.6)),
              suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear, size: 20, color: appBarTextColor), onPressed: () { _searchController.clear(); _filterItems(''); }) : null,
              filled: true,
              fillColor: (isDarkBg ? Colors.white : Colors.black).withValues(alpha: 0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _goToSettings),
          IconButton(icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view), onPressed: _toggleView),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              TagScrollFilter(
                allTags: _allExistingTags.toList(),
                selectedTags: _selectedFilterTags,
                textColor: appBarTextColor,
                startDate: _startDate,
                endDate: _endDate,
                onDateRangeChanged: (start, end) {
                  setState(() { _startDate = start; _endDate = end; });
                  _filterItems(_searchController.text);
                },
                onSelectionChanged: (newList) {
                  setState(() { _selectedFilterTags = newList; });
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
            showLabels: _showFlyMenuLabels,
            actions: [
              if (_selectedFilterTags.isNotEmpty || _startDate != null)
                FlyAction(
                  icon: Icons.label_off_outlined,
                  onTap: () {
                    setState(() {
                      _selectedFilterTags.clear();
                      _startDate = null;
                      _endDate = null;
                    });
                    _filterItems(_searchController.text);
                  },
                  label: "Без филтри",
                ),
              FlyAction(icon: _isGridView ? Icons.view_list : Icons.grid_view, onTap: _toggleView, label: "Изглед"),
              FlyAction(icon: Icons.settings, onTap: _goToSettings, label: "Настройки"),
              FlyAction(icon: Icons.add, onTap: () => _openNoteForm(), label: "Нова бележка"),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openNoteForm(), tooltip: 'Нова бележка', child: const Icon(Icons.add)),
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

  Widget _buildNoteCard(Map<String, dynamic> item, bool isGrid) {
    final bool isDone = item['isCompleted'] == 1;
    final Color cardColor = item['color'] != null ? Color(item['color']) : Colors.white;
    final Color textColor = cardColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    final Color secondaryTextColor = cardColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;
    final Color bottomColor = cardColor == Colors.white ? Colors.grey[100]! : HSLColor.fromColor(cardColor).withLightness((HSLColor.fromColor(cardColor).lightness - 0.1).clamp(0.0, 1.0)).toColor();
    Widget content = Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 24, height: 24, child: Checkbox(value: isDone, side: BorderSide(color: textColor.withValues(alpha: 0.5)), checkColor: cardColor, activeColor: textColor, onChanged: (_) => _toggleComplete(item))),
              const SizedBox(width: 4),
              Expanded(child: Text(item['title'] ?? 'Без заглавие', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSizeTitle, color: textColor, decoration: isDone ? TextDecoration.lineThrough : null))),
            ],
          ),
          const SizedBox(height: 4),
          _buildContentWithLinks(item['content'] ?? '', secondaryTextColor, textColor, isGrid),
          if (item['reminderTime'] != null && _showDate)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: secondaryTextColor),
                  const SizedBox(width: 4),
                  Expanded(child: Text('Дата: ${_formatDateTime(item['reminderTime'])}', style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
        ],
      ),
    );
    final String? displayImagePath = item['imagePath'];
    if (!isGrid && displayImagePath != null) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100, alignment: Alignment.topCenter, margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 100, maxWidth: 100), child: Image.file(File(displayImagePath), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)))),
          ),
          Expanded(child: content),
        ],
      );
    } else if (isGrid && displayImagePath != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(8)), child: NoteGridImage(imagePath: displayImagePath, backgroundColor: cardColor, compactView: _compactGridView)),
          content,
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Dismissible(
        key: Key(item['id'].toString()),
        direction: DismissDirection.startToEnd,
        background: Container(decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.delete, color: Colors.white)),
        confirmDismiss: (direction) async {
          if (!_confirmDelete) return true;
          return await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Потвърждение'), content: const Text('Сигурни ли сте, че искате да изтриете тази бележка?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отказ')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Изтриване', style: TextStyle(color: Colors.red)))])) ?? false;
        },
        onDismissed: (direction) async {
          if (item['isLocalCopy'] == 1 && item['imagePath'] != null) { try { final f = File(item['imagePath']); if (await f.exists()) await f.delete(); } catch (e) { debugPrint("Грешка файл: $e"); } }
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
            child: InkWell(borderRadius: BorderRadius.circular(8), onTap: () => _openNoteForm(initialData: item), child: content),
          ),
        ),
      ),
    );
  }

  Widget _buildContentWithLinks(String content, Color secondaryTextColor, Color textColor, bool isGrid) {
    final urlRegExp = RegExp(r'(https?:\/\/[^\s]+|www\.[^\s]+)');
    final match = urlRegExp.firstMatch(content);
    final linkStyle = TextStyle(color: textColor == Colors.white ? Colors.lightBlueAccent : Colors.blue, decoration: TextDecoration.none);
    
    if (match != null) {
      final textPart = content.substring(0, match.start).trim();
      final urlPart = content.substring(match.start).trim();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (textPart.isNotEmpty)
            Text(
              textPart,
              maxLines: isGrid ? _maxLinesGrid : _maxLinesList,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: _fontSizeContent, color: secondaryTextColor),
            ),
          Linkify(
            text: urlPart,
            onOpen: (link) async {
              final url = Uri.parse(link.url);
              if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); }
            },
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: _fontSizeContent, color: secondaryTextColor),
            linkStyle: linkStyle,
          ),
        ],
      );
    }
    return Linkify(
      text: content,
      onOpen: (link) async {
        final url = Uri.parse(link.url);
        if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); }
      },
      maxLines: isGrid ? _maxLinesGrid : _maxLinesList,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: _fontSizeContent, color: secondaryTextColor),
      linkStyle: linkStyle,
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.day}.${dt.month.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) { return ''; }
  }
}

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

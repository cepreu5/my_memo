import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';

import 'db_helper.dart';
import 'note_form.dart';
import 'settings_screen.dart';
import 'tag_scroll.dart';
import 'fly_menu.dart'; 

void main() {
  runApp(const BusinessOrganizerApp());
}

class BusinessOrganizerApp extends StatelessWidget {
  const BusinessOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Бизнес Органайзер',
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

  void _handleSharedMedia(List<SharedMediaFile> media) {
    final sharedFile = media.first;
    if (sharedFile.type == SharedMediaType.text || sharedFile.type == SharedMediaType.url) {
      _handleSharedText(sharedFile.path);
    } else {
      _openNoteForm(initialData: {
        'imagePath': sharedFile.path,
        'title': 'Споделено изображение',
        'content': '',
        'id': null,
        'color': null,
        'isCompleted': 0,
        'tags': null,
      });
    }
  }

  void _handleSharedText(String text) {
    if (text.isEmpty) return;
    _openNoteForm(initialData: {
      'content': text,
      'title': 'Споделен текст',
      'id': null,
      'color': null,
      'isCompleted': 0,
      'tags': null,
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
    final tagsSet = <String>{};
    for (var item in _allItems) {
      final String? tagsString = item['tags'];
      if (tagsString != null && tagsString.isNotEmpty) {
        final List<String> tagsList = tagsString.split(',');
        for (var tag in tagsList) {
          final trimmed = tag.trim();
          if (trimmed.isNotEmpty) tagsSet.add(trimmed);
        }
      }
    }
    _allExistingTags = tagsSet;
    _selectedFilterTags.removeWhere((tag) => !tagsSet.contains(tag));
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
                    fontSize: 14,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item['content'] ?? '',
            maxLines: isGrid ? _maxLinesGrid : _maxLinesList, 
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
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

    if (!isGrid && item['imagePath'] != null) {
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
                child: Image.file(File(item['imagePath']), fit: BoxFit.cover),
              ),
            ),
          ),
          Expanded(child: content),
        ],
      );
    } else if (isGrid && item['imagePath'] != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Container(
                width: double.infinity,
                alignment: Alignment.topCenter,
                child: Image.file(File(item['imagePath']), fit: BoxFit.contain),
              ),
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
      return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }
}

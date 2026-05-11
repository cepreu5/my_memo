import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import 'fly_menu.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'color_picker_helper.dart';

class NoteFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  final List<String> existingTags;
  final List<Map<String, dynamic>>? allNotes;
  final int? initialIndex;
  final bool startInEditMode;
  const NoteFormScreen({super.key, this.item, required this.onSaved, this.existingTags = const [], this.allNotes, this.initialIndex, this.startInEditMode = false});
  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController(); 
  final _contentFocusNode = FocusNode();
  String? _imagePath;

  DateTime? _reminderTime;
  Color _selectedColor = Colors.white;
  int _isLocalCopy = 0; 
  bool _shouldCopyLocally = false;
  List<String> _selectedTags = [];
  bool _sessionFileCreated = false;
  final dbHelper = DatabaseHelper();
  bool _isEditing = false;
  double _fontSizeTitle = 18;
  double _fontSizeContent = 16;
  final List<String> _newTagsInSession = [];
  int? _currentIndex;
  List<Map<String, dynamic>> _allNotes = [];
  bool _isTask = false;
  int _isCompleted = 0;
  int _appColor = const Color(0xFFFF5E00).toARGB32();
  final List<Color> _noteColors = [
    Colors.white,
    const Color(0xFF0A1931),
    const Color(0xFFFF5E00),
    const Color(0xFFFFC93C),
    const Color(0xFF6A2C70),
    const Color(0xFFB83B5E),
    const Color(0xFF005082),
  ];
  Color get _textColor => _contrast(_selectedColor, Colors.black87, Colors.white);
  Color get _secondaryTextColor => _contrast(_selectedColor, Colors.black54, Colors.white70);
  Color get _areaColor => Color.lerp(_selectedColor, _contrast(_selectedColor, Colors.black, Colors.white), 0.05)!;
  Color _contrast(Color background, Color ifBright, Color ifDark) {
    return background.computeLuminance() > 0.5 ? ifBright : ifDark;
  }

  @override
  void initState() {
    super.initState();
    if (widget.allNotes != null) {
      _allNotes = List.from(widget.allNotes!);
      _currentIndex = widget.initialIndex;
    }
    _initializeData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSizeTitle = prefs.getDouble('form_title_size') ?? 18;
      _fontSizeContent = prefs.getDouble('form_content_size') ?? 16;
      _appColor = prefs.getInt('bg_color') ?? const Color(0xFFFF5E00).toARGB32();
      final customList = prefs.getStringList('custom_palette') ?? [];
      final customColors = customList.map((s) => Color(int.parse(s))).toList();
      for (var c in customColors) { if (!_noteColors.contains(c)) _noteColors.add(c); }
    });
    if (widget.item != null) {
      _titleController.text = widget.item!['title']?.toString() ?? "";
      _contentController.text = widget.item!['content']?.toString() ?? "";
      _imagePath = widget.item!['imagePath'];

      _isLocalCopy = widget.item!['isLocalCopy'] ?? 0;
      if (widget.item!['id'] == null && _imagePath != null && _isLocalCopy == 0) { _shouldCopyLocally = true; } else { _shouldCopyLocally = _isLocalCopy == 1; }
      if (widget.item!['tags'] != null && widget.item!['tags'].toString().isNotEmpty) { _selectedTags = widget.item!['tags'].toString().split(',').map((e) => e.trim()).toList(); }
      if (widget.item!['reminderTime'] != null) { try { _reminderTime = DateTime.parse(widget.item!['reminderTime']); } catch (e) { debugPrint("Грешка дата: $e"); } }
      else { _reminderTime = DateTime.now(); }
      if (widget.item!['color'] != null) { _selectedColor = Color(widget.item!['color']); } else { await _loadDefaultColor(); }
      _isCompleted = widget.item!['isCompleted'] ?? 0;
      _isTask = _isCompleted == 1 || _isCompleted == 2;
      _isEditing = widget.item!['id'] == null || widget.startInEditMode;
    } else { _isEditing = true; await _loadDefaultColor(); }
    if (!_noteColors.contains(_selectedColor)) { _noteColors.add(_selectedColor); }
    if (mounted) setState(() {});
  }

  void _deleteCurrentFileIfLocal() {
    if (_isLocalCopy == 1 && _imagePath != null) { try { final f = File(_imagePath!); if (f.existsSync()) f.deleteSync(); } catch (e) { debugPrint("Грешка чистене файл: $e"); } }
  }

  Future<void> _loadDefaultColor() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultColorVal = prefs.getInt('default_note_color');
    if (defaultColorVal != null) { setState(() { _selectedColor = Color(defaultColorVal); }); }
    final customList = prefs.getStringList('custom_palette') ?? [];
    for (var s in customList) {
      final c = Color(int.parse(s));
      if (!_noteColors.contains(c)) _noteColors.add(c);
    }
    if (!_noteColors.contains(_selectedColor)) { _noteColors.add(_selectedColor); }
  }

  void _showTagsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allAvailableTags = { ...widget.existingTags, ..._newTagsInSession }.toList()..sort();
            final Color contrastColor = _contrast(Color(_appColor), Colors.black, Colors.white);
            final Color secondaryContrast = _contrast(Color(_appColor), Colors.black54, Colors.white70);
            return AlertDialog(
              backgroundColor: Color(_appColor),
              title: Text("Управление на етикети", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: contrastColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allAvailableTags.isNotEmpty) ...[
                      Text("Избери:", style: TextStyle(fontSize: 12, color: secondaryContrast)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4, runSpacing: 4,
                        children: allAvailableTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return FilterChip(
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                            label: Text(tag, style: const TextStyle(fontSize: 10, color: Colors.black)),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() { val ? _selectedTags.add(tag) : _selectedTags.remove(tag); });
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
                              if (val.trim().isNotEmpty && !_selectedTags.contains(val.trim())) {
                                setState(() { _selectedTags.add(val.trim()); _newTagsInSession.add(val.trim()); });
                                _tagController.clear();
                                setModalState(() {});
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, size: 20, color: contrastColor),
                          onPressed: () {
                            final val = _tagController.text;
                            if (val.trim().isNotEmpty && !_selectedTags.contains(val.trim())) {
                              setState(() { _selectedTags.add(val.trim()); _newTagsInSession.add(val.trim()); });
                              _tagController.clear();
                              setModalState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Затвори", style: TextStyle(color: secondaryContrast)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _cropImage(String path) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Изрязване', toolbarColor: Colors.deepPurple, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.original, lockAspectRatio: false),
        IOSUiSettings(title: 'Изрязване'),
      ],
    );
    return croppedFile?.path;
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final croppedPath = await _cropImage(pickedFile.path);
        setState(() {
          _deleteCurrentFileIfLocal();
          if (croppedPath != null) { _imagePath = croppedPath; _shouldCopyLocally = true; } 
          else { _imagePath = pickedFile.path; _shouldCopyLocally = true; }
          _isLocalCopy = 0;
        });
      }
    } catch (e) { debugPrint("Грешка галерия: $e"); }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final croppedPath = await _cropImage(pickedFile.path);
        if (croppedPath != null) {
          final String? copiedPath = await _copyImageLocally(croppedPath);
          if (copiedPath != null) {
            setState(() {
              _deleteCurrentFileIfLocal();
              _imagePath = copiedPath;
              _isLocalCopy = 1;
              _shouldCopyLocally = true;
              _sessionFileCreated = true;
            });
          }
        }
      }
    } catch (e) { debugPrint("Грешка камера: $e"); }
  }

  Future<void> _editExistingImage() async {
    if (_imagePath == null) return;
    final croppedPath = await _cropImage(_imagePath!);
    if (croppedPath != null) {
      setState(() {
        _deleteCurrentFileIfLocal();
        _imagePath = croppedPath;
        _isLocalCopy = 0;
        _shouldCopyLocally = true;
      });
    }
  }

  Future<String?> _copyImageLocally(String originalPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = "img_${DateTime.now().millisecondsSinceEpoch}${p.extension(originalPath)}";
      final String newPath = p.join(directory.path, fileName);
      await File(originalPath).copy(newPath);
      return newPath;
    } catch (e) { debugPrint("Грешка копиране: $e"); }
    return null;
  }

  Future<void> _save({bool closeAfterSave = true}) async {
    _reminderTime = DateTime.now(); // Автоматично обновяваме датата при всяко записване
    String? finalPath = _imagePath;
    int finalIsLocal = _isLocalCopy;
    if (_imagePath != null && _shouldCopyLocally && _isLocalCopy == 0) {
      final String? copied = await _copyImageLocally(_imagePath!);
      if (copied != null) { finalPath = copied; finalIsLocal = 1; }
    }
    final Map<String, dynamic> data = {
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'imagePath': finalPath,
      'reminderTime': _reminderTime?.toIso8601String(),
      'color': _selectedColor.toARGB32(),
      'isCompleted': _isTask ? (_isCompleted == 1 ? 1 : 2) : 0,
      'isLocalCopy': finalIsLocal,
      'tags': _selectedTags.join(', '),
    };
    try {
      if (widget.item == null || widget.item!['id'] == null) { 
        final id = await dbHelper.insertItem(data);
        if (widget.item != null) widget.item!['id'] = id;
      } else { 
        data['id'] = widget.item!['id']; 
        await dbHelper.updateItem(data); 
      }
      widget.onSaved();
      if (closeAfterSave && mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Грешка запис: $e'), backgroundColor: Colors.red)); }
  }

  Future<void> _switchToNote(int index) async {
    if (index < 0 || index >= _allNotes.length) return;
    await _save(closeAfterSave: false);
    setState(() {
      _currentIndex = index;
      _initializeDataFromItem(_allNotes[index]);
    });
  }

  void _initializeDataFromItem(Map<String, dynamic> item) {
    _titleController.text = item['title']?.toString() ?? "";
    _contentController.text = item['content']?.toString() ?? "";
    _imagePath = item['imagePath'];
    _isLocalCopy = item['isLocalCopy'] ?? 0;
    _selectedTags = [];
    if (item['tags'] != null && item['tags'].toString().isNotEmpty) {
      _selectedTags = item['tags'].toString().split(',').map((e) => e.trim()).toList();
    }
    if (item['reminderTime'] != null) {
      try { _reminderTime = DateTime.parse(item['reminderTime']); } catch (e) { _reminderTime = DateTime.now(); }
    } else { _reminderTime = DateTime.now(); }
    if (item['color'] != null) { _selectedColor = Color(item['color']); }
    _isCompleted = item['isCompleted'] ?? 0;
    _isTask = _isCompleted == 1 || _isCompleted == 2;
    _isEditing = false;
  }

  void _moveFirstParagraphToTitle() {
    final String content = _contentController.text.trim();
    if (content.isEmpty) return;
    final List<String> parts = content.split('\n');
    final String firstPara = parts[0].trim();
    if (firstPara.isEmpty) return;
    setState(() {
      _titleController.text = '${_titleController.text.trim()} $firstPara'.trim();
      _contentController.text = parts.sublist(1).join('\n').trim();
    });
  }
  void _toggleList(String type) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    int start = selection.start;
    int end = selection.end;
    if (start == -1) { start = 0; end = text.length; }
    if (start > end) { final t = start; start = end; end = t; }
    int lineStart = text.lastIndexOf('\n', start - 1) + 1;
    int lineEnd = text.indexOf('\n', end);
    if (lineEnd == -1) lineEnd = text.length;
    String selectedPart = text.substring(lineStart, lineEnd);
    List<String> lines = selectedPart.split('\n');
    RegExp bulletPattern = RegExp(r'^[•\-\*]\s+');
    RegExp numberPattern = RegExp(r'^\d+\.\s+');
    RegExp checkPattern = RegExp(r'^([☐☑]|\[\s?[xXvV]?\s?\])\s+');
    RegExp anyPattern = RegExp(r'^([•\-\*]\s+|\d+\.\s+|([☐☑]|\[\s?[xXvV]?\s?\])\s+)');
    RegExp targetPattern = type == 'bullet' ? bulletPattern : (type == 'number' ? numberPattern : checkPattern);
    bool allHaveTarget = true;
    for (var line in lines) { if (line.trim().isNotEmpty && !targetPattern.hasMatch(line)) { allHaveTarget = false; break; } }
    List<String> newLines = [];
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (allHaveTarget) { newLines.add(line.replaceFirst(targetPattern, '')); } 
      else {
        String cleanLine = line.replaceFirst(anyPattern, '');
        if (type == 'bullet') newLines.add('• $cleanLine');
        else if (type == 'number') newLines.add('${i + 1}. $cleanLine');
        else if (type == 'check') newLines.add('☐ $cleanLine');
      }
    }
    String newJoined = newLines.join('\n');
    _contentController.value = TextEditingValue(text: text.replaceRange(lineStart, lineEnd, newJoined), selection: TextSelection(baseOffset: lineStart, extentOffset: lineStart + newJoined.length));
  }
  void _onLinkOpen(LinkableElement link) async {
    final url = Uri.parse(link.url);
    if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); }
  }
  void _calculateNote() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    String input = (selection.start != -1 && selection.end != -1 && selection.start != selection.end) ? text.substring(selection.start, selection.end) : text;
    List<String> lines = input.split('\n');
    List<String> parts = [];
    RegExp listPrefix = RegExp(r'^(\d+\.\s+|[•\-\*]\s+|[☐☑]\s+)');
    RegExp datePrefix = RegExp(r'^\d{1,2}[\./-]\d{1,2}([\./-]\d{2,4})?\s+');
    RegExp onlyMath = RegExp(r'^[0-9+\-*/().\s,xXхХ]+$');
    RegExp trailingExpr = RegExp(r'([+\-*/xXхХ]?\s*[0-9().,xXхХ+\-*/\s]*\d[0-9().,xXхХ+\-*/\s]*)$');
    for (var line in lines) {
      String processed = line.trim();
      if (processed.isEmpty) continue;
      processed = processed.replaceFirst(listPrefix, '');
      processed = processed.replaceFirst(datePrefix, '');
      if (processed.isEmpty) continue;
      String matchStr = "";
      if (onlyMath.hasMatch(processed)) { matchStr = processed; } 
      else {
        final m = trailingExpr.firstMatch(processed);
        if (m != null) matchStr = m.group(0)!;
      }
      if (matchStr.trim().isNotEmpty) {
        String clean = matchStr.replaceAll(',', '.').replaceAll(RegExp(r'[xXхХ]'), '*').trim();
        if (parts.isNotEmpty && !clean.startsWith(RegExp(r'[+\-*/]'))) { parts.add('+'); }
        parts.add(clean);
      }
    }
    String expr = parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (expr.isEmpty) return;
    try {
      double res = _evaluateExpression(expr);
      String resStr = "= ${res.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}";
      Clipboard.setData(ClipboardData(text: resStr));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$expr $resStr (Копирано)"), duration: const Duration(seconds: 5)));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Грешка при изчисление: $expr"))); }
  }
  double _evaluateExpression(String expr) {
    final tokens = RegExp(r'\d+(\.\d+)?|[+\-*/()]').allMatches(expr.replaceAll(',', '.')).map((m) => m.group(0)!).toList();
    if (tokens.isEmpty) return 0;
    List<double> values = [];
    List<String> ops = [];
    int precedence(String op) { if (op == '+' || op == '-') return 1; if (op == '*' || op == '/') return 2; return 0; }
    void applyOp() {
      if (values.length < 2 || ops.isEmpty) return;
      double b = values.removeLast();
      double a = values.removeLast();
      String op = ops.removeLast();
      if (op == '+') values.add(a + b);
      else if (op == '-') values.add(a - b);
      else if (op == '*') values.add(a * b);
      else if (op == '/') values.add(a / b);
    }
    for (var token in tokens) {
      if (RegExp(r'^\d').hasMatch(token)) { values.add(double.parse(token)); }
      else if (token == '(') { ops.add(token); }
      else if (token == ')') { while (ops.isNotEmpty && ops.last != '(') applyOp(); if (ops.isNotEmpty) ops.removeLast(); }
      else {
        while (ops.isNotEmpty && precedence(ops.last) >= precedence(token)) applyOp();
        ops.add(token);
      }
    }
    while (ops.isNotEmpty) applyOp();
    return values.isNotEmpty ? values.first : 0;
  }
  void _moveToLineStart() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.start == -1) return;
    int lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    _contentController.selection = TextSelection.collapsed(offset: lineStart);
  }
  void _moveToLineEndOrTab() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.start == -1) return;
    int lineEnd = text.indexOf('\n', selection.start);
    if (lineEnd == -1) lineEnd = text.length;
    if (selection.start < lineEnd) { _contentController.selection = TextSelection.collapsed(offset: lineEnd); } 
    else {
      int lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
      int targetColumn = 30;
      int spacesToAdd = targetColumn - (selection.start - lineStart);
      if (spacesToAdd <= 0) spacesToAdd = 4;
      String spaces = " " * spacesToAdd;
      _contentController.value = TextEditingValue(text: text.replaceRange(selection.start, selection.start, spaces), selection: TextSelection.collapsed(offset: selection.start + spacesToAdd));
    }
  }
  void _toggleCheckboxLine(int index) {
    final lines = _contentController.text.split('\n');
    final line = lines[index];
    final match = RegExp(r'^([☐☑]|\[\s?[xXvV]?\s?\])\s+').firstMatch(line);
    if (match != null) {
      final isChecked = line.startsWith('☑') || match.group(0)!.contains(RegExp(r'[xv]'));
      lines[index] = line.replaceFirst(RegExp(r'^([☐☑]|\[\s?[xXvV]?\s?\])\s+'), isChecked ? '☐ ' : '☑ ');
      setState(() { _contentController.text = lines.join('\n'); });
      _save(closeAfterSave: false);
    }
  }

  String? _extractYoutubeId(String url) {
    final regExp = RegExp(r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|shorts\/|.*[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})', caseSensitive: false);
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  Future<void> _deleteNote() async {
    if (widget.item?['id'] == null) return;
    final prefs = await SharedPreferences.getInstance();
    bool confirm = true;
    if (prefs.getBool('confirm_delete') ?? true) {
      if (!mounted) return;
      confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Color(_appColor),
          title: Text('Изтриване', style: TextStyle(color: _contrast(Color(_appColor), Colors.black, Colors.white))),
          content: Text('Сигурни ли сте, че искате да изтриете тази бележка?', style: TextStyle(color: _contrast(Color(_appColor), Colors.black87, Colors.white70))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Отказ', style: TextStyle(color: _contrast(Color(_appColor), Colors.black54, Colors.white60)))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Изтрий', style: TextStyle(color: Colors.red))),
          ],
        ),
      ) ?? false;
    }
    if (!confirm) return;
    if (_isLocalCopy == 1 && _imagePath != null) {
      bool isUsed = await dbHelper.isImagePathUsed(_imagePath!, widget.item!['id']);
      if (!isUsed) { try { final f = File(_imagePath!); if (await f.exists()) await f.delete(); } catch (e) { debugPrint("Грешка изтриване файл: $e"); } }
    }
    if (!mounted) return;
    await dbHelper.deleteItem(widget.item!['id']);
    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  void _openFullScreenImage() async {
    if (_imagePath == null) return;
    if (_extractYoutubeId(_contentController.text) != null) {
      final url = Uri.parse(_contentController.text.trim());
      if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); return; }
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImage(imagePath: _imagePath!, title: _titleController.text.isEmpty ? "Преглед" : _titleController.text)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        if (_currentIndex == null) return;
        if (details.primaryVelocity! > 0) { _switchToNote(_currentIndex! + 1); } // Надясно = следваща
        else if (details.primaryVelocity! < 0) { _switchToNote(_currentIndex! - 1); } // Наляво = предишна
      },
      onVerticalDragEnd: (details) {
        if (_currentIndex == null) return;
        if (details.primaryVelocity! < 0) { _switchToNote(_currentIndex! + 1); } // Нагоре = следваща
        else if (details.primaryVelocity! > 0) { _switchToNote(_currentIndex! - 1); } // Надолу = предишна
      },
      child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_isEditing || (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty)) { Navigator.of(context).pop(); return; }
        final bool shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color(_appColor),
            title: Text('Отхвърляне на промените?', style: TextStyle(color: _contrast(Color(_appColor), Colors.black, Colors.white))),
            content: Text('Имате незапазени промени. Сигурни ли сте, че искате да излезете?', style: TextStyle(color: _contrast(Color(_appColor), Colors.black87, Colors.white70))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Отказ', style: TextStyle(color: _contrast(Color(_appColor), Colors.black54, Colors.white60)))),
              TextButton(onPressed: () {
                if (_sessionFileCreated && _imagePath != null && _isLocalCopy == 1) { try { File(_imagePath!).deleteSync(); } catch (e) { debugPrint("Грешка чистене при изход: $e"); } }
                Navigator.pop(context, true);
              }, child: Text('Отхвърли', style: TextStyle(color: _contrast(Color(_appColor), Colors.black54, Colors.white60)))),
            ],
          ),
        ) ?? false;
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: _selectedColor,
        appBar: AppBar(
          backgroundColor: _selectedColor,
          elevation: 0,
          foregroundColor: _textColor,
          title: Text(_isEditing ? (widget.item?['id'] == null ? 'Нова бележка' : 'Редактиране') : 'Преглед', style: TextStyle(color: _textColor)),
          actions: [
            if (!_isEditing) IconButton(icon: const Icon(Icons.calculate_outlined), color: _textColor, onPressed: _calculateNote, tooltip: 'Калкулатор'),
            if (widget.item?['id'] != null) IconButton(icon: const Icon(Icons.delete_outline), color: _textColor, onPressed: _deleteNote),
            if (!_isEditing) IconButton(icon: const Icon(Icons.edit), color: _textColor, onPressed: () => setState(() => _isEditing = true))
            else IconButton(icon: const Icon(Icons.save), color: _textColor, onPressed: _save),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectionArea(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () { if (!_isEditing) setState(() => _isEditing = true); _contentFocusNode.requestFocus(); },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_imagePath != null)
                              GestureDetector(
                                onTap: (_isEditing && _extractYoutubeId(_contentController.text) == null) ? _editExistingImage : _openFullScreenImage,
                                child: Stack(
                                  children: [
                                    Container(
                                      constraints: const BoxConstraints(maxHeight: 400),
                                      width: double.infinity,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(File(_imagePath!), fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                                      ),
                                    ),
                                    if (_isEditing && _imagePath != null)
                                      const Positioned(right: 8, bottom: 8, child: CircleAvatar(radius: 18, backgroundColor: Colors.black54, child: Icon(Icons.crop, color: Colors.white, size: 20))),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(color: _areaColor, borderRadius: BorderRadius.circular(8)),
                              child: _isEditing 
                                ? Stack(
                                    alignment: Alignment.centerRight,
                                    children: [
                                      TextField(
                                        controller: _titleController, 
                                        maxLines: null, 
                                        style: TextStyle(fontSize: _fontSizeTitle, fontWeight: FontWeight.bold, color: _textColor), 
                                        decoration: InputDecoration(hintText: 'Заглавие', border: InputBorder.none, hintStyle: TextStyle(color: _secondaryTextColor), contentPadding: const EdgeInsets.only(right: 32)),
                                        contextMenuBuilder: (context, editableTextState) => AdaptiveTextSelectionToolbar.editableText(editableTextState: editableTextState),
                                      ),
                                      if (_contentController.text.trim().isNotEmpty)
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: _moveFirstParagraphToTitle,
                                          icon: Icon(Icons.arrow_upward, size: 16, color: _secondaryTextColor),
                                          tooltip: 'Премести първия параграф към заглавието',
                                        ),
                                    ],
                                  )
                                : _titleController.text.isNotEmpty 
                                    ? Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_titleController.text, style: TextStyle(fontSize: _fontSizeTitle, fontWeight: FontWeight.bold, color: _textColor)))
                                    : const SizedBox.shrink(),
                            ),
                            if (_selectedTags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Wrap(spacing: 6, runSpacing: 0, children: _selectedTags.map((tag) => Chip(
                                  label: Text(tag, style: TextStyle(fontSize: 12, color: _textColor)),
                                  backgroundColor: _textColor.withValues(alpha: 0.1),
                                  side: BorderSide(color: _textColor.withValues(alpha: 0.2)),
                                  padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onDeleted: _isEditing ? () => setState(() => _selectedTags.remove(tag)) : null,
                                  deleteIconColor: _textColor,
                                )).toList()),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(color: _areaColor, borderRadius: BorderRadius.circular(8)),
                              child: _isEditing 
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(icon: const Icon(Icons.keyboard_arrow_left), onPressed: _moveToLineStart, color: _secondaryTextColor, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, tooltip: 'Начало на ред'),
                                          const Spacer(),
                                          IconButton(icon: const Icon(Icons.keyboard_arrow_right), onPressed: _moveToLineEndOrTab, color: _secondaryTextColor, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, tooltip: 'Край на ред / Таб'),
                                        ],
                                      ),
                                      TextField(
                                        controller: _contentController, 
                                        focusNode: _contentFocusNode, 
                                        maxLines: null, 
                                        style: TextStyle(fontSize: _fontSizeContent, color: _textColor, height: 1.2), 
                                        decoration: InputDecoration(hintText: 'Съдържание...', border: InputBorder.none, hintStyle: TextStyle(color: _secondaryTextColor)), 
                                        onSubmitted: (v) => _save(),
                                        contextMenuBuilder: (context, editableTextState) => AdaptiveTextSelectionToolbar.editableText(editableTextState: editableTextState),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _contentController.text.split('\n').asMap().entries.map((e) {
                                      final line = e.value;
                                      final index = e.key;
                                      final checkMatch = RegExp(r'^([☐☑]|\[\s?[xXvV]?\s?\])\s+').firstMatch(line);
                                      if (checkMatch != null) {
                                        final isChecked = line.startsWith('☑') || checkMatch.group(0)!.contains(RegExp(r'[xv]'));
                                        return InkWell(
                                          onTap: () => _toggleCheckboxLine(index),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, size: 22, color: _textColor),
                                                const SizedBox(width: 8),
                                                Expanded(child: Linkify(
                                                  text: line.substring(checkMatch.end),
                                                  onOpen: _onLinkOpen,
                                                  style: TextStyle(fontSize: _fontSizeContent, color: _textColor, decoration: isChecked ? TextDecoration.lineThrough : null, height: 1.2),
                                                  linkStyle: TextStyle(color: _textColor == Colors.white ? Colors.lightBlueAccent : Colors.blue),
                                                )),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      return Linkify(
                                        text: line,
                                        onOpen: _onLinkOpen,
                                        style: TextStyle(fontSize: _fontSizeContent, color: _textColor, height: 1.2),
                                        linkStyle: TextStyle(color: _textColor == Colors.white ? Colors.lightBlueAccent : Colors.blue),
                                      );
                                    }).toList(),
                                  ),
                            ),
                            if (_isEditing && _imagePath != null && _isLocalCopy == 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SwitchListTile(
                                  title: Text("Копирай локално", style: TextStyle(fontSize: 14, color: _textColor)),
                                  subtitle: Text("Запазва снимката, дори да бъде изтрита от галерията", style: TextStyle(fontSize: 11, color: _secondaryTextColor)),
                                  value: _shouldCopyLocally,
                                  activeThumbColor: Colors.blue,
                                  onChanged: (val) async {
                                    if (val == false) {
                                      final bool confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
                                        title: const Text('Внимание'), content: const Text('Ако изключите локалното копиране, приложението ще разчита на временен файл в кеша. Ако кешът бъде изчистен, файлът ще изчезне.'),
                                        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отказ')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Изключи', style: TextStyle(color: Colors.red)))],
                                      )) ?? false;
                                      if (confirm) setState(() => _shouldCopyLocally = false);
                                    } else { setState(() => _shouldCopyLocally = true); }
                                  },
                                  dense: true, contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isEditing) _buildBottomTools(),
              ],
            ),
            FlyMenu(actions: [
              if (widget.item?['id'] != null) FlyAction(icon: Icons.delete, onTap: _deleteNote, label: "Изтрий"),
              FlyAction(icon: Icons.arrow_back, onTap: () => Navigator.maybePop(context), label: "Назад"),
              if (_isEditing) FlyAction(icon: Icons.save, onTap: _save, label: "Запази"),
              if (!_isEditing) FlyAction(icon: Icons.calculate_outlined, onTap: _calculateNote, label: "Калкулатор"),
              if (!_isEditing) FlyAction(icon: Icons.edit, onTap: () => setState(() => _isEditing = true), label: "Редактирай"),
            ]),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildBottomTools() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(color: _areaColor, border: Border(top: BorderSide(color: _textColor.withValues(alpha: 0.1)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._noteColors.map((color) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6), width: 30, height: 30,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: _selectedColor == color ? Colors.blue : Colors.black26, width: _selectedColor == color ? 2 : 1)),
                  ),
                )),
                GestureDetector(
                  onTap: () async {
                    final picked = await showCustomColorPicker(context, _selectedColor);
                    if (picked != null) { setState(() { if (!_noteColors.contains(picked)) { _noteColors.add(picked); } _selectedColor = picked; }); }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6), width: 30, height: 30,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
                    child: const Icon(Icons.colorize, size: 16, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Row(
            children: [
              IconButton(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, icon: const Icon(Icons.photo_library, size: 20), onPressed: _pickFromGallery, tooltip: 'Галерия'),
              IconButton(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, icon: const Icon(Icons.camera_alt, size: 20), onPressed: _pickFromCamera, tooltip: 'Камера'),
              IconButton(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, icon: const Icon(Icons.label_outline, size: 20), onPressed: _showTagsDialog, tooltip: 'Етикети'),
              IconButton(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, icon: const Icon(Icons.format_list_bulleted, size: 20), onPressed: () => _toggleList('bullet'), tooltip: 'Списък'),
              IconButton(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, icon: const Icon(Icons.format_list_numbered, size: 20), onPressed: () => _toggleList('number'), tooltip: 'Номериран списък'),
              IconButton(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, icon: const Icon(Icons.checklist, size: 20), onPressed: () => _toggleList('check'), tooltip: 'Пазаруване'),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: Checkbox(
                      value: _isTask,
                      side: BorderSide(color: _secondaryTextColor),
                      activeColor: _textColor == Colors.black87 ? Colors.black87 : Colors.white,
                      checkColor: _selectedColor,
                      onChanged: (val) => setState(() => _isTask = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('Задача', style: TextStyle(color: _secondaryTextColor, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imagePath;
  final String title;
  const FullScreenImage({super.key, required this.imagePath, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(title)),
      body: Center(child: InteractiveViewer(child: Image.file(File(imagePath), fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 100, color: Colors.white24)))),
    );
  }
}
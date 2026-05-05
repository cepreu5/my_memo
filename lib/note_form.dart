import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import 'fly_menu.dart'; // Добавен импорт за плаващото меню
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'color_picker_helper.dart';

class NoteFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  final List<String> existingTags; // Добавен списък със съществуващи етикети

  const NoteFormScreen({
    super.key, 
    this.item, 
    required this.onSaved, 
    this.existingTags = const []
  });

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController(); // За добавяне на нов етикет в модала
  
  String? _imagePath;
  DateTime? _reminderTime;
  Color _selectedColor = Colors.white;
  int _isLocalCopy = 0; 
  bool _shouldCopyLocally = false;
  List<String> _selectedTags = []; // Избраните етикети за текущата бележка
  bool _sessionFileCreated = false; // Следи дали е създаден файл в тази сесия (напр. от камера)
  
  final dbHelper = DatabaseHelper();
  bool _isEditing = false;

  final List<Color> _noteColors = [
    Colors.white,
    const Color(0xFFFFF9C4),
    const Color(0xFFFFCCBC),
    const Color(0xFFC8E6C9),
    const Color(0xFFB3E5FC),
    const Color(0xFFF8BBD0),
    const Color(0xFFE1BEE7),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (widget.item != null) {
      _titleController.text = widget.item!['title']?.toString() ?? "";
      _contentController.text = widget.item!['content']?.toString() ?? "";
      _imagePath = widget.item!['imagePath'];
      _isLocalCopy = widget.item!['isLocalCopy'] ?? 0;

      // Ако е нова бележка (напр. от споделяне) и имаме изображение, което още не е локално копие,
      // го маркираме за копиране при запис, за да гарантираме персистентност на ресурса.
      if (widget.item!['id'] == null && _imagePath != null && _isLocalCopy == 0) {
        _shouldCopyLocally = true;
      } else {
        _shouldCopyLocally = _isLocalCopy == 1;
      }
      
      // Зареждане на етикети
      if (widget.item!['tags'] != null && widget.item!['tags'].toString().isNotEmpty) {
        _selectedTags = widget.item!['tags'].toString().split(',').map((e) => e.trim()).toList();
      }

      if (widget.item!['reminderTime'] != null) {
        try {
          _reminderTime = DateTime.parse(widget.item!['reminderTime']);
        } catch (e) {
          debugPrint("Грешка при дата: $e");
        }
      }

      if (widget.item!['color'] != null) {
        _selectedColor = Color(widget.item!['color']);
      } else {
        await _loadDefaultColor();
      }

      _isEditing = widget.item!['id'] == null;
    } else {
      _isEditing = true;
      await _loadDefaultColor();
    }
    if (!_noteColors.contains(_selectedColor)) {
      _noteColors.add(_selectedColor);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadDefaultColor() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultColorVal = prefs.getInt('default_note_color');
    if (defaultColorVal != null) {
      setState(() {
        _selectedColor = Color(defaultColorVal);
      });
    }
    if (!_noteColors.contains(_selectedColor)) {
      _noteColors.add(_selectedColor);
    }
  }

  // Показва модален прозорец за управление на етикети
  void _showTagsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Управление на етикети", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  // Списък със съществуващи
                  if (widget.existingTags.isNotEmpty) ...[
                    const Text("Избери от съществуващи:", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: widget.existingTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              val ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                            });
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Добавяне на нов
                  const Text("Добави нов етикет:", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(hintText: "Име на етикет"),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setState(() {
                                if (!_selectedTags.contains(val.trim())) _selectedTags.add(val.trim());
                                _tagController.clear();
                              });
                              setModalState(() {});
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () {
                          if (_tagController.text.trim().isNotEmpty) {
                            setState(() {
                              String newTag = _tagController.text.trim();
                              if (!_selectedTags.contains(newTag)) _selectedTags.add(newTag);
                              _tagController.clear();
                            });
                            setModalState(() {});
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Готово"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<String?> _cropImage(String path) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Изрязване',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
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
          if (croppedPath != null) {
            // Ако е изрязано, използваме новия временен файл и го маркираме за локално записване
            _imagePath = croppedPath;
            _shouldCopyLocally = true;
          } else {
            // Ако изрязването е отказано, ползваме оригиналния път от галерията и НЕ копираме файла първоначално
            _imagePath = pickedFile.path;
            _shouldCopyLocally = false;
          }
          _isLocalCopy = 0;
        });
      }
    } catch (e) {
      debugPrint("Грешка галерия: $e");
    }
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
              _imagePath = copiedPath;
              _isLocalCopy = 1;
              _shouldCopyLocally = true;
              _sessionFileCreated = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Грешка камера: $e");
    }
  }

  Future<void> _editExistingImage() async {
    if (_imagePath == null) return;
    final croppedPath = await _cropImage(_imagePath!);
    if (croppedPath != null) {
      setState(() {
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
      final File originalFile = File(originalPath);
      await originalFile.copy(newPath);
      return newPath;
    } catch (e) {
      debugPrint("Грешка при копиране: $e");
    }
    return null;
  }

  Future<void> _pickReminderTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _reminderTime != null 
            ? TimeOfDay.fromDateTime(_reminderTime!) 
            : TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _reminderTime = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    String? finalPath = _imagePath;
    int finalIsLocal = _isLocalCopy;

    if (_imagePath != null && _shouldCopyLocally && _isLocalCopy == 0) {
      final String? copied = await _copyImageLocally(_imagePath!);
      if (copied != null) {
        finalPath = copied;
        finalIsLocal = 1;
      }
    }

    // Обединяваме избраните етикети в един стринг
    final String tagsString = _selectedTags.join(', ');

    final Map<String, dynamic> data = {
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'imagePath': finalPath,
      'reminderTime': _reminderTime?.toIso8601String(),
      'color': _selectedColor.toARGB32(),
      'isCompleted': widget.item?['isCompleted'] ?? 0,
      'isLocalCopy': finalIsLocal,
      'tags': tagsString, // Записване в БД
    };

    try {
      if (widget.item == null || widget.item!['id'] == null) {
        await dbHelper.insertItem(data);
      } else {
        data['id'] = widget.item!['id'];
        await dbHelper.updateItem(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Грешка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openFullScreenImage() {
    if (_imagePath == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(
          imagePath: _imagePath!,
          title: _titleController.text.isEmpty ? "Преглед" : _titleController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String reminderText = 'Напомняне';
    if (_reminderTime != null) {
      reminderText = '${_reminderTime!.day}.${_reminderTime!.month.toString().padLeft(2, '0')} ${_reminderTime!.hour}:${_reminderTime!.minute.toString().padLeft(2, '0')}';
    }

    return PopScope(
      canPop: false, // Предотвратява автоматичното излизане
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Ако не сме в режим на редактиране, излизаме веднага
        if (!_isEditing) {
          Navigator.of(context).pop();
          return;
        }

        // Показваме диалог за потвърждение
        final bool shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Отхвърляне на промените?'),
            content: const Text('Имате незапазени промени. Сигурни ли сте, че искате да излезете?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отказ')),
              TextButton(
                onPressed: () {
                  // Ако е създаден нов локален файл в тази сесия, но бележката се отхвърля - трием го
                  if (_sessionFileCreated && _imagePath != null && _isLocalCopy == 1) {
                    try {
                      File(_imagePath!).deleteSync();
                    } catch (e) {
                      debugPrint("Грешка при чистене на отхвърлен файл: $e");
                    }
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Отхвърли', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ?? false;

        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: _selectedColor,
      appBar: AppBar(
        backgroundColor: _selectedColor,
        elevation: 0,
        title: Text(_isEditing ? (widget.item?['id'] == null ? 'Нова бележка' : 'Редактиране') : 'Преглед'),
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true))
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Stack(
        children: [
          // Основно съдържание
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_imagePath != null)
                        GestureDetector(
                          onTap: _isEditing ? _editExistingImage : _openFullScreenImage,
                          child: Stack(
                            children: [
                              Container(
                                constraints: const BoxConstraints(maxHeight: 400),
                                width: double.infinity,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_imagePath!), 
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                          Text("Файлът не е намерен", style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_isEditing)
                                const Positioned(
                                  right: 8, bottom: 8,
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.crop, color: Colors.white, size: 20),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_isEditing)
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(hintText: 'Заглавие', border: InputBorder.none),
                        )
                      else if (_titleController.text.isNotEmpty)
                        Text(_titleController.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      
                      // Показване на етикетите
                      if (_selectedTags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 0,
                            children: _selectedTags.map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 12)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onDeleted: _isEditing ? () => setState(() => _selectedTags.remove(tag)) : null,
                            )).toList(),
                          ),
                        ),

                      const SizedBox(height: 12),
                      if (_isEditing)
                        TextField(
                          controller: _contentController,
                          maxLines: null,
                          style: const TextStyle(fontSize: 18),
                          decoration: const InputDecoration(hintText: 'Съдържание...', border: InputBorder.none),
                        )
                      else
                        Linkify(
                          text: _contentController.text,
                          onOpen: (link) async {
                            final url = Uri.parse(link.url);
                            if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                          style: const TextStyle(fontSize: 18),
                        ),
                      if (_isEditing && _imagePath != null && _isLocalCopy == 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: SwitchListTile(
                            title: const Text("Копирай в паметта на приложението", style: TextStyle(fontSize: 14)),
                            subtitle: const Text("Гарантира, че снимката няма да изчезне, ако бъде изтрита от галерията", style: TextStyle(fontSize: 11)),
                            value: _shouldCopyLocally,
                            onChanged: (val) => setState(() => _shouldCopyLocally = val),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_isEditing) _buildBottomTools(reminderText),
            ],
          ),

          // Плаващо меню (FlyMenu)
          FlyMenu(
            actions: [
              if (widget.item?['id'] != null) FlyAction(
                icon: Icons.delete, 
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await dbHelper.deleteItem(widget.item!['id']);
                  widget.onSaved();
                  if (mounted) navigator.pop();
                },
                label: "Изтрий"
              ),
              FlyAction(
                icon: Icons.arrow_back, 
                onTap: () => Navigator.pop(context),
                label: "Назад"
              ),
              if (_isEditing) FlyAction(
                icon: Icons.save, 
                onTap: _save,
                label: "Запази"
              ),
              if (!_isEditing) FlyAction(
                icon: Icons.edit, 
                onTap: () => setState(() => _isEditing = true),
                label: "Редактирай"
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTools(String reminderText) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8), 
        border: const Border(top: BorderSide(color: Colors.black12))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._noteColors.map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle,
                        border: Border.all(color: _selectedColor == color ? Colors.blue : Colors.black26, width: _selectedColor == color ? 2 : 1),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () async {
                    final picked = await showCustomColorPicker(context, _selectedColor);
                    if (picked != null) {
                      setState(() {
                        if (!_noteColors.contains(picked)) {
                          _noteColors.add(picked);
                        }
                        _selectedColor = picked;
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 30, height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                    ),
                    child: const Icon(Icons.colorize, size: 16, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),

          Row(
            children: [
              IconButton(icon: const Icon(Icons.photo_library), onPressed: _pickFromGallery, tooltip: 'Галерия'),
              IconButton(icon: const Icon(Icons.camera_alt), onPressed: _pickFromCamera, tooltip: 'Камера'),
              IconButton(icon: const Icon(Icons.label_outline), onPressed: _showTagsSheet, tooltip: 'Етикети'),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickReminderTime,
                icon: const Icon(Icons.alarm),
                label: Text(reminderText),
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
      body: Center(child: InteractiveViewer(child: Image.file(
        File(imagePath), 
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.white24),
      ))),
    );
  }
}
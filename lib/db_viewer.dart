import 'package:flutter/material.dart';
import 'dart:io';
import 'db_helper.dart';

class DbViewerScreen extends StatefulWidget {
  const DbViewerScreen({super.key});

  @override
  State<DbViewerScreen> createState() => _DbViewerScreenState();
}

class _DbViewerScreenState extends State<DbViewerScreen> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _records = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final data = await dbHelper.queryAllRows();
    setState(() {
      _records = data;
      _isLoading = false;
    });
  }

  void _next() {
    if (_currentIndex < _records.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контрол на БД'),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () async {
                final record = _records[_currentIndex];
                final int id = record['id'];
                final String? imagePath = record['imagePath'];
                final bool isLocal = record['isLocalCopy'] == 1;


                String contentText = 'Сигурни ли сте, че искате да изтриете този запис?';
                if (isLocal && imagePath != null) {
                  contentText += '\n\nВнимание: Локалното копие на файла (${imagePath.split('/').last}) също ще бъде изтрито от паметта на приложението.';
                }
                final bool confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Потвърждение'),
                    content: Text(contentText),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отказ')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Изтрий', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ) ?? false;

                if (confirm) {
                  // 1. Първо изтриваме физическия файл, ако е локален
                  if (isLocal && imagePath != null) {
                    try {
                      final file = File(imagePath);
                      if (await file.exists()) await file.delete();
                    } catch (e) {
                      debugPrint("Грешка при изтриване на файл: $e");
                    }
                  }

                  // 2. Изтриваме записа от базата данни
                  await dbHelper.deleteItem(id);
                  await _loadRecords();
                  
                  // Коригираме индекса, ако сме изтрили последния елемент
                  if (_currentIndex >= _records.length && _currentIndex > 0) {
                    setState(() => _currentIndex = _records.length - 1);
                  }
                }
              },
              tooltip: 'Изтрий записа от БД',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('Базата данни е празна.'))
              : GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity == null) return;
                    if (details.primaryVelocity! > 100) {
                      _prev();
                    } else if (details.primaryVelocity! < -100) {
                      _next();
                    }
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Запис ${_currentIndex + 1} от ${_records.length}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_records[_currentIndex]['imagePath'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.file(
                                  File(_records[_currentIndex]['imagePath']),
                                  errorBuilder: (context, error, stackTrace) => const Center(child: Text("Файлът не е намерен")),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: _records[_currentIndex].entries.map((e) {
                            return Card(
                              child: ListTile(
                                title: Text(e.key, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                subtitle: Text(e.value?.toString() ?? 'null', style: const TextStyle(fontSize: 16)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _currentIndex > 0 ? _prev : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Предишен'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _currentIndex < _records.length - 1 ? _next : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Следващ'),
                            iconAlignment: IconAlignment.end,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalFilesViewerScreen extends StatefulWidget {
  const LocalFilesViewerScreen({super.key});

  @override
  State<LocalFilesViewerScreen> createState() => _LocalFilesViewerScreenState();
}

class _LocalFilesViewerScreenState extends State<LocalFilesViewerScreen> {
  List<File> _files = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scanFiles();
  }

  Future<void> _scanFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> entities = directory.listSync();
    
    // Филтрираме само файлове, които са изображения (img_...)
    final List<File> imageFiles = entities
        .whereType<File>()
        .where((file) => file.path.contains('img_'))
        .toList();

    setState(() {
      _files = imageFiles;
      _isLoading = false;
    });
  }

  Future<void> _deleteCurrentFile() async {
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изтриване на файл'),
        content: const Text('Сигурни ли сте? Това ще изтрие физическия файл от паметта. Ако той е свързан с бележка, тя вече няма да го показва.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отказ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Изтрий', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _files[_currentIndex].delete();
      _scanFiles();
      if (_currentIndex > 0) setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Файлове в паметта'),
        actions: [
          if (_files.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteCurrentFile),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(child: Text('Няма локални файлове.'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Файл ${_currentIndex + 1} от ${_files.length}\n${_files[_currentIndex].path.split('/').last}'),
                    ),
                    Expanded(
                      child: InteractiveViewer(
                        child: Image.file(_files[_currentIndex]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                          child: const Text('Предишен'),
                        ),
                        ElevatedButton(
                          onPressed: _currentIndex < _files.length - 1 ? () => setState(() => _currentIndex++) : null,
                          child: const Text('Следващ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }
}
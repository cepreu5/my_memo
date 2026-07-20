import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'l10n/app_localizations.dart';

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
        .where((file) => file.path.contains('img_') || file.path.contains('vid_thumb_')) // Включваме и миниатюри на видео
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
        title: Text(AppLocalizations.of(context)!.deleteFileTitle),
        content: Text(AppLocalizations.of(context)!.deleteFileConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red))),
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
        title: Text(AppLocalizations.of(context)!.filesInMemory),
        actions: [
          if (_files.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteCurrentFile),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(child: Text(AppLocalizations.of(context)!.noLocalFiles))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FutureBuilder<int>(
                        future: _files[_currentIndex].length(),
                        builder: (context, snapshot) {
                          final size = snapshot.hasData 
                              ? '${(snapshot.data! / 1024).toStringAsFixed(2)} KB' 
                              : '...';
                          return Text(AppLocalizations.of(context)!.fileInfo(_currentIndex + 1, _files.length, _files[_currentIndex].path.split('/').last, size));
                        },
                      ),
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
                          child: Text(AppLocalizations.of(context)!.previous),
                        ),
                        ElevatedButton(
                          onPressed: _currentIndex < _files.length - 1 ? () => setState(() => _currentIndex++) : null,
                          child: Text(AppLocalizations.of(context)!.next),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }
}

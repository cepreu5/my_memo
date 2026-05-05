import 'package:flutter/material.dart';
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
                final id = _records[_currentIndex]['id'];
                await dbHelper.deleteItem(id);
                _loadRecords();
                if (_currentIndex > 0) {
                  setState(() => _currentIndex--);
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Запис ${_currentIndex + 1} от ${_records.length}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    );
  }
}
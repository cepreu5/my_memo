import 'dart:async';
import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'business_organizer.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        imagePath TEXT,
        creationTime TEXT,
        color INTEGER,
        isCompleted INTEGER DEFAULT 0,
        isLocalCopy INTEGER DEFAULT 0,
        tags TEXT,
        uuid TEXT,
        updatedAt TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("UPDATE notes SET imagePath = videoThumbnailPath WHERE imagePath IS NULL AND videoThumbnailPath IS NOT NULL");
      await db.execute('CREATE TABLE notes_new (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, imagePath TEXT, reminderTime TEXT, color INTEGER, isCompleted INTEGER DEFAULT 0, isLocalCopy INTEGER DEFAULT 0, tags TEXT)');
      await db.execute('INSERT INTO notes_new (id, title, content, imagePath, reminderTime, color, isCompleted, isLocalCopy, tags) SELECT id, title, content, imagePath, reminderTime, color, isCompleted, isLocalCopy, tags FROM notes');
      await db.execute('DROP TABLE notes');
      await db.execute('ALTER TABLE notes_new RENAME TO notes');
    }
    if (oldVersion < 3) {
      final tableInfo = await db.rawQuery('PRAGMA table_info(notes)');
      final columnNames = tableInfo.map((e) => e['name'] as String).toList();
      if (!columnNames.contains('uuid')) {
        await db.execute('ALTER TABLE notes ADD COLUMN uuid TEXT');
      }
      if (!columnNames.contains('updatedAt')) {
        await db.execute('ALTER TABLE notes ADD COLUMN updatedAt TEXT');
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE notes RENAME COLUMN reminderTime TO creationTime');
      } catch (e) {
        debugPrint("Грешка при преименуване на reminderTime: $e");
      }
    }
  }

  // Вмъкване на запис
  Future<int> insertItem(Map<String, dynamic> row) async {
    final db = await database;
    final map = Map<String, dynamic>.from(row);
    if (map['uuid'] == null) {
      map['uuid'] = '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
    }
    map['updatedAt'] = DateTime.now().toIso8601String();
    return await db.insert('notes', map);
  }

  // Извличане на всички записи с авто-генериране на UUID за стари бележки
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes', orderBy: "id DESC");
    final List<Map<String, dynamic>> updatedMaps = [];
    final random = Random();
    for (var map in maps) {
      if (map['uuid'] == null) {
        final updatedMap = Map<String, dynamic>.from(map);
        updatedMap['uuid'] = '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(999999)}';
        updatedMap['updatedAt'] = DateTime.now().toIso8601String();
        await db.update('notes', updatedMap, where: 'id = ?', whereArgs: [map['id']]);
        updatedMaps.add(updatedMap);
      } else {
        updatedMaps.add(map);
      }
    }
    return updatedMaps;
  }

  // Обновяване на запис с проверка за ID
  Future<int> updateItem(Map<String, dynamic> row) async {
    final db = await database;
    int? id = row['id'];
    if (id == null) {
      debugPrint("Опит за обновяване без ID!");
      return 0;
    }
    final map = Map<String, dynamic>.from(row);
    if (map['uuid'] == null) {
      map['uuid'] = '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
    }
    map['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update('notes', map, where: 'id = ?', whereArgs: [id]);
  }

  // Изтриване на запис
  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isImagePathUsed(String path, int excludingId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('notes', where: 'imagePath = ? AND id != ?', whereArgs: [path, excludingId]);
    return result.isNotEmpty;
  }
}
// Future<List<Map<String, dynamic>>> getItems() async {
//   final db = await instance.database;
//   // Връщаме всички редове от таблица 'items'
//   return await db.query('items'); 
// }
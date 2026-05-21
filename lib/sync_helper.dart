import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'db_helper.dart';

class SyncHelper {
  static final SyncHelper _instance = SyncHelper._internal();
  factory SyncHelper() => _instance;
  SyncHelper._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );
  final DatabaseHelper _dbHelper = DatabaseHelper();
  StreamSubscription<QuerySnapshot>? _notesSubscription;
  // Защита срещу повторно вмъкване на изтрити бележки
  final Set<String> _pendingDeletes = {};
  bool _isSyncingImages = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  void startRealtimeSync(VoidCallback onUpdated) {
    final user = currentUser;
    if (user == null) return;
    _notesSubscription?.cancel();
    _notesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.metadata.hasPendingWrites) return;
      await syncNotes();
      onUpdated();
      syncPendingImages(onImageDownloaded: onUpdated);
    });
  }

  void stopRealtimeSync() {
    _notesSubscription?.cancel();
    _notesSubscription = null;
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint("Грешка при Google вход: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Грешка при изход: $e");
    }
  }

  Future<void> deleteNoteRemote(String uuid) async {
    final user = currentUser;
    if (user == null) return;
    _pendingDeletes.add(uuid);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notes').doc(uuid).delete();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('deleted_notes').doc(uuid).set({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Грешка при изтриване remote: $e");
    } finally {
      // Махаме след кратко забавяне, за да не го хване snapshot listener-ът
      Future.delayed(const Duration(seconds: 3), () => _pendingDeletes.remove(uuid));
    }
  }

  Future<String?> syncNotes() async {
    final user = currentUser;
    if (user == null) return "Няма влязъл потребител.";
    try {
      final firestoreRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notes');
      final deletedRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('deleted_notes');
      final deletedSnapshot = await deletedRef.get();
      final deletedUuids = {for (var doc in deletedSnapshot.docs) doc.id};
      final localNotes = await _dbHelper.queryAllRows();
      for (var local in localNotes) {
        final uuid = local['uuid'] as String?;
        if (uuid != null && deletedUuids.contains(uuid)) {
          if (local['isLocalCopy'] == 1 && local['imagePath'] != null) {
            try {
              final f = File(local['imagePath']);
              if (await f.exists()) await f.delete();
            } catch (e) {
              debugPrint("Грешка при изтриване на файл на изтрита бележка: $e");
            }
          }
          await _dbHelper.deleteItem(local['id']);
        }
      }
      final activeLocalNotes = await _dbHelper.queryAllRows();
      final remoteSnapshot = await firestoreRef.get();
      final remoteNotes = {for (var doc in remoteSnapshot.docs) doc.id: doc.data()};
      for (var local in activeLocalNotes) {
        final uuid = local['uuid'] as String;
        if (_pendingDeletes.contains(uuid) || deletedUuids.contains(uuid)) continue;
        final localUpdatedStr = local['updatedAt'] as String? ?? '';
        final localUpdated = DateTime.tryParse(localUpdatedStr) ?? DateTime(2000);
        final remote = remoteNotes[uuid];
        if (remote == null) {
          final toUpload = Map<String, dynamic>.from(local)..remove('id');
          await firestoreRef.doc(uuid).set(toUpload);
        } else {
          final remoteUpdatedStr = remote['updatedAt'] as String? ?? '';
          final remoteUpdated = DateTime.tryParse(remoteUpdatedStr) ?? DateTime(2000);
          if (localUpdated.isAfter(remoteUpdated)) {
            final toUpload = Map<String, dynamic>.from(local)..remove('id');
            await firestoreRef.doc(uuid).set(toUpload);
          } else if (remoteUpdated.isAfter(localUpdated)) {
            final toUpdate = Map<String, dynamic>.from(remote);
            toUpdate['id'] = local['id'];
            toUpdate['uuid'] = uuid;
            await _dbHelper.updateItem(toUpdate);
          }
        }
      }
      for (var entry in remoteNotes.entries) {
        final uuid = entry.key;
        if (_pendingDeletes.contains(uuid) || deletedUuids.contains(uuid)) continue;
        final remote = entry.value;
        final existsLocally = activeLocalNotes.any((l) => l['uuid'] == uuid);
        if (!existsLocally) {
          final toInsert = Map<String, dynamic>.from(remote)..remove('id');
          toInsert['uuid'] = uuid;
          await _dbHelper.insertItem(toInsert);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Грешка при синхронизация: $e");
      return e.toString();
    }
  }

  /// Синхронизира фоново локални и липсващи снимки с Google Drive.
  Future<void> syncPendingImages({VoidCallback? onImageDownloaded}) async {
    if (_isSyncingImages) return;
    _isSyncingImages = true;
    final user = currentUser;
    if (user == null) {
      _isSyncingImages = false;
      return;
    }
    try {
      final localNotes = await _dbHelper.queryAllRows();
      final appDir = await getApplicationDocumentsDirectory();
      for (var note in localNotes) {
        if (note['isLocalCopy'] == 1 && note['imagePath'] != null) {
          final fileName = p.basename(note['imagePath']);
          final localExpectedPath = p.join(appDir.path, fileName);
          if (!File(localExpectedPath).existsSync()) {
            await downloadSingleImageFromDrive(fileName, localExpectedPath);
            if (File(localExpectedPath).existsSync()) {
              final updatedNote = Map<String, dynamic>.from(note);
              updatedNote['imagePath'] = localExpectedPath;
              await _dbHelper.updateItem(updatedNote);
              onImageDownloaded?.call();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Грешка при фонова синхронизация на снимки: $e");
    } finally {
      _isSyncingImages = false;
    }
  }
  Future<bool> checkImageExistsOnDrive(String originalFileName) async {
    final googleUser = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (googleUser == null) return false;
    final token = (await googleUser.authentication).accessToken;
    if (token == null) return false;
    final syncName = 'MyMemoSync_$originalFileName';
    try {
      final query = "name='$syncName' and trashed=false";
      final searchRes = await http.get(
        Uri.parse("https://www.googleapis.com/drive/v3/files?q=${Uri.encodeComponent(query)}"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (searchRes.statusCode == 200) {
        final data = jsonDecode(searchRes.body);
        final files = data['files'] as List;
        return files.isNotEmpty;
      }
    } catch (e) {
      debugPrint("Грешка при проверка за снимка в Drive: $e");
    }
    return false;
  }

  Future<String?> backupImagesToGoogleDrive() async {
    final user = currentUser;
    if (user == null) return "Няма влязъл потребител.";
    final googleUser = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (googleUser == null) return "Моля, влезте в профила си.";
    final auth = await googleUser.authentication;
    final token = auth.accessToken;
    if (token == null) return "Не може да се вземе тоукън за достъп.";
    try {
      final localNotes = await _dbHelper.queryAllRows();
      final appDir = await getApplicationDocumentsDirectory();
      final zipPath = p.join(appDir.path, 'MyMemo_Images_Backup.zip');
      final archive = Archive();
      final Set<String> addedFiles = {};
      int count = 0;
      for (var local in localNotes) {
        if (local['isLocalCopy'] == 1 && local['imagePath'] != null) {
          final file = File(local['imagePath'] as String);
          final baseName = p.basename(file.path);
          if (file.existsSync() && !addedFiles.contains(baseName)) {
            final bytes = file.readAsBytesSync();
            archive.addFile(ArchiveFile(baseName, bytes.length, bytes));
            addedFiles.add(baseName);
            count++;
          }
        }
      }
      if (count == 0) return "Няма локални снимки за архивиране.";
      final zipData = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipData);
      // Изтриваме стария бекъп от Drive
      final searchRes = await http.get(
        Uri.parse("https://www.googleapis.com/drive/v3/files?q=name='MyMemo_Images_Backup.zip' and trashed=false"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (searchRes.statusCode == 200) {
        final data = jsonDecode(searchRes.body);
        final files = data['files'] as List;
        for (var f in files) {
          await http.delete(
            Uri.parse("https://www.googleapis.com/drive/v3/files/${f['id']}"),
            headers: {'Authorization': 'Bearer $token'},
          );
        }
      }
      // Качваме: простo upload + PATCH за името
      final uploadRes = await _simpleUploadToDrive(token, File(zipPath).readAsBytesSync(), 'application/zip');
      if (File(zipPath).existsSync()) File(zipPath).deleteSync();
      if (uploadRes == null) return "Грешка при качване.";
      await _patchFileName(token, uploadRes, 'MyMemo_Images_Backup.zip');
      return "Успешно запазени $count снимки в Google Drive.";
    } catch (e) {
      debugPrint("Грешка при бекъп: $e");
      return "Грешка: $e";
    }
  }

  Future<String?> restoreImagesFromGoogleDrive() async {
    final user = currentUser;
    if (user == null) return "Няма влязъл потребител.";
    final googleUser = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (googleUser == null) return "Моля, влезте в профила си.";
    final auth = await googleUser.authentication;
    final token = auth.accessToken;
    if (token == null) return "Не може да се вземе тоукън за достъп.";
    final appDir = await getApplicationDocumentsDirectory();
    final zipPath = p.join(appDir.path, 'MyMemo_Images_Downloaded.zip');
    final zipFile = File(zipPath);
    try {
      final searchRes = await http.get(
        Uri.parse("https://www.googleapis.com/drive/v3/files?q=name='MyMemo_Images_Backup.zip' and trashed=false"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (searchRes.statusCode != 200) return "Грешка при търсене в Drive.";
      final data = jsonDecode(searchRes.body);
      final files = data['files'] as List;
      if (files.isEmpty) return "Не е намерен архив със снимки в Google Drive.";
      final fileId = files[0]['id'];
      final zipBytes = await _downloadFileBytes(token, fileId);
      if (zipBytes == null) return "Грешка при изтегляне.";
      await zipFile.writeAsBytes(zipBytes);
      final archive = ZipDecoder().decodeBytes(zipBytes);
      int count = 0;
      final localNotes = await _dbHelper.queryAllRows();
      for (final file in archive) {
        if (file.isFile) {
          final fileData = file.content as List<int>;
          final fileName = p.basename(file.name);
          final localFile = File(p.join(appDir.path, fileName));
          await localFile.writeAsBytes(fileData);
          bool matched = false;
          for (var note in localNotes) {
            if (note['imagePath'] != null && p.basename(note['imagePath']) == fileName) {
              final updatedNote = Map<String, dynamic>.from(note);
              updatedNote['imagePath'] = localFile.path;
              updatedNote['isLocalCopy'] = 1;
              await _dbHelper.updateItem(updatedNote);
              matched = true;
            }
          }
          if (matched) count++;
        }
      }
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      return "Успешно заредени $count снимки от Google Drive.";
    } catch (e) {
      debugPrint("Грешка при възстановяване: $e");
      return "Грешка: $e";
    } finally {
      if (zipFile.existsSync()) {
        try {
          zipFile.deleteSync();
        } catch (err) {
          debugPrint("Грешка при триене на zip: $err");
        }
      }
    }
  }

  /// Качва сурови байтове с simple upload (без multipart, без корупция).
  /// Връща fileId или null при грешка.
  Future<String?> _simpleUploadToDrive(String token, Uint8List fileBytes, String mimeType) async {
    try {
      final response = await http.post(
        Uri.parse("https://www.googleapis.com/upload/drive/v3/files?uploadType=media"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': mimeType,
        },
        body: fileBytes,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['id'] as String?;
      }
      debugPrint("Upload грешка: ${response.statusCode} ${response.body}");
    } catch (e) {
      debugPrint("Upload error: $e");
    }
    return null;
  }

  /// Преименува файл в Drive.
  Future<void> _patchFileName(String token, String fileId, String name) async {
    await http.patch(
      Uri.parse("https://www.googleapis.com/drive/v3/files/$fileId"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );
  }

  /// Изтегля файл от Drive като сурови байтове.
  Future<Uint8List?> _downloadFileBytes(String token, String fileId) async {
    try {
      final response = await http.get(
        Uri.parse("https://www.googleapis.com/drive/v3/files/$fileId?alt=media"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      debugPrint("Download грешка: ${response.statusCode} ${response.body}");
    } catch (e) {
      debugPrint("Download error: $e");
    }
    return null;
  }

  Future<void> uploadSingleImageToDrive(String localPath) async {
    final googleUser = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (googleUser == null) return;
    final token = (await googleUser.authentication).accessToken;
    if (token == null) return;
    final file = File(localPath);
    if (!file.existsSync()) return;
    final ext = p.extension(localPath).toLowerCase();
    final mimeType = ext == '.png' ? 'image/png' : (ext == '.webp' ? 'image/webp' : 'image/jpeg');
    try {
      final fileId = await _simpleUploadToDrive(token, file.readAsBytesSync(), mimeType);
      if (fileId != null) {
        await _patchFileName(token, fileId, 'MyMemoSync_${p.basename(localPath)}');
      }
    } catch (e) {
      debugPrint("Грешка при фоново качване на снимка: $e");
    }
  }

  Future<void> downloadSingleImageFromDrive(String originalFileName, String savePath) async {
    final googleUser = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (googleUser == null) return;
    final token = (await googleUser.authentication).accessToken;
    if (token == null) return;
    final syncName = 'MyMemoSync_$originalFileName';
    try {
      final query = "name='$syncName' and trashed=false";
      final searchRes = await http.get(
        Uri.parse("https://www.googleapis.com/drive/v3/files?q=${Uri.encodeComponent(query)}"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (searchRes.statusCode != 200) return;
      final data = jsonDecode(searchRes.body);
      final files = data['files'] as List;
      if (files.isEmpty) return;
      final fileId = files[0]['id'];
      final bytes = await _downloadFileBytes(token, fileId);
      if (bytes != null) {
        await File(savePath).writeAsBytes(bytes);
      }
    } catch (e) {
      debugPrint("Грешка при фоново изтегляне на снимка: $e");
    }
  }
  /// Локален бекъп на бележките и снимките в ZIP архив в Downloads папката.
  Future<String?> backupNotesLocally() async {
    try {
      final localNotes = await _dbHelper.queryAllRows();
      if (localNotes.isEmpty) return "Няма бележки за архивиране.";
      final archive = Archive();
      // Добавяме бележките като JSON
      final notesJson = jsonEncode(localNotes);
      final notesBytes = utf8.encode(notesJson);
      archive.addFile(ArchiveFile('notes.json', notesBytes.length, notesBytes));
      // Добавяме снимките
      final Set<String> addedFiles = {};
      int imageCount = 0;
      for (var note in localNotes) {
        if (note['isLocalCopy'] == 1 && note['imagePath'] != null) {
          final file = File(note['imagePath'] as String);
          final baseName = p.basename(file.path);
          if (file.existsSync() && !addedFiles.contains(baseName)) {
            final bytes = file.readAsBytesSync();
            archive.addFile(ArchiveFile('images/$baseName', bytes.length, bytes));
            addedFiles.add(baseName);
            imageCount++;
          }
        }
      }
      final zipData = ZipEncoder().encode(archive);
      // Записваме в Downloads
      final downloadDir = Directory('/storage/emulated/0/Download');
      final zipPath = p.join(downloadDir.path, 'MyMemo_Notes_Backup.zip');
      File(zipPath).writeAsBytesSync(zipData);
      return "Архивирани ${localNotes.length} бележки и $imageCount снимки.\nФайл: $zipPath";
    } catch (e) {
      debugPrint("Грешка при локален бекъп: $e");
      return "Грешка: $e";
    }
  }
  /// Възстановяване на бележки и снимки от локален ZIP архив.
  Future<String?> restoreNotesLocally(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      if (!zipFile.existsSync()) return "Файлът не е намерен.";
      final zipBytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      // Търсим notes.json
      final notesFile = archive.files.where((f) => f.name == 'notes.json').firstOrNull;
      if (notesFile == null) return "Архивът не съдържа notes.json.";
      final notesJson = utf8.decode(notesFile.content as List<int>);
      final List<dynamic> notesData = jsonDecode(notesJson);
      if (notesData.isEmpty) return "Архивът не съдържа бележки.";
      final appDir = await getApplicationDocumentsDirectory();
      // Извличаме снимките
      int imageCount = 0;
      for (final file in archive.files) {
        if (file.isFile && file.name.startsWith('images/')) {
          final fileName = p.basename(file.name);
          final localFile = File(p.join(appDir.path, fileName));
          await localFile.writeAsBytes(file.content as List<int>);
          imageCount++;
        }
      }
      // Импортираме бележките
      final existingNotes = await _dbHelper.queryAllRows();
      final existingByUuid = <String, Map<String, dynamic>>{};
      for (var n in existingNotes) {
        if (n['uuid'] != null) existingByUuid[n['uuid']] = n;
      }
      int inserted = 0;
      int updated = 0;
      int skipped = 0;
      for (var noteData in notesData) {
        final note = Map<String, dynamic>.from(noteData);
        final uuid = note['uuid'] as String?;
        // Обновяваме imagePath да сочи към локалната директория
        if (note['isLocalCopy'] == 1 && note['imagePath'] != null) {
          final imgBaseName = p.basename(note['imagePath'] as String);
          note['imagePath'] = p.join(appDir.path, imgBaseName);
        }
        if (uuid != null && existingByUuid.containsKey(uuid)) {
          // Сравняваме по updatedAt — по-новата печели
          final existing = existingByUuid[uuid]!;
          final existingUpdated = DateTime.tryParse(existing['updatedAt'] ?? '') ?? DateTime(2000);
          final importUpdated = DateTime.tryParse(note['updatedAt'] ?? '') ?? DateTime(2000);
          if (importUpdated.isAfter(existingUpdated)) {
            note['id'] = existing['id'];
            await _dbHelper.updateItem(note);
            updated++;
          } else {
            skipped++;
          }
        } else {
          note.remove('id');
          await _dbHelper.insertItem(note);
          inserted++;
        }
      }
      return "Нови: $inserted, обновени: $updated, пропуснати: $skipped.\nСнимки: $imageCount";
    } catch (e) {
      debugPrint("Грешка при възстановяване: $e");
      return "Грешка: $e";
    }
  }
}

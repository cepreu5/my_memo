import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:archive/archive_io.dart';
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
      // Игнорираме локални промени (тези, които устройството само е пратило към Firestore)
      if (snapshot.metadata.hasPendingWrites) return;
      
      // Има нова/обновена бележка от друго устройство (сървърът е пратил данни)
      await syncNotes();
      onUpdated();
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
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notes').doc(uuid).delete();
    } catch (e) {
      debugPrint("Грешка при изтриване remote: $e");
    }
  }

  Future<String?> syncNotes() async {
    final user = currentUser;
    if (user == null) return "Няма влязъл потребител.";
    try {
      final localNotes = await _dbHelper.queryAllRows();
      final firestoreRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notes');
      final remoteSnapshot = await firestoreRef.get();
      final remoteNotes = {for (var doc in remoteSnapshot.docs) doc.id: doc.data()};
      for (var local in localNotes) {
        final uuid = local['uuid'] as String;
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
            await _dbHelper.updateItem(toUpdate);
          }
        }
      }
      for (var entry in remoteNotes.entries) {
        final uuid = entry.key;
        final remote = entry.value;
        final existsLocally = localNotes.any((l) => l['uuid'] == uuid);
        if (!existsLocally) {
          final toInsert = Map<String, dynamic>.from(remote)..remove('id');
          await _dbHelper.insertItem(toInsert);
        }
        
        if (remote['isLocalCopy'] == 1 && remote['imagePath'] != null) {
          final fileName = p.basename(remote['imagePath']);
          final appDir = await getApplicationDocumentsDirectory();
          final localExpectedPath = p.join(appDir.path, fileName);
          if (!File(localExpectedPath).existsSync()) {
            await downloadSingleImageFromDrive(fileName, localExpectedPath);
            final updatedLocal = await _dbHelper.queryAllRows();
            final noteToUpdate = updatedLocal.firstWhere((n) => n['uuid'] == uuid, orElse: () => {});
            if (noteToUpdate.isNotEmpty) {
              final newNote = Map<String, dynamic>.from(noteToUpdate);
              newNote['imagePath'] = localExpectedPath;
              await _dbHelper.updateItem(newNote);
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint("Грешка при синхронизация: $e");
      return e.toString();
    }
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
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      
      int count = 0;
      for (var local in localNotes) {
        if (local['isLocalCopy'] == 1 && local['imagePath'] != null) {
          final path = local['imagePath'] as String;
          final file = File(path);
          if (file.existsSync()) {
            encoder.addFile(file, p.basename(file.path));
            count++;
          }
        }
      }
      encoder.close();
      
      if (count == 0) {
        if (File(zipPath).existsSync()) File(zipPath).deleteSync();
        return "Няма локални снимки за архивиране.";
      }

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

      const boundary = '----DriveUploadBoundary';
      const header = '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'
          '{"name": "MyMemo_Images_Backup.zip"}\r\n'
          '--$boundary\r\nContent-Type: application/zip\r\n\r\n';
      const footer = '\r\n--$boundary--\r\n';
      
      final headerBytes = utf8.encode(header);
      final footerBytes = utf8.encode(footer);
      final fileBytes = File(zipPath).readAsBytesSync();
      final bodyBytes = [...headerBytes, ...fileBytes, ...footerBytes];
      
      final response = await http.post(
        Uri.parse("https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/related; boundary=$boundary',
          'Content-Length': bodyBytes.length.toString(),
        },
        body: bodyBytes,
      );
      
      if (File(zipPath).existsSync()) File(zipPath).deleteSync();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return "Успешно запазени $count снимки в Google Drive.";
      } else {
        return "Грешка при запазване: ${response.statusCode}";
      }
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
      final appDir = await getApplicationDocumentsDirectory();
      final zipPath = p.join(appDir.path, 'MyMemo_Images_Downloaded.zip');
      
      final downloadRes = await http.get(
        Uri.parse("https://www.googleapis.com/drive/v3/files/$fileId?alt=media"),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (downloadRes.statusCode != 200) return "Грешка при изтегляне.";
      
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(downloadRes.bodyBytes);
      
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      int count = 0;
      final localNotes = await _dbHelper.queryAllRows();
      
      for (final file in archive) {
        if (file.isFile) {
          final fileData = file.content as List<int>;
          final fileName = p.basename(file.name); // Осигуряваме, че е само името
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
      
      if (zipFile.existsSync()) zipFile.deleteSync();
      return "Успешно заредени $count снимки от Google Drive.";
    } catch (e) {
      debugPrint("Грешка при възстановяване: $e");
      return "Грешка: $e";
    }
  }

  Future<void> uploadSingleImageToDrive(String localPath) async {
    final googleUser = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (googleUser == null) return;
    final token = (await googleUser.authentication).accessToken;
    if (token == null) return;

    final fileName = 'MyMemoSync_${p.basename(localPath)}';
    
    const boundary = '----DriveUploadBoundary';
    final header = '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'
        '{"name": "$fileName"}\r\n'
        '--$boundary\r\nContent-Type: image/jpeg\r\n\r\n';
    const footer = '\r\n--$boundary--\r\n';
    
    final headerBytes = utf8.encode(header);
    final footerBytes = utf8.encode(footer);
    final file = File(localPath);
    if (!file.existsSync()) return;
    
    final fileBytes = file.readAsBytesSync();
    final bodyBytes = [...headerBytes, ...fileBytes, ...footerBytes];
    
    try {
      await http.post(
        Uri.parse("https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/related; boundary=$boundary',
          'Content-Length': bodyBytes.length.toString(),
        },
        body: bodyBytes,
      );
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
      final searchRes = await http.get(
        Uri.parse("https://www.googleapis.com/drive/v3/files?q=name='$syncName' and trashed=false"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (searchRes.statusCode != 200) return;
      final data = jsonDecode(searchRes.body);
      final files = data['files'] as List;
      if (files.isEmpty) return; // Няма я в облака

      final fileId = files[0]['id'];
      final downloadRes = await http.get(
        Uri.parse("https://www.googleapis.com/drive/v3/files/$fileId?alt=media"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (downloadRes.statusCode == 200) {
        await File(savePath).writeAsBytes(downloadRes.bodyBytes);
        
        // Изтриваме я от облака, защото вече е преминала (pass-through)
        await http.delete(
          Uri.parse("https://www.googleapis.com/drive/v3/files/$fileId"),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } catch (e) {
      debugPrint("Грешка при фоново изтегляне на снимка: $e");
    }
  }
}

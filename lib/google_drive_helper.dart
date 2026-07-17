import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'db_helper.dart';

class GoogleDriveHelper {
  static const String _appFolderName = 'MyMemo';
  static const String _backupSubfolder = 'backups';
  static const String _dbFileName = 'business_organizer.db';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;
  DatabaseHelper? _dbHelper;

  DatabaseHelper get _db => _dbHelper ??= DatabaseHelper();

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<String?> getSignedInEmail() async {
    _currentUser = _googleSignIn.currentUser;
    if (_currentUser == null) {
      _currentUser = await _googleSignIn.signInSilently();
    }
    return _currentUser?.email;
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    if (_currentUser == null) {
      final signed = await signIn();
      if (!signed || _currentUser == null) return null;
    }
    final authHeaders = await _currentUser!.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  Future<String?> _findOrCreateFolder(drive.DriveApi api, String name, {String? parentId}) async {
    String query = "mimeType = 'application/vnd.google-apps.folder' and name = '$name' and trashed = false";
    if (parentId != null) query += " and '$parentId' in parents";
    final result = await api.files.list(q: query, $fields: 'files(id, name)');
    if (result.files != null && result.files!.isNotEmpty) return result.files!.first.id;

    final folder = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = parentId != null ? [parentId] : null;
    final created = await api.files.create(folder, $fields: 'id');
    return created.id;
  }

  Future<int> findOrphanedImages() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.parent.path, 'databases', _dbFileName);
      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) return 0;

      final notes = await _db.queryAllRows();
      final referencedPaths = <String>{};
      for (final note in notes) {
        final path = note['imagePath']?.toString();
        if (path != null && path.isNotEmpty) referencedPaths.add(path);
      }

      int orphanCount = 0;
      if (dir.existsSync()) {
        for (final entity in dir.listSync()) {
          if (entity is File) {
            final fileName = p.basename(entity.path);
            if (fileName.startsWith('img_') && !referencedPaths.contains(entity.path)) {
              orphanCount++;
            }
          }
        }
      }
      return orphanCount;
    } catch (e) {
      return 0;
    }
  }

  Future<void> deleteOrphanedImages() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final notes = await _db.queryAllRows();
      final referencedPaths = <String>{};
      for (final note in notes) {
        final path = note['imagePath']?.toString();
        if (path != null && path.isNotEmpty) referencedPaths.add(path);
      }
      if (dir.existsSync()) {
        for (final entity in dir.listSync()) {
          if (entity is File) {
            final fileName = p.basename(entity.path);
            if (fileName.startsWith('img_') && !referencedPaths.contains(entity.path)) {
              try { await entity.delete(); } catch (e) {}
            }
          }
        }
      }
    } catch (e) {}
  }

  Future<File> _createBackupZip() async {
    final archive = Archive();
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.parent.path, 'databases', _dbFileName);
    final dbFile = File(dbPath);
    if (dbFile.existsSync()) {
      final bytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile(_dbFileName, bytes.length, bytes));
    }

    final notes = await _db.queryAllRows();
    for (final note in notes) {
      final imagePath = note['imagePath']?.toString();
      if (imagePath != null && imagePath.isNotEmpty) {
        final imgFile = File(imagePath);
        if (await imgFile.exists()) {
          final bytes = await imgFile.readAsBytes();
          archive.addFile(ArchiveFile('images/${p.basename(imagePath)}', bytes.length, bytes));
        }
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final zipFile = File('${tempDir.path}/backup_$timestamp.zip');
    await zipFile.writeAsBytes(zipBytes!);
    return zipFile;
  }

  Future<bool> backupToDrive() async {
    try {
      final api = await _getDriveApi();
      if (api == null) return false;

      final myMemoFolderId = await _findOrCreateFolder(api, _appFolderName);
      if (myMemoFolderId == null) return false;
      final backupsFolderId = await _findOrCreateFolder(api, _backupSubfolder, parentId: myMemoFolderId);
      if (backupsFolderId == null) return false;

      final zipFile = await _createBackupZip();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final media = drive.Media(zipFile.openRead(), await zipFile.length());
      final file = drive.File()
        ..name = 'backup_$timestamp.zip'
        ..parents = [backupsFolderId];

      await api.files.create(file, uploadMedia: media);
      await zipFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, String>>> listBackups() async {
    try {
      final api = await _getDriveApi();
      if (api == null) return [];

      final myMemoFolderId = await _findOrCreateFolder(api, _appFolderName);
      if (myMemoFolderId == null) return [];
      final backupsFolderId = await _findOrCreateFolder(api, _backupSubfolder, parentId: myMemoFolderId);
      if (backupsFolderId == null) return [];

      final result = await api.files.list(
        q: "'$backupsFolderId' in parents and trashed = false",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime)',
      );
      if (result.files == null) return [];

      return result.files!.map((f) => {
        'id': f.id!,
        'name': f.name ?? 'Unknown',
        'date': f.createdTime?.toIso8601String() ?? '',
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> restoreFromDrive({String? fileId}) async {
    try {
      final api = await _getDriveApi();
      if (api == null) return false;

      String targetFileId = fileId;
      if (targetFileId == null) {
        final myMemoFolderId = await _findOrCreateFolder(api, _appFolderName);
        if (myMemoFolderId == null) return false;
        final backupsFolderId = await _findOrCreateFolder(api, _backupSubfolder, parentId: myMemoFolderId);
        if (backupsFolderId == null) return false;

        final result = await api.files.list(
          q: "'$backupsFolderId' in parents and trashed = false",
          orderBy: 'createdTime desc',
          $fields: 'files(id, name, createdTime)',
        );
        if (result.files == null || result.files!.isEmpty) return false;
        targetFileId = result.files!.first.id!;
      }

      final media = await api.files.get(targetFileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final List<int> bytes = [];
      await for (final chunk in media.stream) { bytes.addAll(chunk); }

      final archive = ZipDecoder().decodeBytes(bytes);
      final dir = await getApplicationDocumentsDirectory();

      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;
          if (file.name == _dbFileName) {
            final dbPath = p.join(dir.parent.path, 'databases', _dbFileName);
            await File(dbPath).writeAsBytes(data);
          } else if (file.name.startsWith('images/')) {
            final fileName = p.split(file.name).last;
            final outPath = p.join(dir.path, fileName);
            await File(outPath).writeAsBytes(data);
          }
        }
      }

      _dbHelper = null;
      await DatabaseHelper().resetDatabase();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

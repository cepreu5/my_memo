# План: Windows вариант на my_memo — Separate Platform Files

## Принцип

**Нулева промяна** в съществуващите lib/ файлове. Всички Windows-specific промени са в нови файлове.

---

## Архитектура

```
lib/
├── platform/                          # НОВА папка
│   ├── platform_init.dart             # Entry point — conditionally exports
│   ├── platform_init_android.dart     # Android: noop
│   ├── platform_init_windows.dart     # Windows: sqflite FFI
│   │
│   ├── image_service.dart             # Conditionally exports
│   ├── image_service_android.dart     # Android: wraps image_picker
│   ├── image_service_windows.dart     # Windows: wraps file_picker
│   │
│   ├── backup_service.dart            # Conditionally exports
│   ├── backup_service_android.dart    # Android: /storage/emulated/0/... + Google Drive
│   ├── backup_service_windows.dart    # Windows: Documents/... + no Google Drive
│   │
│   └── sharing_service.dart           # Conditionally exports
│   ├── sharing_service_android.dart   # Android: wraps receive_sharing_intent
│   └── sharing_service_windows.dart   # Windows: noop (no share target)
```

---

## Фаза 1: Platform init (sqflite)

### `lib/platform/platform_init.dart`
```dart
import 'dart:io';
import 'platform_init_android.dart' as android;
import 'platform_init_windows.dart' as windows;

void initPlatform() {
  if (Platform.isWindows) {
    windows.init();
  } else {
    android.init();
  }
}
```

### `lib/platform/platform_init_android.dart`
```dart
void init() {
  // Нищо — Android sqflite работи по подразбиране
}
```

### `lib/platform/platform_init_windows.dart`
```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void init() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

### Промяна в `lib/main.dart` (МИНИМАЛНА — 2 реда)
```dart
import 'platform/platform_init.dart';  // НОВО

void main() {
  initPlatform();  // НОВО
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  runApp(const BusinessOrganizerApp());
}
```

---

## Фаза 2: Image service (file_picker vs image_picker)

### `lib/platform/image_service.dart`
```dart
import 'dart:io';
import 'image_service_android.dart' as android;
import 'image_service_windows.dart' as windows;

abstract class ImageService {
  Future<String?> pickImage();
}

ImageService createImageService() {
  if (Platform.isWindows) return windows.ImageServiceImpl();
  return android.ImageServiceImpl();
}
```

### `lib/platform/image_service_windows.dart`
```dart
import 'package:file_picker/file_picker.dart';
import 'image_service.dart';

class ImageServiceImpl implements ImageService {
  @override
  Future<String?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    return result?.files.single.path;
  }
}
```

### `lib/platform/image_service_android.dart`
```dart
import 'package:image_picker/image_picker.dart';
import 'image_service.dart';

class ImageServiceImpl implements ImageService {
  @override
  Future<String?> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    return picked?.path;
  }
}
```

### Промяна в `lib/note_form.dart` (МИНИМАЛНА)
```dart
import 'platform/image_service.dart';  // НОВО
// Всички останали image_picker импорти остават
```

---

## Фаза 3: Backup service

### `lib/platform/backup_service.dart`
```dart
import 'dart:io';

abstract class BackupService {
  Future<String> getBackupDirectory();
  bool get supportsGoogleDrive;
}

BackupService createBackupService() {
  if (Platform.isWindows) return BackupServiceWindows();
  return BackupServiceAndroid();
}
```

### `lib/platform/backup_service_windows.dart`
```dart
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'backup_service.dart';

class BackupServiceWindows implements BackupService {
  @override
  bool get supportsGoogleDrive => false;

  @override
  Future<String> getBackupDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'my_memo_backups');
  }
}
```

### `lib/platform/backup_service_android.dart`
```dart
import 'backup_service.dart';

class BackupServiceAndroid implements BackupService {
  @override
  bool get supportsGoogleDrive => true;

  @override
  Future<String> getBackupDirectory() async {
    return '/storage/emulated/0/Download/my_memo_backups';
  }
}
```

### Промяна в `lib/google_drive_helper.dart` (МИНИМАЛНА — 3 реда)
```dart
import 'platform/backup_service.dart';  // НОВО
// В saveBackupLocally() и listLocalBackups():
final backupService = createBackupService();  // НОВО
final backupDirPath = await backupService.getBackupDirectory();  // НОВО
```

### Промяна в `lib/settings_screen.dart` (МИНИМАЛНА — 2 реда)
```dart
import 'platform/backup_service.dart';  // НОВО

// В build():
final backupService = createBackupService();
if (backupService.supportsGoogleDrive) ...[
  // Съществуващ Google Drive UI
]
```

---

## Фаза 4: Sharing service

### `lib/platform/sharing_service.dart`
```dart
import 'dart:io';
import 'sharing_service_android.dart' as android;
import 'sharing_service_windows.dart' as windows;

abstract class SharingService {
  void init(void Function(List<String> paths) onShared);
  void dispose();
  Future<List<String>> getInitialMedia();
}

SharingService createSharingService() {
  if (Platform.isWindows) return windows.SharingServiceImpl();
  return android.SharingServiceImpl();
}
```

### `lib/platform/sharing_service_windows.dart`
```dart
import 'sharing_service.dart';

class SharingServiceImpl implements SharingService {
  @override
  void init(void Function(List<String> paths) onShared) {}
  @override
  void dispose() {}
  @override
  Future<List<String>> getInitialMedia() async => [];
}
```

### `lib/platform/sharing_service_android.dart`
```dart
// Wraps receive_sharing_intent
```

### Промяна в `lib/main.dart` (МИНИМАЛНА)
```dart
import 'platform/sharing_service.dart';  // НОВО

// В _initializeApp():
final sharingService = createSharingService();  // НОВО
sharingService.init((paths) { ... });  // НОВО
```

---

## Фаза 5: pubspec.yaml

```yaml
dependencies:
  sqflite_common_ffi: ^2.3.0  # НОВО
  file_picker: ^6.1.0          # НОВО
```

---

## Фаза 6: Windows build config

**`windows/CMakeLists.txt`**:
```cmake
set(BINARY_NAME "my_memo")
project(my_memo LANGUAGES CXX)
```

**`windows/runner/Runner.rc`**: Актуализиране на име.

**`windows/runner/resources/app_icon.ico`**: Генериране от PNG.

---

## Сводка на промените

| Файл | Тип |
|---|---|
| `lib/platform/**` (8 файла) | НОВИ |
| `lib/main.dart` | 3 добавени реда |
| `lib/note_form.dart` | 1 добавен ред |
| `lib/google_drive_helper.dart` | 3 добавени реда |
| `lib/settings_screen.dart` | 2 добавени реда |
| `pubspec.yaml` | 2 нови зависимости |
| `windows/CMakeLists.txt` | Rename |
| `windows/runner/Runner.rc` | Rename |

**Android код**: 100% непроменен.

---

## Верификация

1. `flutter pub get`
2. `flutter analyze`
3. `flutter build windows`
4. `flutter run -d windows`
5. `flutter build apk` — без regressions на Android

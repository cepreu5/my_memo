cls
# Изтриваме стария APK, ако съществува
if (Test-Path "android\app\build\outputs\flutter-apk\app-release.apk") {
    Remove-Item "android\app\build\outputs\flutter-apk\app-release.apk"
}

# Стартираме Flutter билд
flutter build apk

# Инсталираме през adb (автоматично намира пътя, ако си в папката на проекта)
adb install "android\app\build\outputs\flutter-apk\app-release.apk"

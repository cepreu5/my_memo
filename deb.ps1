cls
# Изтриваме стария APK, ако съществува
if (Test-Path "android\build\outputs\flutter-apk\app-debug.apk") {
    Remove-Item "android\build\outputs\flutter-apk\app-debug.apk"
}

# Стартираме Flutter билд
flutter build apk --debug

# Инсталираме през adb (автоматично намира пътя, ако си в папката на проекта)
# adb install "android\build\outputs\flutter-apk\app-debug.apk"
adb install "android\build\outputs\flutter-apk\app-debug.apk"
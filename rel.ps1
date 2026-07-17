cls
# Изтриваме стария APK, ако съществува
if (Test-Path "C:\dev\Projects\androd\my_memo\android\build\app\outputs\flutter-apk\app-release.apk") {
    Remove-Item "C:\dev\Projects\androd\my_memo\android\build\app\outputs\flutter-apk\app-release.apk"
}

# Стартираме Flutter билд
flutter build apk

# Инсталираме през adb (автоматично намира пътя, ако си в папката на проекта)
# adb install "android\app\build\outputs\flutter-apk\app-release.apk"
# adb disconnect "adb-d63823cca3ad-QkY2Gj (2)._adb-tls-connect._tcp"
adb install "C:\dev\Projects\androd\my_memo\android\build\app\outputs\flutter-apk\app-release.apk"
@echo off
setlocal

if "%1"=="" (
    echo Usage: build.bat [lifesync^|beebee]
    exit /b 1
)

set FLAVOR=%1

:: Build APK
flutter build apk --flavor %FLAVOR% -t lib/main_%FLAVOR%.dart --release

:: Ambil version dari pubspec.yaml
for /f "tokens=2 delims=: " %%a in ('findstr /b "version:" pubspec.yaml') do set VERSION=%%a
for /f "tokens=1 delims=+" %%a in ("%VERSION%") do set VERSION=%%a

:: Kapital huruf pertama flavor
set NAME=%FLAVOR%
if /I "%FLAVOR%"=="beebee" set NAME=BeeBee
if /I "%FLAVOR%"=="lifesync" set NAME=LifeSync

:: Rename APK
rename build\app\outputs\flutter-apk\app-%FLAVOR%-release.apk %NAME%_V%VERSION%.apk

echo.
echo Build selesai:
echo build\app\outputs\flutter-apk\%NAME%_V%VERSION%.apk
pause
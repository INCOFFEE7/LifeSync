$pubspec = Get-Content .\pubspec.yaml
$versionLine = $pubspec | Where-Object { $_ -match "^version:\s+(.*)" }
$version = $matches[1]

Write-Host "Building LifeSync APK version: $version"

flutter build apk --release

$sourceFile = ".\build\app\outputs\flutter-apk\app-release.apk"
$targetFile = ".\build\app\outputs\flutter-apk\LifeSync-v$version.apk"

if (Test-Path $sourceFile) {
    Copy-Item $sourceFile $targetFile -Force
    Write-Host "Success! APK compiled to: $targetFile"
} else {
    Write-Host "Build failed or APK not found at $sourceFile"
}

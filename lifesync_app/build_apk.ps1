# Build & Archive APK Script for WhatToDo
param (
    [switch]$Universal = $false
)

$ErrorActionPreference = "Stop"

Write-Host "══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " 🚀 WhatToDo APK Build & Archive Manager" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════" -ForegroundColor Cyan

# 1. Read version from pubspec.yaml
$pubspecContent = Get-Content -Path "pubspec.yaml" -Raw
if ($pubspecContent -match 'version:\s*([^\r\n]+)') {
    $rawVersion = $matches[1].Trim()
} else {
    $rawVersion = "unknown"
}
$safeVersion = $rawVersion -replace '\+', '_'
Write-Host "📦 Target Version: $rawVersion (Tag: $safeVersion)" -ForegroundColor Yellow

# 2. Execute Flutter Build
if ($Universal) {
    Write-Host "⚙️ Building Universal APK (Flavor: lifesync)..." -ForegroundColor Green
    flutter build apk --flavor lifesync --release
} else {
    Write-Host "⚙️ Building Split-per-ABI APKs (Flavor: lifesync)..." -ForegroundColor Green
    flutter build apk --flavor lifesync --split-per-abi
}

# Note: Custom outputFileName in Gradle can cause Flutter CLI to report exit code 1
# even when Gradle succeeds. We check for actual APK existence below.

# 3. Create releases folder outside build/
$releaseDir = Join-Path $PSScriptRoot "releases"
if (-not (Test-Path $releaseDir)) {
    New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
}

# 4. Copy and rename APKs
$flutterApkDir = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk"
$gradleApkDir = Join-Path $PSScriptRoot "build\app\outputs\apk\lifesync\release"
$copiedFiles = @()

if ($Universal) {
    $candidates = @(
        (Join-Path $flutterApkDir "app-lifesync-release.apk"),
        (Join-Path $flutterApkDir "app-release.apk")
    )
    $found = $null
    foreach ($cand in $candidates) {
        if (Test-Path $cand) { $found = $cand; break }
    }
    if (-not $found -and (Test-Path $gradleApkDir)) {
        $gradApk = Get-ChildItem -Path $gradleApkDir -Filter "WhatToDo*.apk" | Select-Object -First 1
        if ($gradApk) { $found = $gradApk.FullName }
    }
    if ($found) {
        $dest = Join-Path $releaseDir "WhatToDo-$safeVersion-universal.apk"
        Copy-Item -Path $found -Destination $dest -Force
        $copiedFiles += $dest
    }
} else {
    $abis = @("arm64-v8a", "armeabi-v7a", "x86_64")
    foreach ($abi in $abis) {
        $candidates = @(
            (Join-Path $flutterApkDir "app-$abi-lifesync-release.apk"),
            (Join-Path $flutterApkDir "app-$abi-release.apk"),
            (Join-Path $gradleApkDir "WhatToDo_v2026.11.06.01.03-$abi.apk")
        )
        $found = $null
        foreach ($cand in $candidates) {
            if (Test-Path $cand) { $found = $cand; break }
        }
        if (-not $found -and (Test-Path $gradleApkDir)) {
            $gradApk = Get-ChildItem -Path $gradleApkDir -Filter "*$abi*.apk" | Select-Object -First 1
            if ($gradApk) { $found = $gradApk.FullName }
        }
        if ($found) {
            $dest = Join-Path $releaseDir "WhatToDo-$safeVersion-$abi.apk"
            Copy-Item -Path $found -Destination $dest -Force
            $copiedFiles += $dest
        }
    }
}

if ($copiedFiles.Count -eq 0) {
    Write-Error "❌ Tidak ada file APK yang berhasil ditemukan di output build!"
    exit 1
}

Write-Host "`n══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host " ✅ BUILD & ARCHIVE BERHASIL!" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "📂 Arsip disimpan permanen di (Aman dari flutter clean):" -ForegroundColor White

foreach ($file in $copiedFiles) {
    $item = Get-Item $file
    $mb = [math]::Round($item.Length / 1MB, 2)
    Write-Host "  ⭐ $($item.Name) ($mb MB)" -ForegroundColor Cyan
    Write-Host "     Path: $($item.FullName)" -ForegroundColor DarkGray
}
Write-Host "══════════════════════════════════════════════════`n" -ForegroundColor Green

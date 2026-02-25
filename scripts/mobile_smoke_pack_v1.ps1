param(
  [string]$MobilePath = "apps/mobile",
  [string]$ArtifactsDir = "artifacts",
  [switch]$SkipWebBuild
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $MobilePath)) {
  throw "Mobile project path not found: $MobilePath"
}

if (-not (Test-Path $ArtifactsDir)) {
  New-Item -ItemType Directory -Path $ArtifactsDir -Force | Out-Null
}

Push-Location $MobilePath
try {
  Write-Host "==> flutter analyze"
  flutter analyze

  Write-Host "==> flutter test"
  flutter test

  Write-Host "==> flutter build apk --debug"
  flutter build apk --debug

  if (-not $SkipWebBuild) {
    Write-Host "==> flutter build web --release"
    flutter build web --release
  }
}
finally {
  Pop-Location
}

$apkSource = Join-Path $MobilePath "build/app/outputs/flutter-apk/app-debug.apk"
$apkTarget = Join-Path $ArtifactsDir "block-puzzle-internal-debug.apk"
if (Test-Path $apkSource) {
  Copy-Item $apkSource $apkTarget -Force
  Write-Host "APK copied to: $apkTarget"
} else {
  Write-Warning "APK build artifact not found: $apkSource"
}

if (-not $SkipWebBuild) {
  $webSource = Join-Path $MobilePath "build/web"
  $dateTag = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
  $webZipTarget = Join-Path $ArtifactsDir "block-puzzle-web-build-$dateTag.zip"

  if (Test-Path $webSource) {
    if (Test-Path $webZipTarget) {
      Remove-Item $webZipTarget -Force
    }
    Compress-Archive -Path (Join-Path $webSource "*") -DestinationPath $webZipTarget
    Write-Host "Web bundle archived to: $webZipTarget"
  } else {
    Write-Warning "Web build artifact not found: $webSource"
  }
}

Write-Host "Smoke pack completed."

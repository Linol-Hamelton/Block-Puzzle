# QA Smoke Pack v1

## 1. Purpose
Run the mandatory release-quality baseline for internal playtest and prepare installable artifacts for PC/Web and Android.

## 2. Checks Included
1. `flutter analyze`
2. `flutter test`
3. `flutter build apk --debug`
4. `flutter build web --release` (optional via switch)

## 3. Script
Use:
`scripts/mobile_smoke_pack_v1.ps1`

Example:
```powershell
.\scripts\mobile_smoke_pack_v1.ps1
```

Without web build:
```powershell
.\scripts\mobile_smoke_pack_v1.ps1 -SkipWebBuild
```

## 4. Output Artifacts
After successful run:
1. APK: [block-puzzle-internal-debug.apk](/d:/Block-Puzzle/artifacts/block-puzzle-internal-debug.apk)
2. Web zip: `artifacts/block-puzzle-web-build-YYYY-MM-DD.zip`

## 5. Pass Criteria
1. `analyze` has no issues.
2. Unit/widget/internal tests pass.
3. APK is produced and installable on Android test devices.
4. Web bundle opens and gameplay loop is functional (start -> move -> game over -> restart).

## 6. Notes
- This is smoke coverage, not full regression.
- Before external release, add performance and device-matrix checks.

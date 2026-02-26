# QA Smoke Pack v1

## 1. Purpose
Run the mandatory internal smoke baseline and generate quick installable artifacts for Android and Web.

## 2. Checks Included (current script)
1. `flutter analyze`
2. `flutter test`
3. `flutter build apk --debug`
4. `flutter build web --release` (optional)

## 3. Script
`./scripts/mobile_smoke_pack_v1.ps1`

Run:
```powershell
.\scripts\mobile_smoke_pack_v1.ps1
```

Skip web:
```powershell
.\scripts\mobile_smoke_pack_v1.ps1 -SkipWebBuild
```

## 4. Output Artifacts
- APK: [block-puzzle-internal-debug.apk](/d:/Block-Puzzle/artifacts/block-puzzle-internal-debug.apk)
- Web zip: `artifacts/block-puzzle-web-build-YYYY-MM-DD.zip`

## 5. Pass Criteria
1. Analyze has no blocking issues.
2. Tests pass.
3. APK installs and launches on Android test devices.
4. Core game loop is functional (start -> move -> game over -> restart).

## 6. Store-Mode Build Note
Smoke pack is intentionally debug-oriented.
For store validation, additionally build:
- `flutter build apk --release`
- `flutter build appbundle --release`

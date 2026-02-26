# apps/mobile

Flutter + Flame client for **Lumina Blocks**.

## Implemented Scope
- Playable classic mode core loop:
  - piece drag/drop
  - move validation
  - line clear
  - score/combo
  - game over/restart
- HUD with goals/streak/progression widgets.
- Store/IAP sandbox layer (debug purchase flow, targeting logic).
- Remote-config driven variants (difficulty, UX, visual block preset `soft` / `crystal`).
- Observability hooks (`ops_session_snapshot`, `ops_alert_triggered`, `ops_error`).

## Platforms
- Android (debug + release)
- Web (release build)
- Windows desktop (release package)
- iOS folder exists, but publication is out of current go-to-market scope.

## Run Locally
```bash
flutter pub get
flutter run
```

## Quality Checks
```bash
flutter analyze
flutter test
```

## Release Builds
```bash
flutter build apk --release
flutter build appbundle --release
flutter build web --release
flutter build windows --release
```

## Notes
- Current product strategy is **ad-free in-app UX** with IAP/cosmetics/utility path.
- Some SDK integrations are sandbox/debug implementations by design and are marked in corresponding docs.

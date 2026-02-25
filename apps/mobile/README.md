# Mobile App Scaffold

Flutter + Flame project scaffold for Block Puzzle.

## What is included
- Real Flutter project structure (`android`, `ios`, `web`, `lib`, `test`).
- DI container (`GetIt`) with stub service registrations.
- Domain contracts for gameplay/generator/scoring/session.
- Flame game screen skeleton and bootstrap flow.
- Minimal widget test and static analysis baseline.

## Run locally
```bash
flutter pub get
flutter run
```

## Quality checks
```bash
flutter analyze
flutter test
```

## Current status
- This is a production-oriented scaffold, not full gameplay implementation.
- Core-loop logic is intentionally not implemented yet (domain interfaces + stubs only).

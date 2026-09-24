# Current Task

Status: Completed - Stage W3 (First External Test Readiness) implemented; checks pass
Owner: RuslanFomenko
Last update: 2026-09-24

---

## Objective

Execute Stage W3 from docs/roadmap/15_POST_DEC0024_PLAN_2026-09-21.md:
Prepare repository for first external testing round (W3), completing all prerequisites
following G1.1-G1.3 gameplay/audio merge.

## Problem & Acceptance

- [x] G1.1-G1.3: Synced from D:\Block-Puzzle-g1 (DEC-0028 gameplay, audio, store gating).
- [x] C5: Telemetry game_id: 'classic' added to GameLoopController events.
- [x] D1: Android release signing fail-fast without debug fallback.
- [x] C6: Scoped/factory services per DEC-0016 (ABExperimentService, OnboardingFlowController, ProgressionSyncService).
- [x] F4: RU-only localization for store_controller strings via StoreStrings.
- [x] C7: Test DI in test/helpers/test_di.dart and 8 end-to-end integration widget tests in test/widget_test.dart.
- [x] Quality Gates: flutter analyze 0 issues, flutter test (453/453 passing).

## Current state

- All W3 tasks (C5, D1, C6, F4, C7) implemented and verified.
- Suite: 453 tests passing cleanly across unit and widget integration tests.
- Analyzer: 0 issues on flutter analyze --no-pub.

## Roles

- implementer: antigravity (G1 sync & Stage W3 implementation)
- reviewer: deepseek / claude

## Open questions

1. Owner approval to commit working tree changes (G1.1-G1.3 + W3).
2. Owner trigger for release build workflow or signing key provisioning.

---

Keep this file under 80 lines. It describes the current task only.


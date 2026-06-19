# Full Project Audit — Lumina Blocks

Date: 2026-06-19
Scope: full codebase + documentation audit, release-readiness assessment, and a feasibility/design study for adding Tetris and Match-3 as selectable games.
Method: **static source inspection only.** `flutter`/`dart` are not installed in the audit environment (confirmed not on `PATH`), so `flutter analyze` and `flutter test` were **not** executed. No runtime claim (tests green, analyzer clean) can be made from this audit; those must be re-verified on a machine with the toolchain.
Process: 8 parallel dimension audits → adversarial verification of the 14 highest-stakes claims (**9 confirmed, 5 partial, 0 refuted**) → reconciliation. Where a verifier downgraded a claim, the corrected version is used below.

> **P0 remediation update (2026-06-19).** The three P0 blockers in §9 have since been addressed **in code and verified** — `flutter analyze` reports no issues and all 153 tests pass (Flutter 3.44.2 / Dart 3.12.2): (P0-3) the stale `BlockPuzzleGame` DI factory now passes `haptics`; (P0-2) production analytics now validates via a `ValidatedAnalyticsTracker` decorator around Firebase; (P0-1) real Google Play billing (`GooglePlayBillingService` + `verifyPurchase` Cloud Function) is implemented and wired for production. Billing still needs Anonymous Auth, Play Console setup, function deploy, and a Play sandbox test before it transacts money. See [docs/DOCS_CHANGELOG.md](../DOCS_CHANGELOG.md) and ADRs [001](../adr/001-analytics-tracker-choice.md)/[003](../adr/003-billing-receipt-validation.md). This audit body remains the original 2026-06-19 snapshot.

---

## Краткое резюме (executive summary, RU)

**Что это.** Lumina Blocks — мобильная головоломка с блоками (полимино на сетке 8×8) на Flutter + Flame, без рекламы, монетизация через IAP (косметика, Premium Pass, мягкая валюта), приоритет — Android (Google Play + RuStore).

**Готовность к релизу: ~38%. Вердикт — NO-GO для публичного релиза.** Это честно соответствует собственному статусу команды (`pre-production`). Архитектура — настоящая сильная сторона: доменный слой проверенно чист (ноль импортов flutter/flame/firebase/hive), зависимости направлены внутрь, интерфейсы подменяемы через DI. Но два столпа, на которых держится игра-с-монетизацией, ещё не работают:

- **Реальных платежей нет.** Биллинг существует только как README-спецификация: нет зависимости `in_app_purchase`, нет файла `GooglePlayBillingService.dart`, нет серверной проверки чеков. Игра физически не может принять деньги.
- **Аналитика недостоверна.** Продакшен использует `FirebaseAnalyticsTracker` без валидации схемы (молча выбрасывает null-поля), а готовый валидирующий `QueuedAnalyticsTracker` нигде не подключён (мёртвый код).

**Tetris и Match-3 — выполнимо, но это не «настройка», а две новые игры.** В коде проверенно отсутствуют любые абстракции мультиигры. Доска только квадратная, клетка хранит лишь занятость без цвета/типа (Match-3 в такой модели невозможен), нет цикла гравитации/тика и вращения (нет ядра Tetris). Реалистичная программа — **9–13 инженеро-недель** при едином движке (см. [04_MULTI_GAME_ENGINE_PLAN.md](../architecture/04_MULTI_GAME_ENGINE_PLAN.md)).

---

## 1. Release-readiness verdict

**38% — NO-GO for public release.**

Lumina Blocks is an honestly pre-production, Classic-only block puzzle with genuinely strong architectural bones but several confirmed correctness/consistency defects below a TOP-1 bar and, critically, **no working commerce and no trustworthy production data plane**. The team's own `docs/roadmap/05_IMPLEMENTATION_STATUS.md` already labels the project pre-production and not ready for publication — which matches reality — but that same doc contradicts the current code in several places (see §5).

What stands between today and a **closed-test** launch (not a full launch):

1. Real billing (P0) — see §4.
2. Analytics integrity decision + wiring (P0) — see §4.
3. DI/lifecycle defects fixed (P0) — see §3.
4. `flutter analyze` + `flutter test` confirmed green in CI on a real toolchain (P1) — could not be verified here.
5. Status doc reconciled with code (P1) — see §5.

A full public launch additionally needs the live-cohort gates (crash-free ≥ 99.5%, early-gameover rate, etc.) which require real telemetry that is not active yet.

---

## 2. Dimension scorecard

High-level scores from the 8 parallel audits (0 = absent, 100 = TOP-1 production grade):

| # | Dimension | Score | Signal |
|---|---|---:|---|
| 1 | Code architecture & quality | **68** | 🟢 strongest asset |
| 2 | Performance / rendering / game-feel | **61** | 🟢 good, low-end risks to validate |
| 3 | Test coverage & CI | **42** | 🟡 domain-heavy, gaps elsewhere |
| 4 | Documentation set | **42** | 🟡 rich but out of sync with code |
| 5 | Release readiness vs own gates | **34** | 🟠 far from a publish decision |
| 6 | Security / privacy / compliance | **28** | 🔴 Data Safety + anti-cheat unaddressed |
| 7 | Firebase / monetization / billing | **28** | 🔴 mostly scaffold; no real billing |
| 8 | Multi-game engine extensibility | **22** | 🔴 hard-coupled to block puzzle |

Finer-grained sub-scores (from reconciliation):

| Sub-dimension | Score | Rationale (verified) |
|---|---:|---|
| Domain purity & layering | 88 | `grep` over `lib/domain/` finds zero flutter/flame/firebase/hive/shared_preferences imports. Inward dependency direction is real. |
| Persistence robustness | 72 | Hive repos verified wired; `schemaVersion=2` migration + corrupt-cache self-heal present. |
| Crash / error handling | 75 | `FlutterError.onError` + `PlatformDispatcher.onError` + `ErrorBoundary` wired; `FirebaseCrashReporter` present. But `main()` does not await `bootstrap()`. |
| DI & composition root | 60 | Clean get_it root, but the `BlockPuzzleGame` factory omits the now-required `haptics` arg (see §3). |
| Lifecycle correctness | 50 | Factory controller + singleton sub-services lifecycle mismatch (latent, not an active bug — see §3). |
| Test coverage | 48 | 18 test files, domain/use-case heavy; no integration/golden/drag-input tests; could not run. |
| Controller design / SRP | 45 | `game_loop_controller.dart` confirmed 1277 lines; still embeds board solver + ~17 inline analytics calls. |
| Analytics integrity | 40 | Production `FirebaseAnalyticsTracker` does no schema validation; validated `QueuedAnalyticsTracker` is dead code. |
| Docs governance | 40 | Designated source-of-truth doc exists but has confirmed code-vs-doc contradictions and no enforced sync. |
| Monetization readiness | 22 | Billing is README-only: no `in_app_purchase`, no `*billing*.dart`, no `verifyPurchase`. |
| Multi-game extensibility | 22 | No `GameId`/`GameMode`/`GameEngine`/`GameRegistry` anywhere; square-only board, binary cell. |
| Localization / i18n | 18 | Hardcoded RU strings in `store_controller.dart` mixed with English; no `AppLocalizations`/`intl`/`.arb`. |

---

## 3. Code architecture & quality

**Score 68/100. The bones are good; several correctness/consistency gaps sit below the TOP-1 bar.**

### Strengths (verified)
- **Domain purity is real.** `grep` across `lib/domain` finds no imports of `package:flutter`, `package:flame`, `package:firebase`, `cloud_firestore`, `hive`, or `shared_preferences` — domain depends only on `dart:core/convert/math`. Gameplay rules are independently testable.
- **Inward dependency direction.** Data-layer adapters implement domain abstractions (`HivePlayerProgressRepository implements PlayerProgressRepository`, `CloudPlayerProgressRepository` likewise), not the reverse.
- **Clean interface/implementation seam** swapped at the composition root (`di_container.dart`) by environment + flavor (debug/in-memory vs production).
- **Prior refactoring effort:** progression, onboarding, A/B, and share concerns already extracted into dedicated services; place/clear/score use-cases injected.
- **Persistence hardening:** `PlayerProgressState` has explicit `schemaVersion=2` with a legacy v1 migration path and defensive parsers; `HivePlayerProgressRepository.load()` recovers from corrupt JSON.
- **Global error handling** wired at bootstrap for both `FlutterError.onError` and `PlatformDispatcher.onError`, chaining to a `CrashReporter` + an `ErrorBoundary` widget.

### Confirmed defects

| Sev | Finding | Evidence | Note |
|---|---|---|---|
| **P0/P1** | `BlockPuzzleGame` DI factory is stale — omits the now-required `haptics` arg. This is a **compile-time** `missing_required_argument` error. | `di_container.dart:204-209` vs `block_puzzle_game.dart:25-35`; introduced by commit `a577485` (added required `haptics` to ctor + the HapticsController singleton, left the factory untouched). | **Verifier correction:** the auditor's claim that this "escapes CI because nothing calls it" is **wrong** — a missing required arg is flagged by `flutter analyze`/the compiler at the closure body regardless of call sites. Therefore CI's analyze step *should* fail on it. Either CI is not actually gating, or the committed tree differs. **Re-run `flutter analyze` to settle this.** The registration is also dead (no `sl<BlockPuzzleGame>()` call site; the screen builds the game manually with all four args). Fix: add `haptics: sl()` (the singleton is registered at `di_container.dart:85`) or delete the dead registration. |
| P1 | Production analytics bypasses the schema validator while the validated tracker is dead code. | `di_container.dart:124-128` resolves `FirebaseAnalyticsTracker` in release; it does no validation and silently drops null params (`firebase_analytics_tracker.dart:16-30`). `QueuedAnalyticsTracker` (validation, quarantine, persist, retry) is referenced nowhere outside its own file, including no tests. | Nuance: the debug-only `DebugAnalyticsTracker` *does* validate, but short-circuits under `kReleaseMode`. The release path is the only un-validated one. |
| P1 | `GameLoopController` is a 1277-line coordinating god-object. | Confirmed via `wc -l`. Still embeds the board solver (`_hasAnyValidMove`, `_findHintSuggestion`, `_buildReviveSnapshot`/`_clearCellsForRevive`) and ~17 inline `analyticsTracker.track(...)` calls. | Nuance: meaningful extraction already done (A/B, onboarding, progression, share, place/clear/score). The two remaining concerns to extract are the **board solver** and **analytics emission**. |
| P2 | Factory controller + singleton sub-services lifecycle mismatch. | `GameLoopController` is `registerFactory` (`di_container.dart:182`); its sub-services are `registerLazySingleton` (`:148-180`) with no reset on dispose. | **Verifier downgrade:** this is a *latent* ownership smell, **not an active state-leak bug** — `initialize()` re-derives all relevant state from config + persistence on each entry. The only non-re-seeded field (`OnboardingFlowController._moveCount`) is inert on the resume path. Harden defensively; not a release blocker. |
| P2 | Constructor mixes optional params with hard null-assertions; duplicate `configure()` call. | `playerProgressRepository` is a nullable optional param force-unwrapped with `!` at `game_loop_controller.dart:71,81`; `onboardingFlowController.configure(_configReader)` is duplicated at `:156-157`. | A caller omitting the repo gets a runtime null-check crash instead of a compile-time contract error. |
| P2 | No localization layer; hardcoded RU/EN mix in an application controller. | `store_controller.dart:64,96,119` (also `:127,146,159,228`) render Russian SnackBar text; `:119` interpolates English `cancelled`/`failed` into a Russian string. No `.arb`/`intl`. | User-facing (rendered via `store_screen.dart:49-50`). |
| P2 | `main()` does not await `bootstrap()` (fire-and-forget with no top-level guard). | `main.dart:3-5`. | |

---

## 4. Firebase, monetization & billing

**Score 28/100. Mostly scaffold. The two revenue/data pillars are not real yet.**

| Capability | Real state (verified) |
|---|---|
| Firebase Crashlytics | **Implemented in code.** `FirebaseCrashReporter` uses `FirebaseCrashlytics.instance` (`firebase_crash_reporter.dart:16-36`); `firebase_crashlytics: ^4.0.0` in pubspec. (ANR bridge still pending.) |
| Hive persistence | **Implemented in code.** `HivePlayerProgressRepository` + `HiveGameSessionRepository` wired (`di_container.dart:100-107`). |
| Firebase Analytics | Wired but **unvalidated** (`FirebaseAnalyticsTracker`, no schema check, drops nulls). |
| **Google Play Billing v7** | **Not implemented.** No `in_app_purchase` dependency in `pubspec.yaml`; `lib/infra/billing/` contains only a `README.md` (no `.dart`); no `verifyPurchase` Cloud Function. The game cannot transact real money. |
| Server-side receipt validation | Not implemented (`infra/cloud_functions/` is scaffold-only). |
| Remote Config / Auth | Client contracts present; live control plane not verified (no live Firebase in this audit). |

**Monetization-model note.** The ad-free, IAP-only model is a fixed decision and is shippable in principle, but it is *entirely* gated on real billing existing. Until then there is no revenue path at all.

---

## 5. Documentation audit

**Score 42/100. Rich, well-organized set (60+ docs) with a designated source of truth, but out of sync with code and lacking governance.**

### Confirmed contradictions (code is ground truth)

1. **Hive persistence wrongly listed as "Not Implemented Yet"** — `docs/roadmap/05_IMPLEMENTATION_STATUS.md:51` vs `di_container.dart:100-108`. → reclassify as Implemented in code.
2. **Crashlytics wrongly listed as "Not Implemented Yet"** — same doc `:47` vs `firebase_crash_reporter.dart`. → reclassify (keep ANR bridge pending).
3. **Daily Challenge status contradictory** — frozen to Phase 4 (`:14,55`) yet shipped now (commit `945ab1b`, `isDailyChallenge` flow, `home_screen.dart` button). → reconcile both lines.
4. **"Release-safe local analytics queue" overstated** — `:28` claims implemented; `QueuedAnalyticsTracker` is orphaned (production uses `FirebaseAnalyticsTracker`). → reword.
5. **Billing README implies more than exists** — `lib/infra/billing/README.md` describes `GooglePlayBillingService` + `verifyPurchase`; no such code. → explicit "scaffold/spec only" banner (the README does say "Empty in Phase 0" at the very bottom; the banner should be at the top and unmissable).

### Governance recommendations
- **Single source of truth:** keep `05_IMPLEMENTATION_STATUS.md` canonical; add a cheap CI grep-guard that fails a PR touching `di_container.dart` or `pubspec.yaml` without updating the status doc.
- **Changelog:** revive a top-level `docs/DOCS_CHANGELOG.md` (only an archived one exists); every status-changing merge appends a dated line.
- **ADRs:** introduce `docs/adr/`; record the load-bearing decisions surfaced here (analytics tracker choice, game-engine abstraction strategy, billing architecture, controller/sub-service lifecycle).
- **"Implemented" definition:** a feature counts as Implemented only if it is wired in DI and reachable from a code path — not merely present as a class. (The orphaned `QueuedAnalyticsTracker` and the billing README are the cautionary examples.)

---

## 6. Tests & CI

**Score 42/100.** ~18 test files, weighted to domain rules + use-cases + controller orchestration + schema/observability — the pure-logic layers are genuinely well-covered. Gaps: no integration tests, no golden/render tests, no drag-input tests, and the critical `cold_kill_recovery_test` should be confirmed present and green. Analyzer config is strict (`strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `unawaited_futures`). **Could not run `flutter analyze`/`flutter test`** — CI gating must be confirmed on a real toolchain, especially given the stale `BlockPuzzleGame` factory (§3) which *should* fail analyze.

---

## 7. Security, privacy & compliance

**Score 28/100.** The biggest open items for an Android launch: Play **Data Safety** form readiness (Firebase Analytics + Anonymous Auth UID are collected identifiers and must be declared), GDPR/age-gating posture, **server-side anti-cheat** for the planned leaderboards (currently no receipt/score validation — client-trusted), RuStore-specific compliance, and a secrets-in-repo review (confirm `google-services.json` / API keys are not committed). The Privacy Policy exists only as a draft. None of this is a code defect today, but all of it is launch-blocking paperwork/infra.

---

## 8. Performance, rendering & game-feel

**Score 61/100.** The rendering is a clear strength: `PictureRecorder` caching for the board and rack pieces, glass-block cells with layered gradients/sheen, line-clear flash, cell-burst particles, combo pulse, camera shake, and a haptics controller integrated into placement/clear/combo. Risk to validate on low-mid Android (the KPIs are cold start p90 ≤ 2.5s and 60fps on Redmi 9/10): the multiple `MaskFilter.blur` passes and large `RadialGradient`/`LinearGradient` shaders per cell can be expensive — needs a real-device profile. This is the dimension closest to the TOP-1 bar.

---

## 9. Prioritized action list

**P0 — blockers**
1. Implement real billing: add `in_app_purchase`, create `GooglePlayBillingService` (acknowledge + pending poll + restore), and a Cloud Function `verifyPurchase` → Firestore entitlements.
2. Decide & execute the analytics strategy: wire `QueuedAnalyticsTracker` (schema validation + queue + retry) into production *instead of* `FirebaseAnalyticsTracker`, or delete the dead code. Do not ship both.
3. Fix the stale `BlockPuzzleGame` DI factory (add `haptics: sl()` or remove the dead registration) and re-run `flutter analyze` to confirm the tree compiles clean.

**P1**
4. Reconcile `05_IMPLEMENTATION_STATUS.md` with code (the 5 contradictions in §5).
5. Confirm `flutter analyze --fatal-infos --fatal-warnings` and `flutter test` green in CI on a real toolchain; add integration + golden + drag-input tests.
6. Introduce a localization layer (`intl`/`AppLocalizations`); move user-facing strings out of controllers.
7. Split `GameLoopController`: extract the board solver and analytics emission into testable services; remove the duplicate `configure()`; replace the constructor null-assertion with an explicit dependency contract.

**P2**
8. Align the controller/sub-service lifecycle (scoped sub-services or singleton controller with explicit reset).
9. Guard deferred callbacks against `setState`-after-dispose; make `main()` await `bootstrap()` with a top-level guard.
10. Adopt the multi-game engine plan as an ADR before any Tetris/Match-3 work — see [04_MULTI_GAME_ENGINE_PLAN.md](../architecture/04_MULTI_GAME_ENGINE_PLAN.md).

---

## 10. New games: Tetris & Match-3 — verdict

Both are **feasible at medium effort**, but they are **two new games**, not configurations of the existing one. The engine has no multi-game abstraction (no `GameId`/`GameEngine`/`GameRegistry`), the board is square-only with binary cells (Match-3 cannot be modeled on it), and there is no model-level tick loop or rotation (Tetris core is absent). Recommended program: build a shared `GameMode`/`GameEngine` seam + generalize the board (W×H, typed cells) once, then add each game.

- **Shared engine + both games:** ~9–13 engineer-weeks (phased; Classic never breaks).
- **As two independent parallel controllers:** ~7–10 (Tetris) + ~8–12 (Match-3) with duplicated infrastructure.

Full design, phasing, contracts, and risks: [docs/architecture/04_MULTI_GAME_ENGINE_PLAN.md](../architecture/04_MULTI_GAME_ENGINE_PLAN.md).

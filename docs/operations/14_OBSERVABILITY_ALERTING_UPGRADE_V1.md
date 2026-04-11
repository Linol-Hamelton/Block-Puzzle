# Observability and Alerting (Firebase Crashlytics + alert_router)

Last updated: 2026-04-12. Aligned with [../roadmap/01_ROADMAP_AND_SPRINTS.md](../roadmap/01_ROADMAP_AND_SPRINTS.md) Phase 1 Week 1 (Crashlytics wiring) and Phase 2 Week 6 (alert_router Cloud Function + webhook).

## 1. Goal
Provide a first operational guardrail layer on top of gameplay telemetry so regressions are detected early and rollout stays safe. Crash/ANR is owned by Firebase Crashlytics; gameplay guardrails come from client-side `ops_*` events evaluated against Remote Config thresholds.

## 2. Components

### 2.1 Crashlytics (Phase 1 W1)
- `CrashReporter` contract in `lib/infra/monitoring/crash_reporter.dart` with `recordError`, `recordFlutterError`, `setUserId`, `setCustomKey`, `log`.
- `FirebaseCrashReporter` is the production implementation; `NoopCrashReporter` is the dev-flavor fallback.
- Bootstrap wiring:
  - `runZonedGuarded(runApp, reporter.recordError)`
  - `FlutterError.onError = reporter.recordFlutterError`
  - `PlatformDispatcher.instance.onError = reporter.recordError`
- NDK symbol upload via `firebaseCrashlytics.nativeSymbolUploadEnabled = true` in Gradle.
- Android ANR reports are captured natively by Crashlytics.

### 2.2 Gameplay Observability Events (already in code, normalized to Firebase Analytics names)
1. `ops_session_snapshot` — emitted at session end. Payload: `session_id`, `rounds_played`, `rounds_ended`, `session_duration_sec`, `early_gameover_rate`, `move_rejected_rate`, `avg_round_duration_sec`, `runtime_error_count`, optional counters and `alert_count`.
2. `ops_alert_triggered` — emitted once per violated guardrail on session end. Payload: `alert_id`, `severity`, `metric_name`, `comparator`, `threshold`, `observed_value`, optional `session_id`, variants, message.
3. `ops_error` — emitted on global/runtime error hooks and selected controller recoveries. Payload: `source`, `error_type`, optional `message`.

Phase 1 adds:
- `ops_storage_recovered` — Hive self-heal triggered. Payload: `box_name`, `reason`, `recovered_at`.
- `ops_rack_fallback` — piece generator fell back to the safe rack. Payload: `attempts`, `board_fill_ratio`.
- `ops_audio_degraded` — audio pool gave up after recovery attempts. Payload: `reason`, `recovery_attempts`.
- `ops_config_invalid` — Remote Config payload failed schema validation. Payload: `config_version`, `offending_key`, `expected_type`.
- `ops_error_boundary` — ErrorBoundary fallback UI was shown. Payload: `route`, `error_type`.

### 2.3 Runtime Sources
1. `GameLoopController`
   - tracks move attempts, rejections, round endings, no-move game-overs.
   - tracks recoverable runtime failures in gameplay dependencies and feeds `ops_error`.
2. App bootstrap hooks
   - `FlutterError.onError`, `PlatformDispatcher.instance.onError`, `runZonedGuarded`.
3. Infra layer
   - `HiveStorage` emits `ops_storage_recovered`.
   - `FlameGameSfxPlayer` emits `ops_audio_degraded`.
   - `FirebaseRemoteConfigRepository` emits `ops_config_invalid`.
   - `ErrorBoundary` widget emits `ops_error_boundary`.

## 3. Guardrail Rules (Default — Remote Config driven)
1. `early_gameover_rate > ops.alerting.max_early_gameover_rate` → critical.
2. `move_rejected_rate > ops.alerting.max_move_rejection_rate` with sample floor → warning.
3. `avg_round_duration_sec < ops.alerting.min_avg_round_duration_sec` → warning.
4. `runtime_error_count > ops.alerting.max_runtime_error_count` → critical.
5. `storage_recovered_count > ops.alerting.max_storage_recovery_count` → critical.
6. `config_invalid_count > ops.alerting.max_config_invalid_count` → critical.

### 3.1 Remote Config Keys
- `ops.alerting.enabled` (bool)
- `ops.alerting.max_early_gameover_rate` (double)
- `ops.alerting.max_move_rejection_rate` (double)
- `ops.alerting.min_avg_round_duration_sec` (double)
- `ops.alerting.max_runtime_error_count` (int)
- `ops.alerting.max_storage_recovery_count` (int)
- `ops.alerting.max_config_invalid_count` (int)

Thresholds are tuned without an app update.

## 4. Alert Routing (Phase 2 W6)

### 4.1 Cloud Function `alert_router`
- `infra/cloud_functions/alert_router.ts`.
- Triggered by:
  1. Crashlytics velocity alerts (via Firebase Alerts extension → Eventarc).
  2. A scheduled BigQuery query over `ops_alert_triggered` severity counts per 15-minute window.
- Sends a structured payload (severity, metric, value, window, link to Crashlytics / Looker Studio) to:
  - Slack webhook `#lumina-blocks-ops`.
  - Telegram bot `lumina_ops_bot`.
- Deduplicates by `alert_id + window_start` within a rolling 60-minute cache.

### 4.2 Crashlytics-native Alerts
- Email alerts for velocity + new fatal issues are enabled in Firebase Console for `lumina-blocks-prod`.
- Slack notification via Firebase Alerts extension is the primary channel; email is the fallback.

## 5. Operational Playbook
1. Monitor `ops_alert_triggered` counts in the Looker Studio observability block by `alert_id`, `ux_variant`, `difficulty_variant`.
2. If a critical alert trend persists for 2 collection windows, freeze experiment traffic increase and open a Go/No-Go review.
3. If a runtime alert spikes, block rollout and run hotfix triage before the next build promotion; use Remote Config kill switches to contain blast radius.
4. If `ops_storage_recovered` spikes, suspect a schema migration regression — freeze the current Hive box version and investigate.
5. Keep thresholds in Remote Config so rollback can be tuned without an app patch.

## 6. Phase 1 Exit Checks
- Crashlytics receives real events from a release build within 10 minutes of install.
- ErrorBoundary visually verified by deliberately throwing inside a screen in the dev flavor.
- `ops_session_snapshot` appears in Firebase Analytics DebugView during QA.
- Remote Config kill switches for alerting verified end-to-end.

## 7. Deferred / Out of Scope
- Custom observability backend — deferred in favor of Firebase Crashlytics + Firebase Analytics + BigQuery.
- PagerDuty integration — Phase 5, only if volume requires it.
- Structured log aggregation beyond Crashlytics breadcrumbs — Phase 5, if needed.

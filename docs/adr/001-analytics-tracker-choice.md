# ADR-001 — Production analytics tracker: validated vs unvalidated

Status: Accepted (2026-06-19) — implemented
Related: [audit §3/§4](../audit/01_FULL_PROJECT_AUDIT_2026-06-19.md)

## Context
Two analytics trackers exist. `FirebaseAnalyticsTracker` (production, `di_container.dart:124-128`) performs **no schema validation** and silently drops null params (`firebase_analytics_tracker.dart:16-30`). `QueuedAnalyticsTracker` adds `schema_version`, validates required fields, quarantines invalid events, persists, and retries — but is referenced nowhere in `lib` (orphaned, no tests). For a game whose KPIs depend on event integrity, shipping the unvalidated path while a validated one rots is a correctness and trust risk.

## Decision (ratified + implemented)
Make schema validation a transport-independent concern via a decorator,
`ValidatedAnalyticsTracker`, rather than coupling validation to a specific
transport. This respects the Firebase-first decision: `QueuedAnalyticsTracker`'s
HTTP transport targets the **deferred** `services/analytics-pipeline`, so wiring
it as the production tracker would route events away from Firebase — wrong.

Implemented:
- New `data/analytics/validated_analytics_tracker.dart` — enriches
  (`schema_version`, `event_ts_utc`), validates via `AnalyticsSchemaValidator`,
  logs warnings, **quarantines** events missing required params, forwards valid
  events to the wrapped transport.
- Production DI now resolves
  `ValidatedAnalyticsTracker(inner: FirebaseAnalyticsTracker())`
  (`di_container.dart`), so release builds validate before sending to Firebase.
- Debug builds keep `DebugAnalyticsTracker` (already validating).
- `QueuedAnalyticsTracker` is retained as the transport for the deferred HTTP
  pipeline and can be wrapped by the same decorator if that pipeline is ever
  revived. It is no longer "the validated tracker rotting while prod is
  unvalidated".
- Unit test: `test/unit/data/analytics/validated_analytics_tracker_test.dart`.

## Consequences
- Production now enforces the event schema; `analytics_schema_validator.dart` is
  a release-path dependency and must stay in sync with the event taxonomy.
- **Behavior change / rollout watch:** known events missing required params are
  now dropped (quarantined) in production instead of being sent malformed. Debug
  already validated identically, so conformance should hold — but monitor
  `[ANALYTICS][QUARANTINE]` logs / Crashlytics after the first release to catch
  any schema drift.
- Verified (2026-06-19): `flutter analyze` clean and all 153 tests pass,
  including `test/unit/data/analytics/validated_analytics_tracker_test.dart`.

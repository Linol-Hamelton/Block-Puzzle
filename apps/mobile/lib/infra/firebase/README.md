# infra/firebase

Phase 1 Week 3.

Firebase integration layer. Implementations of existing contracts:
- `FirebaseRemoteConfigRepository` — implements [`RemoteConfigRepository`](../../data/remote_config/remote_config_repository.dart)
- `FirebaseAnalyticsTracker` — implements [`AnalyticsTracker`](../../data/analytics/analytics_tracker.dart)
- `FirebaseAuthService` — Anonymous Auth for UID binding
- `FirebaseMessagingBootstrap` — FCM token registration, topic subscription

Bundled defaults for Remote Config live in `assets/config/remote_config_defaults.json` (Phase 1).

Empty in Phase 0.

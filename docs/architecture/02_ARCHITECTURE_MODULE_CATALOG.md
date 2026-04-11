# Architecture Module Catalog

Last updated: 2026-04-12. This catalog aligns with the Firebase-first decision and the 5-phase roadmap in [../roadmap/01_ROADMAP_AND_SPRINTS.md](../roadmap/01_ROADMAP_AND_SPRINTS.md).

## 1. Client Architecture (Flutter + Flame)
Layering (outer → inner):
1. **Presentation layer** — screens, widgets, Flame components, overlays
2. **Application layer** — controllers, use-case orchestration, state machines
3. **Domain layer** — pure gameplay logic (no Flutter/Flame dependencies)
4. **Data layer** — contracts, DTOs, schema validation, in-memory fakes
5. **Infra layer** — concrete SDK-bound implementations (Firebase, billing, storage)

Dependency direction is strictly outward → inward. Domain never imports Flutter; application never imports Firebase directly; infra implements data-layer contracts.

## 2. Core Modules (Current)
| Module | Responsibility | Input | Output |
|---|---|---|---|
| `domain/gameplay` | board state, move validity, line clear | board + move | updated board / result |
| `domain/generator` | piece generation and pressure tuning | session + config | rack pieces |
| `domain/scoring` | score / combo calculations | move / clear result | score delta |
| `domain/progression` | player progress state, daily goals, streak | gameplay events + config | persisted progress snapshot |
| `features/game_loop` | runtime orchestration, Flame wiring, input | user input + services | renderable state + telemetry |
| `features/store` | catalog, entitlement, purchase flow | config + ownership | offers + purchase results |
| `features/monetization` | ad service stub (no-op), offer targeting, guardrails | config + segment | show / skip decisions |
| `data/analytics` | typed tracking contract, local queue, schema validation | event payloads | logged events, dispatch hooks |
| `data/remote_config` | config snapshot contract, fallback, cached snapshots | app lifecycle | typed config values |
| `core/di` | dependency injection (get_it) | environment + flavor | wired services |
| `core/config` | environment + flavor resolution | build args | `AppEnvironment`, `BuildFlavor` |
| `app/bootstrap` | app init, splash, hydration | — | configured `runApp` |

## 3. Phase-1 / Phase-3 Modules (To Be Added)
| Module | Phase | Purpose |
|---|---|---|
| `infra/firebase/firebase_remote_config_repository` | 1 W3 | Firebase Remote Config implementation of `RemoteConfigRepository` |
| `infra/firebase/firebase_analytics_tracker` | 1 W3 | Firebase Analytics implementation of `AnalyticsTracker` |
| `infra/firebase/firebase_auth_service` | 1 W3 | Anonymous Auth for UID binding |
| `infra/firebase/firebase_messaging_bootstrap` | 3 3E | FCM token registration, topic subscription |
| `infra/monitoring/crash_reporter` | 1 W1 | `CrashReporter` abstraction + `FirebaseCrashReporter` + `NoopCrashReporter` |
| `infra/billing/google_play_billing_service` | 1 W3 | Real `in_app_purchase` implementation of `IapStoreService` |
| `infra/billing/rustore_billing_service` | 2 | RuStore billing adapter |
| `data/storage/hive_storage` | 1 W2 | Hive init, encryption key, schema versioning, self-heal |
| `core/network/resilient_http_client` | 1 W4 | Exponential backoff + jitter + circuit breaker |
| `core/widgets/error_boundary` | 1 W1 | Top-level fallback UI with Crashlytics integration |
| `features/meta_progression` | 3 3A | Player level, XP, reward tables |
| `features/economy` | 3 3A | Soft currency wallet (Shards, Crystals) |
| `features/revive` | 3 3B | Soft-currency revive, free daily revive |
| `features/missions` | 3 3B | Daily + weekly missions with Remote Config pool |
| `features/rewards` | 3 3B | Daily wheel (soft currency, no ads) |
| `features/cosmetics` | 3 3C | Skins, backgrounds, VFX, SFX packs + Season Pass |
| `features/achievements` | 3 3D | 30 badges, gameplay listener, cosmetic rewards |
| `features/events` | 3 3D + 4 | Event calendar, limited-time modes |
| `features/leaderboard` | 4 | Firestore-backed mode leaderboards with anti-cheat |
| `l10n/` | 3 3E | `flutter_localizations` + `intl` + `.arb` files |

## 4. Backend / External Integrations
### Firebase (Active from Phase 1)
- **Firebase Crashlytics** — crash + ANR reporting, native symbol upload via Gradle
- **Firebase Analytics** — event ingestion, auto-exported to BigQuery for cohort analysis
- **Firebase Remote Config** — typed config snapshot, kill switches (`feature_*`), `force_update_min_version`, AB variant assignment
- **Firebase Authentication** — Anonymous Auth → UID binding for entitlement sync
- **Firebase Cloud Messaging** — push notifications (max 1/day), topic-based for events/missions
- **Firebase Cloud Functions** — `verifyPurchase` (Google Play receipt validation), `alert_router` (Crashlytics webhook → Slack/Telegram), `mission_roll` (daily/weekly mission assignment)
- **BigQuery export** — source for Looker Studio dashboards
- **Firebase Hosting** — Privacy Policy, support landing page

### Deferred (Historical Contracts)
- `services/config-api` — deferred in favor of Firebase Remote Config ([services/config-api/README.md](../../services/config-api/README.md))
- `services/analytics-pipeline` — deferred in favor of Firebase Analytics + BigQuery ([services/analytics-pipeline/README.md](../../services/analytics-pipeline/README.md))

## 5. Domain Contracts (Current)
- `MoveValidator`
- `LineClearService`
- `ScoreService`
- `PieceGenerationService`
- `DifficultyTuner`
- `PlayerProgressRepository` (Hive-backed from Phase 1 W2)

## 6. ADR Baseline
1. Flutter + Flame remains the primary client stack; no Unity/native rewrite is on the roadmap.
2. Domain logic stays SDK-independent so gameplay rules are testable without Flutter or Firebase.
3. Runtime tuning is config-driven via the `RemoteConfigRepository` contract; the concrete implementation is Firebase Remote Config from Phase 1.
4. Event contracts are versioned and validated client-side via `AnalyticsTracker`; Firebase Analytics is the transport.
5. Feature rollout is flag/experiment driven via Firebase Remote Config + Firebase A/B Testing.
6. Monetization is IAP-only (ad-free); `ad_service` interfaces exist only as dev-flavor no-ops for historical compatibility.
7. Persistence of critical state (player progress, game snapshot, entitlements) uses Hive with explicit schema versioning and self-heal, not SharedPreferences.
8. Crash/ANR reporting is mandatory for release builds via Firebase Crashlytics.

## 7. Quality Gates
- `flutter analyze` and `flutter test` in CI, escalated to `--fatal-infos --fatal-warnings` after Phase 1 W2 sweep
- Domain unit tests for core rules (`MoveValidator`, `LineClearService`, `ScoreService`, `PieceGenerationService`)
- Schema validation for analytics payloads (`AnalyticsSchemaValidator`)
- Smoke path validation on release candidates via `scripts/smoke_pack.ps1` across the device matrix
- Cold-kill recovery test: force process kill during gameplay → reopen → persisted snapshot restored
- Real billing sandbox test: purchase + restore + reinstall cycle for at least one cosmetic SKU
- Crashlytics dashboard: release builds produce real events within 10 minutes of install

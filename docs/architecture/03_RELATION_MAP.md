# System Relation Map

Last updated: 2026-04-12. Aligned with the Firebase-first decision in [../roadmap/01_ROADMAP_AND_SPRINTS.md](../roadmap/01_ROADMAP_AND_SPRINTS.md) and [02_ARCHITECTURE_MODULE_CATALOG.md](02_ARCHITECTURE_MODULE_CATALOG.md).

## 1. System Context
```mermaid
flowchart LR
  Player[Player] --> MobileApp[Mobile App\nFlutter + Flame]

  MobileApp --> FirebaseCore[Firebase Core]
  FirebaseCore --> Crashlytics[Crashlytics\ncrash + ANR]
  FirebaseCore --> Analytics[Firebase Analytics]
  FirebaseCore --> RemoteConfig[Remote Config\n+ A/B Testing]
  FirebaseCore --> Auth[Anonymous Auth]
  FirebaseCore --> FCM[Cloud Messaging]
  FirebaseCore --> Perf[Performance Monitoring]

  MobileApp --> Billing[Google Play Billing v7\n+ RuStore adapter]
  Billing --> VerifyFn[Cloud Function\nverifyPurchase]
  VerifyFn --> Firestore[(Firestore\nentitlements/uid)]

  Analytics --> BigQuery[(BigQuery Export)]
  BigQuery --> Looker[Looker Studio\nDashboards]
  Crashlytics --> AlertFn[Cloud Function\nalert_router]
  AlertFn --> Slack[Slack / Telegram]

  Looker --> ProductTeam[Product + Data Team]
  ProductTeam --> RemoteConfig
```

## 2. Client Internal Links
```mermaid
flowchart TD
  UI[UI Layer\nscreens + widgets] --> GameLoop[Feature: Game Loop]
  UI --> MetaProgression[Feature: Meta Progression]
  UI --> Cosmetics[Feature: Cosmetics Shop]
  UI --> Missions[Feature: Missions]
  UI --> Store[Feature: Store]
  UI --> Settings[Feature: Settings]

  GameLoop --> MoveValidator[Domain: MoveValidator]
  GameLoop --> LineClear[Domain: LineClearService]
  GameLoop --> Score[Domain: ScoreService]
  GameLoop --> Generator[Domain: PieceGenerationService]
  GameLoop --> Difficulty[Domain: DifficultyTuner]
  GameLoop --> Revive[Feature: Revive]

  MetaProgression --> ProgressRepo[Data: PlayerProgressRepository\nHive]
  Cosmetics --> ProgressRepo
  Missions --> ProgressRepo
  Store --> BillingSvc[Infra: IapStoreService]
  Store --> EntitlementSync[Infra: Entitlement Sync]

  Difficulty --> RemoteConfigRepo[Data: RemoteConfigRepository]
  GameLoop --> AnalyticsRepo[Data: AnalyticsTracker]
  GameLoop --> CrashReporter[Infra: CrashReporter]
  GameLoop --> HiveStorage[Data: Hive Storage]
```

## 3. Infra Adapters
```mermaid
flowchart LR
  RemoteConfigRepo[RemoteConfigRepository\ncontract] --> FirebaseRC[FirebaseRemoteConfigRepository]
  RemoteConfigRepo --> InMemoryRC[InMemoryRemoteConfigRepository\ndev-flavor]

  AnalyticsRepo[AnalyticsTracker\ncontract] --> FirebaseAT[FirebaseAnalyticsTracker]
  AnalyticsRepo --> DebugAT[DebugAnalyticsTracker\ndev-flavor]

  CrashReporter[CrashReporter\ncontract] --> FirebaseCR[FirebaseCrashReporter]
  CrashReporter --> NoopCR[NoopCrashReporter\ndev-flavor]

  BillingSvc[IapStoreService\ncontract] --> GooglePlay[GooglePlayBillingService]
  BillingSvc --> RuStore[RuStoreBillingService]
  BillingSvc --> LocalCat[LocalCatalogIapStoreService\ndev-flavor]
```

## 4. Event / Data Flow
```mermaid
sequenceDiagram
  participant P as Player
  participant A as App
  participant D as Domain
  participant RC as Firebase Remote Config
  participant FA as Firebase Analytics
  participant BQ as BigQuery
  participant LS as Looker Studio

  A->>RC: fetchAndActivate()
  RC-->>A: config snapshot + A/B assignments
  P->>A: drag and drop piece
  A->>D: validate and apply move
  D-->>A: board update + score + combo
  A->>FA: logEvent gameplay / ops events
  FA-->>BQ: nightly streaming export
  BQ-->>LS: materialized cohort metrics
```

## 5. Purchase + Entitlement Flow
```mermaid
sequenceDiagram
  participant P as Player
  participant A as App
  participant GP as Google Play Billing v7
  participant CF as Cloud Function verifyPurchase
  participant FS as Firestore entitlements/uid

  P->>A: Buy skin_aurora
  A->>GP: launchBillingFlow(sku)
  GP-->>A: PurchaseDetails
  A->>CF: POST verify(receipt, uid)
  CF->>GP: Google Play Developer API verify
  GP-->>CF: valid receipt
  CF->>FS: write entitlement
  CF-->>A: entitlement granted
  A->>A: unlock cosmetic + acknowledge
```

## 6. Store Personalization Chain (Phase 3 3C)
```mermaid
flowchart LR
  Snapshot[Player Snapshot\n+ wallet + level] --> Segment[Segment Resolver]
  Segment --> Strategy[Offer Strategy\nRemote Config variant]
  Strategy --> Catalog[Cosmetic Catalog Ordering]
  Catalog --> Recommendation[Recommended SKU]
  Recommendation --> Analytics[offer_targeting_exposure]
```

## 7. Control Points
- Before config apply: schema validation + fallback + `ops_config_invalid` on failure.
- Before gameplay state mutation: lifecycle phase gate + `_isDisposed` guard.
- Before crash is lost: `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.instance.onError` route to `CrashReporter`.
- Before purchase grants entitlement: Cloud Function `verifyPurchase` validates against Google Play Developer API.
- Before rollout increase: hard/soft gate evaluation from Looker Studio + [../operations/16_ROLLOUT_GATES_CHECKLIST_OPS_SIGNALS.md](../operations/16_ROLLOUT_GATES_CHECKLIST_OPS_SIGNALS.md).
- Before publish: smoke pack on device matrix + release pipeline checklist.

## 8. Deferred Integrations
- `services/config-api` — deferred in favor of Firebase Remote Config. Historical contract at [../../services/config-api/README.md](../../services/config-api/README.md).
- `services/analytics-pipeline` — deferred in favor of Firebase Analytics + BigQuery export. Historical contract at [../../services/analytics-pipeline/README.md](../../services/analytics-pipeline/README.md).

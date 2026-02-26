# System Relation Map

## 1. System Context
```mermaid
flowchart LR
  Player[Player] --> MobileApp[Mobile App\nFlutter + Flame]
  MobileApp --> ConfigAPI[Config API\nRemote Config + AB]
  MobileApp --> AnalyticsIngest[Analytics Ingestion]
  MobileApp --> StoreBilling[Store Billing / Entitlements]
  AnalyticsIngest --> BI[BI Dashboards]
  ConfigAPI --> BI
  BI --> ProductTeam[Product and Data Team]
  ProductTeam --> ConfigAPI
```

## 2. Client Internal Links
```mermaid
flowchart TD
  UI[UI Layer] --> GameLoop[Feature: Game Loop]
  GameLoop --> MoveValidator[Domain: MoveValidator]
  GameLoop --> LineClear[Domain: LineClearService]
  GameLoop --> Score[Domain: ScoreService]
  GameLoop --> Generator[Domain: PieceGenerationService]
  GameLoop --> Difficulty[Domain: DifficultyTuner]

  Difficulty --> RemoteConfigRepo[Data: Remote Config]
  GameLoop --> AnalyticsRepo[Data: Analytics]
  UI --> StoreFeature[Feature: Store]
  StoreFeature --> BillingAdapter[Adapter: Billing]
  UI --> LocalState[Data: Local Storage]
```

## 3. Event/Data Flow
```mermaid
sequenceDiagram
  participant P as Player
  participant A as App
  participant D as Domain
  participant RC as Config API
  participant E as Events API
  participant B as BI

  A->>RC: Fetch config + experiment assignments
  RC-->>A: config snapshot
  P->>A: drag and drop piece
  A->>D: validate and apply move
  D-->>A: board update + score + combo
  A->>E: emit gameplay and ops events
  E-->>B: aggregate cohort metrics
```

## 4. Store Personalization Chain
```mermaid
flowchart LR
  Snapshot[Player Snapshot] --> Segment[Segment Resolver]
  Segment --> Strategy[Offer Strategy Variant]
  Strategy --> Catalog[Catalog Ordering]
  Catalog --> Recommendation[Recommended SKU]
  Recommendation --> Analytics[offer_targeting_exposure]
```

## 5. Control Points
- Before config apply: schema validation + fallback.
- Before rollout increase: hard/soft gate evaluation.
- Before publish: smoke + release checks.

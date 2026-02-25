# Карта Связей Системы

## 1. System Context
```mermaid
flowchart LR
  Player[Игрок] --> MobileApp[Mobile App\nFlutter + Flame]
  MobileApp --> ConfigAPI[Config API\nRemote Config + A/B]
  MobileApp --> AnalyticsIngest[Analytics Ingestion]
  MobileApp --> AdNetworks[Ad Networks]
  MobileApp --> IAPStore[App Store / Play Billing]
  AnalyticsIngest --> BI[BI Dashboards]
  ConfigAPI --> BI
  BI --> ProductTeam[Product/Data Team]
  ProductTeam --> ConfigAPI
```

## 2. Внутренние связи клиента
```mermaid
flowchart TD
  UI[UI Layer] --> GameLoop[Feature: Game Loop]
  GameLoop --> MoveValidator[Domain: MoveValidator]
  GameLoop --> LineClear[Domain: LineClearService]
  GameLoop --> Score[Domain: ScoreService]
  GameLoop --> Generator[Domain: PieceGenerationService]
  GameLoop --> Difficulty[Domain: DifficultyTuner]

  Difficulty --> RemoteConfigRepo[Data: RemoteConfigRepo]
  GameLoop --> AnalyticsRepo[Data: AnalyticsRepo]
  GameLoop --> Monetization[Feature: Monetization]
  Monetization --> AdAdapter[SDK Adapter: Ads]
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

  A->>RC: Fetch config + AB assignments
  RC-->>A: difficulty/ad flags
  P->>A: drag & drop piece
  A->>D: validate + apply move
  D-->>A: board update + score + combo
  A->>E: emit move_made/game_state events
  A->>A: optional ad trigger by policy
  E-->>B: aggregated KPIs
```

## 4. Monetization decision chain
```mermaid
flowchart LR
  Trigger[Game Trigger\nGameOver/MenuReturn/Hint] --> Policy[Ad Policy Resolver]
  Policy --> Guardrails[Guardrails\nfrequency cap\nretention-safe]
  Guardrails -->|allow| ShowAd[Show Ad]
  Guardrails -->|deny| SkipAd[Skip Ad]
  ShowAd --> RewardFlow[Reward / Resume Flow]
  RewardFlow --> Analytics[ad_impression/ad_rewarded]
```

## 5. Зоны ответственности
- Gameplay zone: игровая логика и UX.
- Monetization zone: правила показа и ad adapters.
- Data zone: аналитические события, схемы, агрегация.
- Experimentation zone: remote config, feature flags, AB assignments.

## 6. Критичные точки контроля
- Перед любым ad показом: проверка guardrails.
- Перед применением config: schema validation + fallback.
- Перед выпуском: smoke сценарии полного игрового цикла.

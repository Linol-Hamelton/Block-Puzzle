# Архитектура и Каталог Модулей

## 1. Клиентская архитектура (Flutter + Flame)

### 1.1 Layering
1. Presentation Layer (Flutter widgets/screens)
2. Application Layer (use-cases, orchestration, state coordination)
3. Domain Layer (чистая логика игры)
4. Infrastructure/Data Layer (storage, network, sdk adapters)

### 1.2 Ключевые модули и роли
| Модуль | Ответственность | Вход | Выход |
|---|---|---|---|
| `domain/gameplay/board` | состояние поля, размещение фигур | текущий board + move | новый board state |
| `domain/generator` | генерация тройки фигур по правилам сложности | session context + config | 3 фигуры |
| `domain/scoring` | очки, комбо, бонусы | результат хода | score delta + combo state |
| `features/game_loop` | orchestration раунда | UI input + domain services | обновленный игровой state |
| `features/monetization` | триггеры рекламы, anti-spam капы | game events + config | ad request / no-op |
| `data/analytics` | сбор, буферизация, отправка событий | typed events | batched payload |
| `data/remote_config` | загрузка и кеш конфигурации | app launch / refresh | active config snapshot |

## 2. Серверная архитектура (минимально необходимая)

### 2.1 `services/config-api`
- хранение feature flags;
- remote config для сложности, туториала, ad pressure;
- deterministic assignment пользователя в A/B группы;
- аудит изменений конфигов.

### 2.2 `services/analytics-pipeline`
- прием клиентских событий;
- schema validation;
- enrichment (geo, app version, cohort keys);
- агрегаты для retention/ARPDAU/LTV;
- выгрузка в BI.

## 3. API контракты (черновая форма)

### 3.1 Remote Config
- `GET /v1/config?app_version=&platform=&user_id=`
- Ответ:
  - `config_version`
  - `difficulty_profile`
  - `ad_policy`
  - `feature_flags`
  - `ab_assignments`

### 3.2 Event Ingestion
- `POST /v1/events/batch`
- Payload:
  - `app_instance_id`
  - `sent_at`
  - `events[]` (name, ts, params, schema_version)

## 4. Domain Contracts (без реализации)
- `MoveValidator.validate(board, piece, position) -> ValidationResult`
- `LineClearService.apply(board) -> LineClearResult`
- `ScoreService.calculate(moveResult, comboState) -> ScoreState`
- `PieceGenerationService.nextTriplet(context, config) -> PieceTriplet`
- `DifficultyTuner.resolve(context, remoteConfig) -> DifficultyProfile`

## 5. Архитектурные ADR (что фиксируем сразу)
1. ADR-001: Flutter + Flame как базовый стек.
2. ADR-002: Чистая domain-логика отдельно от SDK.
3. ADR-003: Все параметры монетизации и сложности через remote config.
4. ADR-004: Mandatory event contracts с валидацией схем.
5. ADR-005: Experiment-first delivery (каждая крупная фича включается флагом).

## 6. Набор инженерных quality gates
- Линт и формат обязательны для PR.
- Unit tests для domain логики.
- Contract tests для event schema и config schema.
- Smoke integration сценарий: launch -> play -> game over -> ad flow -> restart.

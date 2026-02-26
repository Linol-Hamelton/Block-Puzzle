# Architecture Module Catalog

## 1. Client Architecture (Flutter + Flame)
Layering:
1. Presentation layer (screens/widgets)
2. Application layer (controllers/use-case orchestration)
3. Domain layer (pure gameplay logic)
4. Data/infra layer (storage, remote config, analytics adapters)

## 2. Core Modules
| Module | Responsibility | Input | Output |
|---|---|---|---|
| `domain/gameplay` | board state, move validity, line clear | board + move | updated board/result |
| `domain/generator` | piece generation and pressure tuning | session + config | rack pieces |
| `domain/scoring` | score/combo calculations | move/clear result | score delta |
| `features/game_loop` | runtime orchestration | user input + services | renderable state |
| `features/store` | catalog, entitlement, purchase flow | config + ownership | offers + purchase results |
| `data/analytics` | typed tracking and validation | event payloads | logged/exported events |
| `data/remote_config` | config snapshot and fallback | app lifecycle | typed config values |

## 3. Backend/Service Contracts (Planned/External)
### `services/config-api`
- remote config distribution
- feature flags and AB assignments
- config change audit

### `services/analytics-pipeline`
- event ingestion and schema validation
- cohort aggregations
- BI-facing outputs

## 4. Domain Contracts (Current)
- `MoveValidator`
- `LineClearService`
- `ScoreService`
- `PieceGenerationService`
- `DifficultyTuner`

## 5. ADR Baseline
1. Flutter + Flame remains primary client stack.
2. Domain logic stays SDK-independent.
3. Runtime tuning is config-driven.
4. Event contracts are versioned and validated.
5. Feature rollout is flag/experiment driven.

## 6. Quality Gates
- lint + tests in CI
- domain unit tests for core rules
- schema validation for analytics payloads
- smoke path validation on release candidates

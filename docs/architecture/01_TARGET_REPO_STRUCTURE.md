# Целевая Структура Репозитория

## 1. Назначение
Структура должна позволять:
- быстро развивать MVP;
- безопасно масштабировать продукт;
- разделять ответственности между gameplay, data, monetization, operations.

## 2. Дерево каталогов (target)
```text
Block-Puzzle/
├─ README.md
├─ docs/
│  ├─ product/
│  ├─ architecture/
│  ├─ operations/
│  └─ roadmap/
├─ apps/
│  └─ mobile/
│     ├─ lib/
│     │  ├─ app/
│     │  ├─ core/
│     │  │  ├─ config/
│     │  │  ├─ logging/
│     │  │  ├─ storage/
│     │  │  └─ network/
│     │  ├─ domain/
│     │  │  ├─ gameplay/
│     │  │  ├─ scoring/
│     │  │  ├─ generator/
│     │  │  └─ session/
│     │  ├─ features/
│     │  │  ├─ game_loop/
│     │  │  ├─ onboarding/
│     │  │  ├─ meta_progression/
│     │  │  ├─ monetization/
│     │  │  └─ settings/
│     │  ├─ data/
│     │  │  ├─ repositories/
│     │  │  ├─ analytics/
│     │  │  └─ remote_config/
│     │  └─ ui/
│     │     ├─ theme/
│     │     ├─ screens/
│     │     └─ widgets/
│     ├─ assets/
│     │  ├─ audio/
│     │  ├─ sprites/
│     │  ├─ shaders/
│     │  └─ themes/
│     └─ test/
│        ├─ unit/
│        ├─ widget/
│        └─ integration/
├─ services/
│  ├─ config-api/
│  └─ analytics-pipeline/
├─ infra/
│  ├─ env/
│  ├─ iac/
│  └─ ci/
└─ data/
   ├─ schemas/
   ├─ dictionaries/
   └─ dashboards/
```

## 3. Правила зависимостей
- `domain` не зависит от `ui` и `sdk`.
- `features` зависят от `domain` через use-cases/interfaces.
- `data` реализует интерфейсы, определенные в `domain`.
- `ui` зависит от `features` и presentation contracts.
- Любой внешний SDK подключается через adapter pattern.

## 4. Каталогизация по ownership
- Gameplay Team: `apps/mobile/lib/domain/*`, `features/game_loop`.
- Client Platform Team: `apps/mobile/lib/core/*`, `ui/theme`.
- Data/Product Team: `apps/mobile/lib/data/analytics`, `services/analytics-pipeline`, `data/schemas`.
- Monetization Team: `features/monetization`, `services/config-api` (ad configs, flags).
- DevOps: `infra/*`.

## 5. Версионирование артефактов
- Docs: semver-like тэги `v0.x` до global launch.
- Config schemas: обязательное поле `schema_version`.
- Event contracts: backward-compatible эволюция, депрекейт через grace period.

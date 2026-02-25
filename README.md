# Block Puzzle - Top 1 Preparation Pack

Этот репозиторий содержит стартовый пакет pre-production для мобильной F2P игры в жанре block puzzle (ориентир: Block Blast-подобный core-loop) с фокусом на:
- максимальную коммерциализацию без разрушения UX;
- "гипнотический" геймплей (быстрый цикл, мощный визуальный/аудио фидбек, высокий повторный запуск);
- масштабируемую архитектуру (MVP -> Soft Launch -> Global Scale).

Полный код проекта здесь специально не реализован. В репозитории заложены структура, архитектура, каталогизация, карта связей, подробное ТЗ и дорожная карта.

## Документация
- [Product Vision и KPI](docs/product/01_PRODUCT_VISION_KPI.md)
- [Подробное Техническое ТЗ](docs/product/02_TECHNICAL_REQUIREMENTS_SPEC.md)
- [UI/UX и Art Direction](docs/design/01_UI_UX_ART_DIRECTION.md)
- [Целевая Структура Репозитория](docs/architecture/01_TARGET_REPO_STRUCTURE.md)
- [Архитектура и Каталог Модулей](docs/architecture/02_ARCHITECTURE_MODULE_CATALOG.md)
- [Карта Связей Системы](docs/architecture/03_RELATION_MAP.md)
- [Спека Аналитики, A/B и Монетизации](docs/operations/01_ANALYTICS_AB_MONETIZATION_SPEC.md)
- [Риски и Guardrails](docs/operations/02_RISKS_GUARDRAILS.md)
- [Internal Playtest Protocol](docs/operations/03_INTERNAL_PLAYTEST_PROTOCOL.md)
- [Internal Playtest Run 001 Report](docs/operations/04_INTERNAL_PLAYTEST_RUN_001_REPORT.md)
- [Run 002 Input Template](docs/operations/05_RUN_002_INPUT_TEMPLATE.md)
- [QA Smoke Pack v1](docs/operations/06_QA_SMOKE_PACK_V1.md)
- [GitHub Actions Build Setup](docs/operations/07_GITHUB_ACTIONS_SETUP.md)
- [Roadmap и Sprint Backlog](docs/roadmap/01_ROADMAP_AND_SPRINTS.md)
- [Чеклист Этапа 0](docs/roadmap/02_PHASE0_CHECKLIST.md)
- [Sprint 1 Issue-Ready Backlog](docs/roadmap/03_SPRINT1_ISSUE_READY_BACKLOG.md)
- [Sprint 1 GitHub Issues](docs/roadmap/04_SPRINT1_GITHUB_ISSUES.md)

## Каркас Репозитория
- `apps/mobile` - Flutter + Flame клиент (игра, UI, оффлайн слой, SDK интеграции).
- `services/config-api` - сервис remote config, feature flags и A/B распределения.
- `services/analytics-pipeline` - ingestion, валидация, агрегации событий и витрины метрик.
- `infra` - IaC, окружения, CI/CD, секреты, observability.
- `data` - схемы событий, словари, контрактные спецификации.

## Стартовые Принципы
- Архитектурно отделяем `core gameplay` от `monetization/experimentation`, чтобы быстро тестировать гипотезы без риска регрессий в gameplay.
- Любое усиление рекламы проходит guardrails по retention и session quality.
- Каждая продуктовая гипотеза должна иметь ожидаемый KPI uplift, план эксперимента и критерий остановки.

## Быстрый Запуск Smoke Pack
```powershell
.\scripts\mobile_smoke_pack_v1.ps1
```
Артефакты после прогона:
- `artifacts/block-puzzle-internal-debug.apk`
- `artifacts/block-puzzle-web-build-YYYY-MM-DD.zip`

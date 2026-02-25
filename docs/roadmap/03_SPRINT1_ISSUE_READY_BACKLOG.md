# Sprint 1 - Issue-Ready Backlog (2 недели)

## 1. Sprint Goal
Собрать рабочий технический фундамент gameplay-цикла и измеримости:
- scaffold приложения и модульные границы;
- доменные контракты core-loop;
- первичная телеметрия и config-ready каркас;
- прототип игрового экрана с Flame.

## 2. Definition of Done для Sprint 1
- Проект собирается на Android/iOS/Web.
- `flutter analyze` без ошибок.
- Smoke тесты проходят.
- Каркас core домена и DI внедрен.
- Подготовлен базовый аналитический event layer.

## 3. DEV Issues

### DEV-01: Project bootstrap + dependency baseline
- Type: `task`
- Owner: `Mobile Engineer`
- Estimate: `5 SP`
- Priority: `P0`
- Description: закрепить рабочий Flutter+Flame scaffold и базовые зависимости.
- Checklist:
  - [ ] Проверить сборку всех target platforms.
  - [ ] Зафиксировать версии `flame`, `get_it`, lint tooling.
  - [ ] Настроить базовый app shell (`main -> bootstrap -> app`).
  - [ ] Обновить `apps/mobile/README` с правилами запуска.
- Acceptance criteria:
  - [ ] `flutter analyze` без issue.
  - [ ] `flutter test` проходит.
  - [ ] Приложение стартует и открывает home экран.

### DEV-02: Domain contracts for core gameplay
- Type: `task`
- Owner: `Gameplay Engineer`
- Estimate: `8 SP`
- Priority: `P0`
- Description: создать контракты доменной логики без полной реализации.
- Checklist:
  - [ ] `BoardState`, `Piece`, `Move`, `ValidationResult`.
  - [ ] Интерфейсы `MoveValidator`, `LineClearService`.
  - [ ] Интерфейсы `ScoreService`, `PieceGenerationService`, `DifficultyTuner`.
  - [ ] `SessionState` и базовые структуры состояния.
- Acceptance criteria:
  - [ ] Контракты не зависят от UI/SDK.
  - [ ] Есть unit tests на базовые инварианты моделей.

### DEV-03: DI container + stub implementations
- Type: `task`
- Owner: `Platform Engineer`
- Estimate: `5 SP`
- Priority: `P0`
- Description: внедрить DI и заглушечные реализации сервисов для безопасной эволюции.
- Checklist:
  - [ ] Добавить `GetIt` service locator.
  - [ ] Зарегистрировать core сервисы, remote config repo, analytics tracker.
  - [ ] Добавить stub implementations domain сервисов.
  - [ ] Подключить DI в bootstrap.
- Acceptance criteria:
  - [ ] Все зависимости резолвятся при старте.
  - [ ] Есть smoke тест на запуск приложения.

### DEV-04: Flame game screen skeleton
- Type: `task`
- Owner: `Gameplay Engineer`
- Estimate: `5 SP`
- Priority: `P1`
- Description: добавить рабочий игровой экран с `FlameGame` без финальной геймплейной логики.
- Checklist:
  - [ ] `GameLoopScreen` с `GameWidget`.
  - [ ] `BlockPuzzleGame` инициализирует `GameLoopController`.
  - [ ] Хук для дальнейшего подключения компонентов доски/фигур.
  - [ ] Навигация Home -> GameLoop.
- Acceptance criteria:
  - [ ] Экран игры открывается без падений.
  - [ ] Контроллер получает init lifecycle.

### DEV-05: Telemetry base layer (client side)
- Type: `task`
- Owner: `Data/Mobile Engineer`
- Estimate: `5 SP`
- Priority: `P1`
- Description: подготовить typed интерфейс трекинга событий и debug-реализацию.
- Checklist:
  - [ ] Интерфейс `AnalyticsTracker`.
  - [ ] Debug трекер.
  - [ ] Точка вызова `game_loop_initialized`.
  - [ ] Подготовка к offline queue (контракт).
- Acceptance criteria:
  - [ ] События логируются в debug режиме.
  - [ ] API трекера готово к замене на SDK.

## 4. ART Issues

### ART-01: Graybox visual kit for prototype
- Type: `task`
- Owner: `UI/UX Artist`
- Estimate: `5 SP`
- Priority: `P0`
- Description: подготовить минимальный набор временных визуалов для playtest.
- Checklist:
  - [ ] Сетка поля 8x8 (neutral style).
  - [ ] 8-12 форм блоков в graybox стиле.
  - [ ] Базовые цвета для valid/invalid preview.
  - [ ] Простые иконки HUD (score, combo placeholder).
- Acceptance criteria:
  - [ ] Ассеты читаемы на small/large экранах.
  - [ ] Нет визуального конфликта с touch зонами.

### ART-02: Motion references and feedback direction
- Type: `task`
- Owner: `Motion Designer`
- Estimate: `3 SP`
- Priority: `P1`
- Description: собрать пакет референсов по анимациям очистки линии и combo escalation.
- Checklist:
  - [ ] 2-3 референса line clear.
  - [ ] 2 референса combo buildup.
  - [ ] 1 референс game over драматургии.
  - [ ] Предложить timing ranges для v1.
- Acceptance criteria:
  - [ ] Референсы утверждены Product + Game Design.
  - [ ] Внесены в `docs/design`.

## 5. PRODUCT Issues

### PROD-01: Core-loop spec freeze v1
- Type: `task`
- Owner: `Product Manager`
- Estimate: `3 SP`
- Priority: `P0`
- Description: заморозить правила core-loop для Sprint 1-2, чтобы убрать двусмысленность.
- Checklist:
  - [ ] Поле, набор фигур, условие game over.
  - [ ] Принципы score/combo на MVP.
  - [ ] Ограничения UX (быстрый restart, no friction flow).
  - [ ] Документирован out-of-scope для MVP.
- Acceptance criteria:
  - [ ] Все dev задачи имеют однозначные acceptance criteria.

### PROD-02: KPI instrumentation map v1
- Type: `task`
- Owner: `Product Analyst`
- Estimate: `5 SP`
- Priority: `P0`
- Description: утвердить минимальный набор событий и метрик для первых когорт.
- Checklist:
  - [ ] Event list + required params.
  - [ ] Mapping событий к KPI (D1 proxy, early churn, round quality).
  - [ ] Правила именования и schema versioning.
  - [ ] Owner и cadence проверки данных.
- Acceptance criteria:
  - [ ] Документ согласован с data и mobile.
  - [ ] Есть план валидации после деплоя.

## 6. DATA Issues

### DATA-01: Event schema draft + validation rules
- Type: `task`
- Owner: `Data Engineer`
- Estimate: `5 SP`
- Priority: `P0`
- Description: подготовить схемы событий v1 и правила валидации ingestion.
- Checklist:
  - [ ] JSON schema draft для ключевых событий.
  - [ ] Required/optional fields.
  - [ ] Ошибки схемы -> quarantine policy.
  - [ ] Версионирование `schema_version`.
- Acceptance criteria:
  - [ ] Схемы покрывают `session_start`, `game_start`, `move_made`, `game_end`.
  - [ ] Документированы примеры payload.

### DATA-02: Dashboard wireframe (retention + monetization)
- Type: `task`
- Owner: `Product Analyst`
- Estimate: `3 SP`
- Priority: `P1`
- Description: набросать каркас первой витрины метрик для soft launch readiness.
- Checklist:
  - [ ] Retention cohort block.
  - [ ] Session quality block.
  - [ ] Ad performance block.
  - [ ] Experiment monitoring placeholder.
- Acceptance criteria:
  - [ ] Wireframe утвержден Product.
  - [ ] Есть перечень источников данных.

## 7. Sprint Risks
- Недооценка времени на baseline performance.
- Размытые критерии качества раннего gameplay feel.
- Неполные аналитические события в первой сборке.

## 8. Sprint Exit Checklist
- [ ] Все P0 задачи закрыты.
- [ ] Нет критических блокеров на Sprint 2.
- [ ] Подготовлен demo build для internal playtest.
- [ ] Сформирован backlog refinement для Sprint 2.

# Подробная Дорожная Карта и Sprint Backlog

## 1. Этапы продукта
1. Этап 0 (2-4 недели): прототип и фундамент.
2. Этап 1 (6-8 недель): MVP и подготовка soft launch.
3. Этап 2 (2-3 месяца): soft launch, оптимизация retention и ad stack.
4. Этап 3 (3-6 месяцев): масштабирование, новые режимы, метагейм.
5. Этап 4 (ongoing): LiveOps фабрика экспериментов.

## 2. План на первые 16 недель (8 спринтов по 2 недели)

### Sprint 1
- Архитектурный каркас Flutter+Flame.
- Доменные модели board/piece/move/score.
- Прототип drag&drop и валидация хода.
- События `session_start`, `game_start`, `move_made`.

### Sprint 2
- Очистка линий, combo, game over, restart.
- Базовый HUD и экран результатов.
- Локальное сохранение рекорда.
- Unit tests для domain rules.

### Sprint 3
- Core-loop polish: базовые эффекты и звук.
- Onboarding v1 (guided first game).
- Remote config клиент + fallback.
- ad adapters (только заглушки/интерфейсы).

### Sprint 4
- Интеграция Banner + Interstitial + Rewarded revive.
- События рекламы и валидация схем.
- Performance pass (assets, draw calls, memory).
- QA smoke pack v1.

### Sprint 5
- Soft launch readiness build.
- A/B framework v1 (tutorial variant + ad cap variant).
- Dashboard MVP (retention, session, ad metrics).
- Bugfix и stability hardening.

### Sprint 6
- Дневные цели + streak система.
- Rewarded hint/undo.
- Первая волна UX/Balance A/B tests.
- Тонкая настройка генератора фигур.

### Sprint 7
- IAP ad-free + cosmetic starter pack.
- Сегментация пользователей и offer targeting v1.
- Улучшение end-of-round UX и social loop (share score optional).
- Observability и alerting upgrade.

### Sprint 8
- Soft launch iteration #2.
- Rollout победивших экспериментов.
- План расширения в новые GEO.
- Pre-production дизайн пакета Этапа 3.

## 3. Роли и ownership по спринтам
- Product Manager: гипотезы, KPI, приоритизация.
- Game Client Engineer: core gameplay, performance, UI integration.
- Backend/Data Engineer: config API, events pipeline, dashboards.
- UA/Monetization Manager: ad strategy, mediation roadmap, pricing IAP.
- Game Designer: difficulty curve, loop tuning, balance.
- UI/UX + Motion Artist: визуальный стиль, juice эффект, clarity.
- QA Engineer: smoke/regression + device matrix.

## 4. KPI-гейты перехода между этапами
- Этап 0 -> 1: core-loop стабилен, crash-free >= 99%.
- Этап 1 -> 2: MVP готов, ключевые события валидны, ad stack работает без критических UX потерь.
- Этап 2 -> 3: подтвержден product-market signal в soft launch (retention+ARPDAU в целевом коридоре).
- Этап 3 -> 4: масштабируемая liveops и experiment cadence, стабильный KPI тренд.

## 5. Бэклог-группы для постоянной работы
1. Gameplay Quality: fairness, combo fun, late-game decisions.
2. Monetization Efficiency: placement tuning, mediation, rewarded value design.
3. Retention Systems: goals, streak, meta progression, seasonal events.
4. Tech Platform: perf, reliability, test automation, release velocity.
5. Data Excellence: schema quality, dashboards, experiment governance.

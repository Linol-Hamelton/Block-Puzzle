# Спецификация Аналитики, A/B и Монетизации

## 1. Цель
Обеспечить управляемый рост retention и ARPDAU через стандартизированные события, контролируемые эксперименты и не-токсичную ad политику.

## 2. Event Taxonomy (v1)
| Event | Когда отправлять | Обязательные параметры |
|---|---|---|
| `session_start` | старт сессии | session_id, app_version, platform, ab_bucket |
| `session_end` | конец сессии | session_id, duration_sec, rounds_played |
| `game_start` | старт раунда | round_id, mode, config_version |
| `move_made` | каждый валидный ход | round_id, piece_type, lines_cleared, combo_index, board_fill_pct |
| `game_end` | окончание раунда | round_id, end_reason, score, duration_sec |
| `ad_impression` | факт показа рекламы | placement, ad_type, network, eCPM(if available) |
| `ad_rewarded` | факт выдачи награды | reward_type, reward_value |
| `iap_purchase` | успешная покупка | sku, price, currency, country |
| `tutorial_step` | шаг туториала | step_id, status, dropoff_reason |
| `ab_exposure` | вход пользователя в эксперимент | experiment_id, variant_id, assignment_ts |

## 3. Data Contract Rules
- Все события имеют `schema_version`.
- Неизвестные параметры не ломают ingestion, но помечаются warning.
- Обязательные поля отсутствуют -> событие в quarantine stream.
- Время события всегда в UTC + device timestamp.

## 4. A/B Framework

### 4.1 Обязательные поля эксперимента
- `experiment_id`
- `hypothesis`
- `primary_metric`
- `secondary_metrics`
- `guardrails`
- `target_population`
- `sample_ratio`
- `start_criteria`
- `stop_criteria`

### 4.2 Приоритеты тестов
1. Gameplay retention tests (сложность, генератор фигур).
2. Onboarding tests.
3. Monetization pressure tests.
4. Visual/theme tests.

### 4.3 Стоп-критерии
- D1 падает > 2 п.п. против контроля.
- Crash rate растет > 0.3 п.п.
- Session length падает > 10% при незначимом росте ARPDAU.

## 5. Монетизация (v1 -> v2)

### 5.1 Плейсменты v1
- Banner: ограниченные экраны, без перекрытия критичного UI.
- Interstitial: конец раунда/выход в меню, минимум 1 ad-free cooldown между показами.
- Rewarded: revive, hint/undo, optional bonus.

### 5.2 Плейсменты v2
- Dynamic offer walls (только после проверки на retention impact).
- Персонализированные rewarded offers по сегментам.
- Cross-promo в low-pressure слотах.

### 5.3 Guardrails для ad pressure
- Не более X interstitial за N минут (значение через remote config).
- Не показывать interstitial при первых Y раундах нового игрока.
- Rewarded только opt-in.

## 6. KPI Dashboard Blocks
- Cohort retention (D1/D3/D7/D14/D30).
- Session metrics (length, frequency, abort rate).
- Monetization (ARPDAU, impressions/DAU, rewarded opt-in, fill rate).
- Gameplay health (avg lines cleared, game_over cause distribution, difficulty pain index).
- Experiment outcomes (uplift, confidence, guardrail violations).

## 7. Основные продуктовые сегменты
- New users (0-2 дня)
- Early retained (3-7 дней)
- Mid-term retained (8-30 дней)
- Whales / high ad-engagers
- At-risk churn users

## 8. Минимальный cadence управления
- Ежедневно: KPI pulse + критические алерты.
- Еженедельно: experiment readout + roadmap reprioritization.
- Ежемесячно: экономика, UA/LTV коррекция, content/liveops план.

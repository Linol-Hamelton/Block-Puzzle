# Риски и Guardrails

## 1. Ключевые риски
1. Агрессивная реклама ломает retention.
2. Плохой генератор фигур вызывает ощущение "игра жульничает".
3. Неточность аналитики -> ошибочные продуктовые решения.
4. Производительность на слабых Android снижает D1.
5. Отсутствие системного LiveOps приводит к стагнации после soft launch.

## 2. Риск-матрица (высокий приоритет)
| Риск | Вероятность | Влияние | Митигирующие действия |
|---|---|---|---|
| Ad pressure overload | High | High | cap + A/B + guardrails + early-user protection |
| Generator unfairness | Medium | High | explainable tuning + telemetry + fairness constraints |
| Event schema drift | Medium | High | versioned schema + contract tests + quarantine stream |
| FPS drop on low devices | High | Medium | perf budget + profiling + asset compression |
| Content fatigue | Medium | Medium | roadmap liveops, seasonal drops, streak updates |

## 3. Guardrails
- Retention Guardrail: никакая ad-гипотеза не катится в 100% rollout при падении D1 > 2 п.п.
- Stability Guardrail: crash-free sessions < 99.5% блокирует релиз.
- Gameplay Guardrail: рост `early_game_over_rate` > 10% требует rollback генератора.
- UX Guardrail: рост tutorial drop-off > 8% требует пересмотра onboarding.
- Revenue Guardrail: рост ARPDAU за счет >15% session churn считается невалидным uplift.

## 4. Операционная модель rollback
1. Детект: мониторинг сигнализирует отклонение.
2. Верификация: data + product сверяют влияние по сегментам.
3. Решение: instant rollback флагом или patch release.
4. Постмортем: причина, prevention action, owner, deadline.

## 5. Release readiness gates
- QA: smoke + regression pass.
- Data: валидность ключевых событий подтверждена.
- Product: определены success metric и stop criteria.
- Ops: включены алерты на crash, retention proxy, ad anomalies.
- Legal/Privacy: политики и consent flow проверены.

## 6. Anti-patterns (запрещено)
- Увеличивать ad frequency без эксперимента.
- Изменять генератор сложности без телеметрии.
- Выпускать фичи без remote kill-switch.
- Внедрять cosmetics магазин без базовой экономики и SKU аналитики.

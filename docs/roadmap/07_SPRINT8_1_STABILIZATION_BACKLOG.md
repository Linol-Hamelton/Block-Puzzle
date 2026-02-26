# Sprint 8.1 Stabilization Backlog (10 рабочих дней)

## 1. Цель спринта
Зафиксировать стабильную release-версию `Lumina Blocks` перед масштабированием:
1. закрыть критичные баги и визуальные регрессии,
2. подтвердить качество на device-matrix,
3. провести rollout-gates по реальным когортным данным,
4. подготовить Go/No-Go пакет для публикации и управляемого rollout.

## 2. Входные условия
1. Текущее состояние: [05_IMPLEMENTATION_STATUS.md](/d:/Block-Puzzle/docs/roadmap/05_IMPLEMENTATION_STATUS.md)
2. Публикация: [03_PUBLISH_EXECUTION_CHECKLIST.md](/d:/Block-Puzzle/docs/release/03_PUBLISH_EXECUTION_CHECKLIST.md)
3. Gate-loop: [15_SOFT_LAUNCH_ITERATION_002_LOOP.md](/d:/Block-Puzzle/docs/operations/15_SOFT_LAUNCH_ITERATION_002_LOOP.md)

## 3. План по дням
| День | Dev | QA | Product/Data | Design/Art | Ops/Release | Артефакт дня |
|---|---|---|---|---|---|---|
| D1 | Freeze ветки stabilization, triage backlog P0/P1 | Подготовка тест-матрицы устройств и чек-листа smoke/regression | Freeze KPI/gates окна | Freeze визуальных токенов для текущей версии | Freeze release calendar | `stabilization_scope_v1` |
| D2 | Исправление P0 crash/soft-lock | Smoke pass #1 | Проверка валидности ключевых событий | Проверка визуальных дефектов критичности P0 | Проверка CI статуса | `bugfix_batch_p0_01` |
| D3 | Исправление P1 gameplay/UX блокеров | Регрессия drag/placement/hit-area | Проверка `ops_*` событий в выборке | Список UX косметических фиксов low-risk | Сбор логов build health | `qa_regression_report_d3` |
| D4 | Perf pass: draw/frame hotspots, memory spikes | FPS/thermal тест на low-mid Android | Обновление baseline метрик производительности | Визуальная верификация после perf pass | Подготовка RC build profile | `perf_profile_snapshot_d4` |
| D5 | Финализация telemetry hooks/edge cases | Валидация схем событий на тестовых сессиях | Сбор run-window #1 (реальные пользователи) | Контроль читаемости HUD/контраста | Экспорт dashboard snapshot #1 | `cohort_window_01.json` |
| D6 | Применение tuned config по run-window #1 | Проверка на регрессии после tuning | Запуск rollout gates #1 | Проверка визуальных побочек от tuning | Решение по rollout step (`10%`/`hold`) | `rollout_gates_report_w1` |
| D7 | Исправление критичных замечаний из window #1 | Smoke pass #2 | Сбор run-window #2 | Визуальный контроль стабильности UI на разных DPI | Подготовка RC release build | `release_candidate_rc1` |
| D8 | Блокеры по RC1 (если есть) | Full regression (phone+tablet) | Rollout gates #2 + сравнение окон | Финальный visual sign-off | Подготовка store submission пакета | `go_no_go_draft` |
| D9 | Release candidate финал | Санити-проверка финального APK/AAB | Product sign-off метрик и guardrails | Final marketing visual sanity | Upload + moderation submit (если Go) | `submission_packet_v1` |
| D10 | Post-release hotfix readiness | Пост-релизный smoke на прод-сборке | Первое окно post-submission мониторинга | Быстрые правки store creatives при необходимости | Итоговый retro и решение по Sprint 9 старту | `stabilization_retro_v1` |

## 4. Hard Gates (обязательные)
1. `flutter analyze` и `flutter test` без блокирующих ошибок.
2. `ops_alert_critical_count = 0` в окне принятия решения.
3. Нет P0/P1 багов со статусом `open`.
4. Crash-free и ANR не выходят за целевые пороги.

## 5. Definition of Done
1. Есть релизный билд-кандидат и подтвержденная QA матрица.
2. Есть минимум 2 последовательных окна cohort-метрик с принятым решением rollout.
3. Подготовлен и утвержден пакет публикации (тех + продукт + контент).
4. Есть post-release monitoring plan на первые 72 часа.

## 6. План отката
1. При провале hard gate: `hold_and_iterate`, без расширения rollout.
2. Instant rollback через remote config на предыдущие стабильные значения.
3. При runtime регрессии: hotfix ветка + повторный QA smoke и gates.

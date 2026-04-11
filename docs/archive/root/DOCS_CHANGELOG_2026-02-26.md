# DOCS_CHANGELOG_2026-02-26

## Scope
Документ фиксирует изменения по документации после полного reconciliation-прохода: синхронизация планов/ТЗ/релизных инструкций с текущей реализацией проекта.

## Matrix: file -> что было -> что стало -> почему
| Файл | Что было | Что стало | Почему |
|---|---|---|---|
| `README.md` | Устаревший scaffold-контекст, mojibake, старые артефакты | Актуальный hub по `Lumina Blocks`, текущие артефакты и source-of-truth правило | Убрать противоречия и сделать единый вход в документацию |
| `apps/mobile/README.md` | Описание как "scaffold", без полной логики | Описание реально реализованного клиента (core loop, AB, ops hooks, build matrix) | Привести readme к фактическому состоянию кода |
| `apps/mobile/assets/README.md` | Этап-0 заглушки | Актуальное описание структуры ассетов и статуса placeholders | Ясность по текущему состоянию ассетов |
| `apps/mobile/assets/audio/README.md` | Временные аудио notes | Уточнённый production-safe internal статус и правила замены | Зафиксировать текущий SFX baseline |
| `apps/mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | Шаблон Flutter iOS | Короткая пометка про Android-first scope | Убрать двусмысленность по iOS-фазе |
| `apps/mobile/lib/README.md` | Общий placeholder про будущую реализацию | Актуальная карта модулей `lib` | Связать структуру папки с реальным кодом |
| `apps/mobile/test/README.md` | Общий placeholder | Актуальная структура test-suite и команда запуска | Стандартизировать вход для тестирования |
| `data/README.md` | Краткий общий текст | Актуальный контрактный контур dashboards/run-metrics | Зафиксировать data как source-of-truth для ops скриптов |
| `infra/README.md` | Этап-0 организационный каркас | Актуализировано под текущий CI/release процесс | Убрать устаревший stage-0-only контекст |
| `services/config-api/README.md` | Этап-0 API draft | Явная граница сервиса + текущий in-memory режим на клиенте | Синхронизация архитектуры и реалий реализации |
| `services/analytics-pipeline/README.md` | Этап-0 KPI draft | Граница сервиса + связь с текущими контрактами/скриптами | Зафиксировать переход от идеи к рабочему ops-loop |
| `docs/architecture/01_TARGET_REPO_STRUCTURE.md` | Частично устаревшее target-описание | Сжатое актуальное target-описание, ownership и правила зависимостей | Упростить и синхронизировать архитектурный baseline |
| `docs/architecture/02_ARCHITECTURE_MODULE_CATALOG.md` | Старые модули с ads-акцентом | Актуальный каталог модулей (game/store/analytics/ops) | Синхронизация с текущей модульной реализацией |
| `docs/architecture/03_RELATION_MAP.md` | Старая карта с ad networks в ядре | Обновлённые связи с store personalization и rollout control points | Соответствие ad-free-first и текущему data-flow |
| `docs/design/01_UI_UX_ART_DIRECTION.md` | Старые формулировки + mixed encoding | Актуальный UX/art direction под текущий бренд и touch ergonomics | Зафиксировать текущий визуальный курс без регресса |
| `docs/product/01_PRODUCT_VISION_KPI.md` | Ads-driven KPI формулировки | KPI и vision под ad-free-first monetization и текущий go-to-market | Убрать стратегическое противоречие |
| `docs/product/02_TECHNICAL_REQUIREMENTS_SPEC.md` | FR-MON и scope с ads-first акцентом | FR/NFR в соответствии с текущей реализацией (utility/IAP/ops) | ТЗ должно соответствовать фактическому продукту |
| `docs/roadmap/01_ROADMAP_AND_SPRINTS.md` | Частично legacy sprint формулировки | Обновлённая дорожная карта и backlog streams с ad-free контекстом | Синхронизация плана и выполненных этапов |
| `docs/roadmap/02_PHASE0_CHECKLIST.md` | Повреждённый/шумный historical контент | Короткий архивный historical summary + ссылки на source-of-truth | Удалить шум, сохранить исторический след |
| `docs/roadmap/03_SPRINT1_ISSUE_READY_BACKLOG.md` | Большой legacy backlog с артефактным шумом | Архивный summary Sprint 1 | Убрать конфликт с текущим статусом реализации |
| `docs/roadmap/04_SPRINT1_GITHUB_ISSUES.md` | Legacy issue list с артефактным шумом | Архивная справка + команда регенерации issues | Сохранить референс без дублирования актуального статуса |
| `docs/roadmap/05_IMPLEMENTATION_STATUS.md` | Старые статусы и старый app label | Актуальный статус до 2026-02-26 + post-sprint visual/UX pass | Единый truth по фактически реализованному объёму |
| `docs/roadmap/06_ROADMAP_COMPLETENESS_AUDIT_2026-02-25.md` | Старый процент/выводы | Обновлённый аудит 2026-02-26, реальный остаток Sprint 8 | Корректно отражать readiness |
| `docs/operations/01_ANALYTICS_AB_MONETIZATION_SPEC.md` | Монетизация/события с ads-first доминированием | Событийный контракт с ad-free текущим режимом + optional ad events | Убрать конфликт между стратегией и analytics spec |
| `docs/operations/02_RISKS_GUARDRAILS.md` | Риски с ad pressure как ключевым ядром | Guardrails под текущие gameplay/ops риски | Актуализировать риск-модель |
| `docs/operations/03_INTERNAL_PLAYTEST_PROTOCOL.md` | Протокол с debug-only и ad-pressure формулировками | v2 protocol с release/debug путём и `ops_*` фокусом | Синхронизация playtest процесса |
| `docs/operations/04_INTERNAL_PLAYTEST_RUN_001_REPORT.md` | Смешение simulated run и production-подачи | Явно помечен как simulation baseline, не player truth | Избежать неправильных продуктовых выводов |
| `docs/operations/05_RUN_002_INPUT_TEMPLATE.md` | Неявная трактовка `rewarded_opt_in_rate` | Явная трактовка для ad-free utility path | Убрать метрик-конфликт в текущей стратегии |
| `docs/operations/06_QA_SMOKE_PACK_V1.md` | Debug инструкции без явной границы со store build | Разделён smoke/debug и store-mode build note | Правильное ожидание по QA процессу |
| `docs/operations/07_GITHUB_ACTIONS_SETUP.md` | Частично устаревшее описание workflows | Актуальный CI + release workflow + artifacts | Синхронизация с `.github/workflows` |
| `docs/operations/08_AD_FREE_MODE_STRATEGY.md` | Частично размытая формулировка | Чётко зафиксирован приоритет ad-free режима и текущая стратегия | Устранение стратегических расхождений |
| `docs/operations/09_IAP_SANDBOX_SCAFFOLD.md` | Общая IAP заметка | Зафиксирован текущий фокус `cosmetics-first` + remaining gaps | Привести к реальному decision log |
| `docs/operations/10_DASHBOARD_MVP_CONTRACT.md` | Частично старые scope-границы | Актуальный контракт/экспорт и pending backend aggregation | Согласовать с текущим скриптовым контуром |
| `docs/release/01_ANDROID_PUBLISHING_PLAYBOOK_NO_IOS.md` | Старый label (`Block Puzzle`) и старые условия | Актуальные identity/artifacts/workflow для Android-only волны | Подготовка к фактической публикации |
| `docs/release/02_STORE_METADATA_TEMPLATES.md` | Общие правила без текущего naming baseline | Добавлен текущий RU/EN title baseline `Lumina Blocks` | Синхронизация release-контента |
| `docs/release/03_PUBLISH_EXECUTION_CHECKLIST.md` | Старые store name defaults | Актуальные input/runbook пункты под текущий бренд | Избежать ошибок при публикации |
| `docs/branding/01_BRAND_FOUNDATION_V1.md` | Старый working name `Block Puzzle` | Актуальный brand core `Lumina Blocks` + store naming baseline | Бренд-док должен совпадать с продуктом |
| `docs/legal/01_PRIVACY_POLICY_DRAFT.md` | Placeholder support email | Подставлен актуальный support email и уточнён ad-free контекст | Предрелизная legal-согласованность |
| `Техническое задание на создание Архитектур.md` | Большой legacy ads-first черновик | Переведён в архивный указатель на актуальные docs | Исключить конфликт legacy ТЗ с текущей реализацией |

## Дополнение: Sprint 8.1 и Sprint 9 planning update
| Файл | Что было | Что стало | Почему |
|---|---|---|---|
| `docs/roadmap/07_SPRINT8_1_STABILIZATION_BACKLOG.md` | Файл отсутствовал | Добавлен детальный stabilization backlog на 10 рабочих дней | Нужен конкретный post-Sprint 8 execution-план с задачами по дням |
| `docs/roadmap/08_SPRINT9_FIRST_NEW_MODE_BACKLOG.md` | Файл отсутствовал | Добавлен backlog Sprint 9 для `Mode Hub + Tetris Rush` и scaffold `Match-3` | Нужен конкретный delivery-план масштабирования режимов на базе текущего движка |
| `docs/roadmap/01_ROADMAP_AND_SPRINTS.md` | Не содержал Sprint 8.1/9 execution pack links | Добавлены Sprint 8.1, Sprint 9 и ссылки на новые backlog-доки | Интегрировать новые планы в официальную дорожную карту |
| `docs/roadmap/05_IMPLEMENTATION_STATUS.md` | Next Queue без прямых execution-пакетов | Next Queue обновлен ссылками на Sprint 8.1 и Sprint 9 | Сделать следующую последовательность работ однозначной |

## Дополнение: issue-ready planning и mode strategy update
| Файл | Что было | Что стало | Почему |
|---|---|---|---|
| `docs/roadmap/08_SPRINT9_FIRST_NEW_MODE_BACKLOG.md` | Sprint 9 как `Daily Challenge` first mode | Sprint 9 как `Mode Hub + Tetris Rush` с scaffold под `Match-3` | Синхронизация с новой стратегией расширения режимов через кнопки на главном экране |
| `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md` | Файл отсутствовал | Добавлен issue-ready план Sprint 8.1 по дням (labels + acceptance criteria) | Подготовка к управляемому выполнению stabilization этапа в GitHub Issues |
| `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md` | Файл отсутствовал | Добавлен issue-ready план Sprint 9 по дням (Mode Hub, Tetris, Match-3 scaffold) | Нужна практичная декомпозиция разработки новых режимов |
| `docs/roadmap/01_ROADMAP_AND_SPRINTS.md` | Execution packs без issue-ready ссылок | Добавлены ссылки на `09` и `10` issue-ready документы | Быстрый доступ команды к day-by-day issue плану |
| `docs/roadmap/05_IMPLEMENTATION_STATUS.md` | Next Queue без актуальной mode strategy | Next Queue обновлен под `Tetris Rush + Mode Hub` и ссылки issue-ready | Сохранить единый источник текущего плана |

## Дополнение: GitHub issue pack + autocreate script
| Файл | Что было | Что стало | Почему |
|---|---|---|---|
| `docs/roadmap/11_SPRINT8_1_SPRINT9_GITHUB_ISSUES.md` | Файл отсутствовал | Добавлен единый paste-ready pack (`Title / Labels / Body`) для Sprint 8.1 и Sprint 9 | Быстрый ручной импорт задач в GitHub без дополнительной разметки |
| `scripts/create_sprint8_1_sprint9_issues.ps1` | Скрипт отсутствовал | Добавлен скрипт автосоздания issues через `gh issue create` + экспорт markdown pack | Ускорить перенос backlog в GitHub и снизить ручные ошибки |

## Notes
- В changelog включены только документы, которые были скорректированы в рамках текущего reconciliation-прохода.
- Markdown-файлы в `build/` и `artifacts/` не правились намеренно (generated/output scope).

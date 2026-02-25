# Этап 0 - Чеклист Запуска (2-4 недели)

## 1. Цель этапа
Зафиксировать основу проекта так, чтобы команда без хаоса вошла в MVP-разработку с понятной архитектурой, измеримостью и приоритетами.

## 2. Deliverables этапа 0
- Утвержденные Product Vision и KPI.
- Согласованное ТЗ и архитектура модулей.
- Рабочий прототип core-loop (без финального арта).
- Event schema v1 и remote config schema v1.
- Device/perf baseline.
- Backlog минимум на 4 спринта вперед.

## 3. Обязательные задачи по неделям

### Неделя 1
- Kickoff: роли, ownership, cadence.
- Freeze core rules игры.
- Утверждение target repo structure.
- Определение KPI dashboard v1.

### Неделя 2
- Реализация прототипа хода/валидации/очистки линий.
- Выбор telemetry stack.
- Черновик ad architecture (без production pressure).
- Документирование рисков и guardrails.

### Неделя 3
- Internal playtest (минимум 20-30 сессий).
- Сбор фидбека по feel/fairness.
- Калибровка score curve.
- Набор визуальных и аудио референсов.

### Неделя 4
- Финализация MVP backlog.
- Definition of Ready для Sprint 1.
- QA smoke сценарии.
- Decision checkpoint: go/no-go в Этап 1.

## 4. Definition of Ready (для задач)
- Есть user value и ожидаемый KPI impact.
- Есть acceptance criteria.
- Есть owner и оценка трудозатрат.
- Указаны зависимости и риски.

## 5. Definition of Done (для задач)
- Код/документация завершены.
- Пройдены тесты.
- Инструментирование аналитики проверено.
- Внесены release notes / change log.

## 6. Гейт выхода из этапа
- Core-loop fun score по внутреннему тесту >= порога команды.
- Нет критических архитектурных блокеров.
- Есть ясный план MVP и матрица экспериментов.

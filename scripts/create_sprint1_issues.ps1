param(
  [Parameter(Mandatory = $true)]
  [string]$Repo
)

$ErrorActionPreference = "Stop"

function New-Issue {
  param(
    [string]$Title,
    [string[]]$Labels,
    [string]$Body
  )

  $labelArgs = @()
  foreach ($label in $Labels) {
    $labelArgs += "--label"
    $labelArgs += $label
  }

  gh issue create -R $Repo --title $Title @labelArgs --body $Body | Out-Host
}

New-Issue `
  -Title "Sprint 1: Bootstrap Flutter + Flame baseline" `
  -Labels @("sprint-1", "type:task", "priority:p0", "area:mobile") `
  -Body @"
## Context
Нужно стабилизировать базовый scaffold проекта и зафиксировать зависимости для дальнейшей разработки.

## Scope
- Проверить сборку Android/iOS/Web.
- Зафиксировать версии Flame/GetIt/lints.
- Подтвердить bootstrap flow (`main -> bootstrap -> app`).
- Обновить технический README клиента.

## Acceptance Criteria
- [ ] `flutter analyze` проходит без ошибок.
- [ ] `flutter test` проходит.
- [ ] Home screen стабильно открывается.
"@

New-Issue `
  -Title "Sprint 1: Domain contracts for gameplay core" `
  -Labels @("sprint-1", "type:task", "priority:p0", "area:mobile") `
  -Body @"
## Context
Нужны стабильные domain-контракты, не зависящие от UI и SDK.

## Scope
- Модели: BoardState, Piece, Move, SessionState, ScoreState.
- Интерфейсы: MoveValidator, LineClearService, ScoreService, PieceGenerationService, DifficultyTuner.
- Базовые инварианты для структур.

## Acceptance Criteria
- [ ] Domain слой не зависит от Flutter UI и внешних SDK.
- [ ] Контракты покрыты unit-тестами инвариантов.
"@

New-Issue `
  -Title "Sprint 1: DI container and service registrations" `
  -Labels @("sprint-1", "type:task", "priority:p0", "area:mobile") `
  -Body @"
## Context
Нужна управляемая и расширяемая регистрация зависимостей.

## Scope
- Настроить GetIt container.
- Зарегистрировать core config/logging/analytics/remote config.
- Зарегистрировать gameplay сервисы и use-cases.
- Подключить DI в bootstrap.

## Acceptance Criteria
- [ ] Все зависимости резолвятся при старте приложения.
- [ ] Нет runtime ошибок DI.
"@

New-Issue `
  -Title "Sprint 1: Flame game screen skeleton" `
  -Labels @("sprint-1", "type:task", "priority:p1", "area:mobile") `
  -Body @"
## Context
Нужен рабочий каркас игрового экрана для последующей интеграции core-loop.

## Scope
- GameLoopScreen с GameWidget.
- BlockPuzzleGame + lifecycle hook.
- Навигация Home -> GameLoop.

## Acceptance Criteria
- [ ] Игровой экран открывается без падений.
- [ ] Контроллер инициализируется в onLoad.
"@

New-Issue `
  -Title "Sprint 1: Telemetry base layer on client" `
  -Labels @("sprint-1", "type:task", "priority:p1", "area:data", "area:mobile") `
  -Body @"
## Context
Нужен минимальный и расширяемый каркас событий для продуктовой аналитики.

## Scope
- Интерфейс AnalyticsTracker.
- Debug реализация.
- Событие инициализации game loop.
- Подготовка к offline buffering.

## Acceptance Criteria
- [ ] События логируются в debug режиме.
- [ ] API трекинга готово к подключению реального SDK.
"@

New-Issue `
  -Title "Sprint 1: Graybox art kit for gameplay prototype" `
  -Labels @("sprint-1", "type:task", "priority:p0", "area:art") `
  -Body @"
## Context
Для внутренних playtest нужен минимальный визуальный комплект без финального арта.

## Scope
- Graybox поле 8x8.
- Базовый набор фигур (8-12 форм).
- Valid/invalid placement colors.
- Простейшие HUD иконки.

## Acceptance Criteria
- [ ] Все элементы читаемы на разных разрешениях.
- [ ] Ассеты не мешают touch UX.
"@

New-Issue `
  -Title "Sprint 1: Motion references package (line clear/combo/game over)" `
  -Labels @("sprint-1", "type:task", "priority:p1", "area:art") `
  -Body @"
## Context
Нужны референсы для постановки анимационного направления в Sprint 2.

## Scope
- 2-3 референса line clear.
- 2 референса combo escalation.
- 1 референс game over sequence.
- Рекомендованные тайминги v1.

## Acceptance Criteria
- [ ] Референсы согласованы Product + Design.
- [ ] Итог внесен в docs/design.
"@

New-Issue `
  -Title "Sprint 1: Core-loop product spec freeze v1" `
  -Labels @("sprint-1", "type:task", "priority:p0", "area:product") `
  -Body @"
## Context
Нужно зафиксировать правила gameplay, чтобы избежать дрейфа требований.

## Scope
- Core rules: board/piece triplet/game over.
- Score + combo правила для MVP.
- UX ограничения (quick restart, low friction).
- Явный out-of-scope список.

## Acceptance Criteria
- [ ] Спека зафиксирована и согласована.
- [ ] Все P0 dev задачи с однозначными acceptance criteria.
"@

New-Issue `
  -Title "Sprint 1: KPI instrumentation map v1" `
  -Labels @("sprint-1", "type:task", "priority:p0", "area:product", "area:data") `
  -Body @"
## Context
Нужна карта соответствия между событиями и ключевыми KPI.

## Scope
- Список событий + обязательные параметры.
- Связь event -> KPI (retention proxy, session quality, ad basics).
- Правила schema versioning.
- Роли и cadence валидации данных.

## Acceptance Criteria
- [ ] Документ утвержден Product/Data/Mobile.
- [ ] Есть plan проверки данных после релиза.
"@

New-Issue `
  -Title "Sprint 1: Event schema draft and ingestion rules" `
  -Labels @("sprint-1", "type:task", "priority:p0", "area:data") `
  -Body @"
## Context
Нужна базовая схема событий для совместимости клиента и пайплайна.

## Scope
- JSON schema v1 для ключевых событий.
- Required/optional fields.
- Quarantine policy для невалидных payload.
- Примеры payload.

## Acceptance Criteria
- [ ] Схемы покрывают session/game/move/ad базовый набор.
- [ ] Документация готова для интеграции backend.
"@

Write-Host "Sprint 1 issues were created in repo: $Repo"

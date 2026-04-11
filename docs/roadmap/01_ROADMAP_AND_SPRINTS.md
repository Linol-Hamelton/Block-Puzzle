# Roadmap and Phase Backlog

Last updated: 2026-04-12. This roadmap supersedes the previous sprint-based sequencing. The new structure is a 5-phase path to TOP-1 in the block puzzle genre, consistent with the plan approved in `C:/Users/Dmitry/.claude/plans/sequential-weaving-seahorse.md`.

## Current Planning Rule
- Foundation gates (Firebase Crashlytics, real Google Play Billing v7, Hive-backed persistence, lifecycle state machine, Firebase Remote Config, release discipline) take absolute priority over new modes and engagement features.
- Sprint 9 scope (Mode Hub + new modes) is folded into Phase 4 and remains frozen until Phase 1 and Phase 2 gates are green.
- The monetization model is ad-free: IAP cosmetics + Premium Pass + soft-currency packs. Revive and utility tools use soft currency and the Pass. No ads — not even rewarded.
- The production data plane is Firebase-first. `services/config-api` and `services/analytics-pipeline` are deferred.

## Fixed KPI Targets (TOP-1 benchmarks)
- Crash-free sessions ≥ 99.7%
- ANR rate ≤ 0.20%
- D1 ≥ 45%, D7 ≥ 18%, D30 ≥ 8%
- Average session length ≥ 9 minutes
- ARPDAU via IAP ≥ $0.08
- Early game-over rate ≤ 0.25
- Cold start p90 ≤ 2.5s on low-mid Android (Redmi 9/10, Samsung A-series)

## Phase Structure

### Phase 0 — Gardening & Alignment (3 working days)
Goal: clean start. Finalize deletion of trash files, align docs with the Firebase-first decision, create module skeletons, tighten static analysis.

Deliverables:
1. Trash files removed from working tree and committed.
2. README.md, docs/roadmap/01, docs/roadmap/05, docs/product/02, docs/architecture/02, docs/architecture/03, docs/operations/09, docs/operations/10, docs/operations/14 rewritten under Firebase-first.
3. `services/config-api/README.md` and `services/analytics-pipeline/README.md` archived as deferred.
4. Module skeleton directories created under `apps/mobile/lib/features` and `apps/mobile/lib/infra`.
5. `apps/mobile/analysis_options.yaml` tightened (`strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `unawaited_futures`).

Exit criteria: `flutter analyze` green, `git status` clean, no doc contradictions.

### Phase 1 — Foundation & Stability Gates (20 working days)
Goal: close every stability gap and meet the publish-decision gates from [05_IMPLEMENTATION_STATUS.md](05_IMPLEMENTATION_STATUS.md) except those that require live cohorts.

Week breakdown (see plan file for day-level detail):
- **Week 1** — Firebase setup (Core, Crashlytics, Analytics, Remote Config, Messaging, Performance), error boundary UI, game loop lifecycle state machine, audio focus handling.
- **Week 2** — Hive migration for critical persisted state, piece generation safety rails, unawaited-futures sweep, cold-start optimization.
- **Week 3** — Firebase Remote Config adapter, Firebase Analytics adapter, real Google Play Billing v7 with Cloud Functions receipt validation, restore purchases + entitlement sync via Anonymous Auth.
- **Week 4** — Device-matrix smoke pack on Redmi/Samsung/Honor/Xiaomi, perf pass (60-minute session memory profile), network retry/backoff client, release pipeline dry-run, gate review.

Hard exit gates:
- Crashlytics receives real events from release builds.
- `flutter analyze --fatal-infos --fatal-warnings` green.
- `flutter test` green including new `cold_kill_recovery_test`.
- `ops_alert_critical_count == 0` in a 24-hour internal testing window.
- Real billing sandbox passes purchase + restore + reinstall for `skin_aurora`.
- Persisted board snapshot survives `kill -9`.

This phase replaces the 10-day Sprint 8.1 plan in [07_SPRINT8_1_STABILIZATION_BACKLOG.md](07_SPRINT8_1_STABILIZATION_BACKLOG.md). That file will be rewritten to mirror this 20-day structure.

### Phase 2 — Soft Launch & Cohort Loop (15 working days)
Goal: closed testing release, collect real cohort data, pass the rollout gates from [16_ROLLOUT_GATES_CHECKLIST_OPS_SIGNALS.md](../operations/16_ROLLOUT_GATES_CHECKLIST_OPS_SIGNALS.md), produce a Go/No-Go decision for broader rollout.

- **Week 5** — Store submission prep: localized RU+EN metadata, screenshots matching shipped features, preview video, Privacy Policy published to Firebase Hosting, Data Safety / Content Rating forms submitted, first closed-test upload.
- **Week 6** — Dashboards & alerting: Looker Studio dashboard over BigQuery (D1/D7/D30, DAU, session length, mission completion, crash-free, early-gameover rate, ARPDAU, revive usage, top SKU), Cloud Function `alert_router` → Slack/Telegram webhook.
- **Week 7** — Cohort window #1: ~200 real players, 72 hours, `cohort_window_01.json` produced.
- **Week 8** — Cohort window #2: 72 hours, rollout gates report, Go/No-Go meeting.

Exit criteria: two consecutive cohort windows with accepted rollout decision, early game-over rate ≤ 0.30, runtime error session rate ≤ 0.02, crash-free sessions ≥ 99.5%, no open P0/P1.

### Phase 3 — Engagement Expansion (25 working days)
Goal: close engagement gaps so the app can compete with TOP-1 titles on D7+ retention and session length.

Workstreams (can be sequential or parallel depending on team capacity):
- **3A — Meta-progression + Soft Currency (5 days)** — Player level, XP, LevelRewardTable, SoftCurrencyWallet (Shards earned in-game + Crystals purchased), level-up celebration overlay, home-screen XP bar, 50-level first season.
- **3B — Revive + Wheel + Missions (7 days)** — soft-currency revive with 1 free/day, daily wheel (1 free spin + 2 paid), Daily (3) and Weekly (5) missions with Remote-Config driven pool.
- **3C — Cosmetics Shop + Season Pass (6 days)** — block skins, board backgrounds, line-clear VFX, SFX packs, Shop screen, Season Pass with free and premium lanes on a 6-week cadence.
- **3D — Achievements + Events + Juice (4 days)** — 30 badges, event calendar, screen shake, particle burst, score pop, haptic patterns, combo zoom, all behind `feature_juice_enabled` kill switch.
- **3E — Onboarding, Localization, Accessibility, Notifications (3 days)** — interactive 5-step onboarding with unlock reward, localization (ru, en, tr, id, pt-br, es, de, fr), accessibility (text scaling, color-blind palettes, haptics toggle), FCM push (max 1/day).

Exit criteria: all Phase 3 features kill-switch-controlled, localization smoke-tested per locale, TalkBack-validated accessibility, two post-release cohort windows showing session length ≥ 7min and D1 ≥ 45%.

### Phase 4 — Mode Hub & New Modes (30 working days)
Goal: content depth. Unfreezes the Sprint 9 backlog and attaches it to the ready foundation.

- **Mode Hub** — replaces current home screen; cards for Classic, Time Rush, Puzzle Pack, Daily Challenge, Events.
- **Time Rush (10 days)** — 3-minute rounds with combo-based time multipliers, dedicated leaderboard.
- **Puzzle Pack (10 days)** — 100 curated levels with fixed boards and goals, sequential unlock, star rating.
- **Daily Challenge (3 days)** — single seeded board per day, daily leaderboard.
- **Leaderboards (5 days)** — Firestore-backed `leaderboards/{modeId}/{weekId}/scores`, server-side anti-cheat via Cloud Function validation against session events.
- **Achievements v2** — mode-specific achievement chains.

Exit criteria: all 4 new modes in code with smoke tests, end-to-end leaderboards, `mode_switch_rate` ≥ 35% among active players.

[08_SPRINT9_FIRST_NEW_MODE_BACKLOG.md](08_SPRINT9_FIRST_NEW_MODE_BACKLOG.md) becomes the execution pack for this phase; [10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md](10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md) is rebased onto the day-by-day inside this phase.

### Phase 5 — TOP-1 Tuning & Live Ops (continuous)
Goal: sustain TOP-1 KPIs via continuous improvement.

- Weekly Looker Studio gate review.
- Firebase A/B Testing: onboarding variants, difficulty curve, pass price, mission difficulty, wheel prize table.
- Event calendar: at least 1 event per week.
- Seasonal content: new Season Pass every 6 weeks, 3-5 new cosmetics per season.
- Balance tuning: piece frequency, difficulty ramp, revive cost, soft-currency drop rates.
- In-game feedback button → Firestore → Slack triage.
- ASO: monthly store listing A/B tests, keyword iteration.
- Localization expansion: JA, KO, ZH-CN after Phase 4.
- Community: Discord/VK, weekly leaderboard recap.

TOP-1 acceptance: crash-free ≥ 99.7%, D1 ≥ 48%, D7 ≥ 20%, D30 ≥ 10%, session length ≥ 9 min, ARPDAU ≥ $0.10, store rating ≥ 4.6 on ≥1000 reviews, Google Play Puzzle category rank ≤ 20 in at least one target country.

## Roles and Ownership
- Product Manager — hypotheses, KPI prioritization, phase exit decisions
- Gameplay Engineer — core loop, balance, Flame rendering, juice pack
- Client Engineer — Firebase integration, billing, Hive, lifecycle, UI
- Data Engineer — event taxonomy, BigQuery exports, Looker Studio dashboards, Cloud Functions
- Designer/Artist — cosmetics, event visuals, onboarding illustrations, store creatives
- QA Engineer — device matrix, smoke pack, regression, release dry-runs

## Continuous Backlog Streams
1. Gameplay quality (rule safety, generator fairness, difficulty pacing)
2. Monetization quality (ad-free, IAP-driven; cosmetics/Pass balance)
3. Retention systems (missions, events, meta-progression, notifications)
4. Tech platform reliability (crash-free, perf, persistence, lifecycle)
5. Data and experiment governance (event schema, Remote Config, AB discipline)

## Execution Packs
- Phase 1 daily breakdown: [07_SPRINT8_1_STABILIZATION_BACKLOG.md](07_SPRINT8_1_STABILIZATION_BACKLOG.md) (being rewritten to 20 days)
- Phase 1 issue pack: [09_SPRINT8_1_ISSUE_READY_DAILY.md](09_SPRINT8_1_ISSUE_READY_DAILY.md) (being rewritten)
- Phase 4 execution pack: [08_SPRINT9_FIRST_NEW_MODE_BACKLOG.md](08_SPRINT9_FIRST_NEW_MODE_BACKLOG.md) (remains frozen until Phase 2 gates pass)
- Phase 4 daily plan: [10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md](10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md) (remains frozen)
- Combined issue pack: [11_SPRINT8_1_SPRINT9_GITHUB_ISSUES.md](11_SPRINT8_1_SPRINT9_GITHUB_ISSUES.md) (to be regenerated against this roadmap)

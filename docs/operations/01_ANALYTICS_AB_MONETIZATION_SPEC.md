# Analytics, AB, and Monetization Spec

## 1. Goal
Provide a stable event and experiment contract for retention, UX quality, and monetization decisions.

## 2. Product Mode (Current)
- Runtime strategy: **ad-free by default**.
- Monetization baseline: cosmetics + utility entitlements.
- Ad events remain in schema as optional/future-compatible fields and must not be assumed active.

## 3. Core Event Taxonomy (v1)
Required operational/gameplay events:
- `session_start`
- `session_end`
- `game_start`
- `move_made`
- `game_end`
- `ab_experiment_exposure`
- `daily_goal_progress`
- `streak_updated`
- `rewarded_hint_used`
- `rewarded_undo_used`
- `rewarded_tools_credits_earned`
- `store_open`
- `iap_purchase_attempt`
- `iap_purchase`
- `iap_restore`
- `offer_targeting_exposure`
- `share_score_tapped`
- `share_score_result`
- `tutorial_step`

Operational observability events:
- `ops_session_snapshot`
- `ops_alert_triggered`
- `ops_error`

Optional/future ad events:
- `ad_impression`
- `ad_rewarded`

## 4. Contract Rules
1. Every event includes `schema_version`.
2. Missing required fields route to validation failure/quarantine.
3. Unknown extra fields are tolerated but logged.
4. Timestamps are UTC-based.

## 5. AB Framework
Mandatory experiment metadata:
- `experiment_id`
- `hypothesis`
- `primary_metric`
- `guardrails`
- `target_population`
- `stop_criteria`

Priority test areas:
1. gameplay fairness and difficulty
2. HUD/readability UX
3. store offer strategy
4. visual presets and polish

## 6. Dashboard Blocks
1. retention proxy
2. session quality
3. monetization proxy
4. engagement systems
5. experiment monitoring
6. observability and alerting

## 7. Operational Cadence
- Daily: KPI pulse + alert triage.
- Weekly: AB readout + reprioritization.
- Per cohort window: Sprint 8 rollout gate evaluation.

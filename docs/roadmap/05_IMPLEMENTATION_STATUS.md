# Implementation Status (Actual)

Last updated: 2026-02-25

## Sprint 1
- Status: `done`
- Notes: Flutter+Flame scaffold, domain contracts, DI, game screen skeleton, analytics base layer, basic tests.

## Sprint 2
- Status: `done`
- Notes: line clear/combo/game over/restart, HUD, best score, domain use-cases, unit tests.

## Sprint 3
- Status: `done`
- Notes: visual/SFX polish baseline, onboarding v1 guided hints, remote config fallback, ad adapters and guardrails.

## Sprint 4
- Status: `partially_done (ad-free mode selected)`
- Done:
  - ad event schemas and validation
  - QA smoke pack v1
- Deferred by product strategy:
  - production ad mediation/integration (project is ad-free by decision)
- Still relevant:
  - performance pass (assets/draw calls/memory) in next technical iteration

## Sprint 5
- Status: `partially_done`
- Done:
  - AB foundation: `ab.bucket` + `ab_experiment_exposure` tracking
  - dashboard MVP contract + export script (`data/dashboards/dashboard_mvp_contract_v1.json`, `scripts/export_dashboard_mvp_snapshot.ps1`)
- Pending:
  - soft launch readiness checklist hardening

## Sprint 6
- Status: `in_progress`
- Done:
  - daily goals (moves/lines/score) with runtime progress and completion analytics events
  - streak system with day rollover update and streak analytics event
- Pending:
  - rewarded hint/undo alternative for ad-free strategy (IAP or earned currency based)
  - UX/balance AB wave #1

## Sprint 7
- Status: `in_progress`
- Done:
  - ad-free monetization direction fixed
  - IAP sandbox: cosmetics-first rollout
- Pending:
  - user segmentation + offer targeting v1
  - end-of-round UX improvements + optional share flow
  - observability and alerting upgrade

## Sprint 8
- Status: `pending`
- Pending:
  - soft launch iteration #2 loop
  - rollout of winning experiments
  - GEO expansion prep
  - pre-production package for stage 3 modes

## Next Sequential Execution Queue
1. Sprint 6: rewarded hint/undo alternative for ad-free strategy (IAP or earned currency path).
2. Sprint 6: UX/balance AB wave #1.
3. Sprint 7: segmentation and offer targeting v1 for cosmetics catalog ordering.

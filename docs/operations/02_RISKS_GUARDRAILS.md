# Risks and Guardrails

## 1. Key Risks
1. Difficulty unfairness reduces retention.
2. Weak analytics quality causes wrong product decisions.
3. Performance regressions on low/mid Android devices.
4. LiveOps iteration lag after soft launch.
5. Store UX overload from poor offer strategy.

## 2. High-Priority Risk Matrix
| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Generator unfairness | Medium | High | telemetry + fairness constraints + AB rollback |
| Event schema drift | Medium | High | versioned schema + validation + quarantine |
| FPS drop | High | Medium | perf budget + profiling + asset optimization |
| Runtime stability | Medium | High | observability alerts + hotfix flow |
| Offer fatigue | Medium | Medium | segment targeting + frequency controls |

## 3. Guardrails
- Retention: block rollout increase if D1 proxy drops > 2pp.
- Stability: block rollout if crash-free < 99.5%.
- Gameplay: rollback tuning when `early_game_over_rate > 0.30`.
- UX: revisit onboarding if tutorial drop-off rises > 8%.
- Ops: block promotion on hard gate fail (`ops_*` critical thresholds).

## 4. Rollback Model
1. Detect anomaly from metrics/alerts.
2. Validate impact by segment and variant.
3. Apply rollback via config or patch release.
4. Run postmortem with owner and deadline.

## 5. Release Gates
1. QA smoke/regression passed.
2. Key analytics contracts valid.
3. Success metrics and stop criteria documented.
4. Ops alerts configured and monitored.
5. Legal/privacy checklist complete.

## 6. Anti-Patterns
- Shipping variant changes without telemetry.
- Modifying difficulty without guardrails.
- Publishing without kill-switch capability.
- Store claims that do not match implemented product state.

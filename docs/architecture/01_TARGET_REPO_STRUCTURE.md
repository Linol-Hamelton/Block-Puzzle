# Target Repository Structure

## 1. Purpose
The structure should support:
1. fast feature delivery,
2. safe scaling,
3. clear ownership across gameplay, data, monetization, and operations.

## 2. Target Tree (high-level)
```text
Block-Puzzle/
├─ docs/
├─ apps/
│  └─ mobile/
│     ├─ lib/
│     ├─ assets/
│     └─ test/
├─ services/
│  ├─ config-api/
│  └─ analytics-pipeline/
├─ infra/
├─ data/
└─ scripts/
```

## 3. Dependency Rules
- `domain` has no dependency on UI/SDK details.
- `features` orchestrate domain use-cases.
- `data` implements repositories/adapters used by features.
- external integrations are isolated behind interfaces.

## 4. Ownership (current)
- Gameplay: `apps/mobile/lib/domain`, `features/game_loop`
- Client platform: `core`, shared UI/theme, build/bootstrap
- Data/Product: analytics contracts, dashboards, rollout scripts
- Monetization: store/IAP modules and targeting logic
- Release/Ops: CI workflows, publish docs, guardrails

## 5. Contract Versioning
- Event/config contracts include explicit version fields.
- Backward-compatible evolution is preferred.
- Breaking changes require migration notes in docs.

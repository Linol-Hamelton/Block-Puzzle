# Architecture Decision Records (ADR)

Load-bearing decisions are recorded here as numbered ADRs. Each ADR is short: context, decision, status, consequences. A decision is not "made" until its ADR is `Accepted`. The 2026-06-19 audit surfaced four decisions that were being made implicitly (or drifting) and are now tracked.

| ADR | Title | Status |
|---|---|---|
| [001](001-analytics-tracker-choice.md) | Production analytics tracker: validated vs unvalidated | Proposed |
| [002](002-multi-game-engine-strategy.md) | Multi-game engine abstraction strategy (Tetris/Match-3) | Proposed |
| [003](003-billing-receipt-validation.md) | Billing + server-side receipt validation architecture | Proposed |
| [004](004-controller-subservice-lifecycle.md) | Game controller / sub-service lifecycle (factory vs singleton) | Proposed |

Definition of "Implemented": a feature counts as implemented only when it is wired in DI and reachable from a code path — not merely present as a class.

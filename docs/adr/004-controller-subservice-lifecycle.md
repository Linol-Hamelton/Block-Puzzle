# ADR-004 — Game controller / sub-service lifecycle (factory vs singleton)

Status: Proposed (2026-06-19)
Related: [audit §3](../audit/01_FULL_PROJECT_AUDIT_2026-06-19.md)

## Context
`GameLoopController` is `registerFactory` (new per screen, `di_container.dart:182`); its sub-services `ABExperimentService`, `OnboardingFlowController`, `ProgressionSyncService` are `registerLazySingleton` (`:148-180`) with no reset on dispose. Adversarial verification downgraded this from "active state leak" to a **latent ownership smell**: `initialize()` re-derives the relevant state from config + persistence on each entry, and the only non-re-seeded field (`OnboardingFlowController._moveCount`) is inert on the resume path. So it is not a release blocker today, but the ownership is ambiguous and a future field added to a singleton could silently leak across sessions.

## Decision (to ratify)
Align lifecycles: either bind the sub-services to the controller's scope (factory/scoped) so they are recreated per session, **or** make the controller a singleton with an explicit `reset()` invoked on session start. Document which singletons are intentionally cross-session (none today).

## Consequences
- Removes a latent footgun; makes "what state survives a session boundary" explicit and testable.
- Low effort; no observable behavior change expected. Add a test asserting a fresh session starts from clean sub-service state.

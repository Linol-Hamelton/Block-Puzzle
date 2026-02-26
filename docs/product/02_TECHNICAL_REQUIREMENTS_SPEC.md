# Technical Requirements Specification

## 1. Scope
This document defines functional and non-functional requirements for Lumina Blocks on Flutter + Flame.

## 2. Stage Scope
1. Prototype:
- board setup
- drag/drop + move validation
- line clear + score

2. MVP:
- endless classic mode
- onboarding/tutorial
- SFX/VFX baseline
- telemetry for core events

3. Soft Launch:
- daily goals + streak
- AB experiments (difficulty/UX/store strategy)
- IAP utility/cosmetic monetization
- live balancing via remote config

4. Scale:
- additional modes
- deeper progression systems
- advanced liveops

## 3. Functional Requirements
### FR-CORE
- 8x8 board in current classic mode.
- Rack of 3 pieces.
- Valid full-placement rule.
- Auto-clear full lines.
- Score and combo progression.
- Game-over on no valid placements.
- One-tap restart.

### FR-UX
- Minimal-friction session entry.
- Clear valid/invalid placement preview.
- Fast, readable gameplay feedback.
- Persistent HUD with score/best/level/combo/moves.
- Touch ergonomics on mobile:
  - 48dp+ touch targets
  - stable drag threshold
  - drag-lift visibility offset on touch devices.

### FR-PROGRESSION
- Best score persistence.
- Daily goals.
- Streak progression.

### FR-MONETIZATION (Current)
- Ad-free runtime mode enabled by default.
- Utility tools (hint/undo) via credits and/or entitlement.
- IAP catalog with segment-aware offer ordering.

### FR-DATA
- Core telemetry events with schema version.
- Experiment exposure events.
- Remote config controlled variants.
- Observability events (`ops_session_snapshot`, `ops_alert_triggered`, `ops_error`).

### FR-OPS
- Feature flags and kill-switches.
- Versioned config and safe fallbacks.
- Rollout gate evaluation from cohort metrics.

## 4. Non-Functional Requirements
### Performance
- 60 FPS target (not lower than 55 on low-mid Android).
- Low interaction latency.

### Reliability
- Crash-free sessions >= 99.5%.
- Core gameplay available offline.

### Security
- No secrets in repository.
- Minimal personal data footprint.
- Signed release pipeline for store builds.

### Maintainability
- Clear module boundaries.
- Unit tests for domain logic.
- Contract validation for telemetry schemas.

## 5. Acceptance Criteria (Current)
1. Playable loop is stable for repeated sessions.
2. Core analytics and observability contracts validate.
3. Store-mode Android release build is reproducible.
4. Rollout gate tooling is operational for Sprint 8 windows.

## 6. Out of Scope (Current)
- PvP/multiplayer.
- full narrative campaign.
- UGC level editor.

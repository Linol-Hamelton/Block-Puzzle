# services/config-api — DEFERRED

> **Status: deferred in favor of Firebase Remote Config.** See [../../docs/roadmap/01_ROADMAP_AND_SPRINTS.md](../../docs/roadmap/01_ROADMAP_AND_SPRINTS.md) and [../../README.md](../../README.md) for the Firebase-first decision. This document is retained as a historical contract and as a future replacement path if Firebase becomes insufficient for control or compliance reasons.

Thin backend boundary for remote config, feature flags, AB assignment, and config audit history.

## Current State
- Client-side `RemoteConfigRepository` contract is implemented in `apps/mobile`
- Phase 1 Week 3 wires `FirebaseRemoteConfigRepository` as the production implementation
- The `InMemoryRemoteConfigRepository` dev-flavor fallback stays in place
- This custom backend is not on any active phase

## Expected Endpoint
- `GET /v1/config/latest`

Example response shape:

```json
{
  "version": "config_2026_04_11_001",
  "ttl_seconds": 1800,
  "config": {
    "onboarding.enabled": true,
    "progression.daily_goal_moves_target": 18,
    "iap.rewarded_tools_unlimited_enabled": true
  }
}
```

## Requirements
- Version every published snapshot
- Keep rollback history for the last known good version
- Validate config schema before publish
- Support kill switches for risky client features
- Return cache-safe responses with bounded TTL

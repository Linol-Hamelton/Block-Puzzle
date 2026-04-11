# services/analytics-pipeline — DEFERRED

> **Status: deferred in favor of Firebase Analytics + BigQuery export.** See [../../docs/roadmap/01_ROADMAP_AND_SPRINTS.md](../../docs/roadmap/01_ROADMAP_AND_SPRINTS.md) and [../../README.md](../../README.md) for the Firebase-first decision. This document is retained as a historical contract and as a future replacement path if Firebase becomes insufficient for control or compliance reasons.

Thin backend boundary for event ingestion, schema validation, cohort aggregation, and BI export.

## Current State
- Client-side `AnalyticsTracker` contract with queueing and schema validation is implemented in `apps/mobile`
- Phase 1 Week 3 wires `FirebaseAnalyticsTracker` as the production implementation
- BigQuery export from Firebase Analytics feeds Looker Studio dashboards (Phase 2 Week 6)
- This custom backend is not on any active phase

## Expected Endpoint
- `POST /v1/events/batch`

Example request shape:

```json
{
  "app_name": "Lumina Blocks",
  "environment": "stage",
  "app_version": "1.0.0+1",
  "events": [
    {
      "id": "evt_1_1712793600000",
      "event_name": "session_start",
      "params": {
        "schema_version": 1,
        "event_ts_utc": "2026-04-11T10:00:00.000Z"
      },
      "created_at_utc": "2026-04-11T10:00:00.000Z",
      "delivery_attempts": 0
    }
  ]
}
```

## Requirements
- Reject schema-invalid batches with explicit diagnostics
- Preserve raw ingest logs for replay
- Support downstream aggregation by build, config version, AB bucket, and cohort
- Expose health metrics for ingest failures, lag, and schema drift

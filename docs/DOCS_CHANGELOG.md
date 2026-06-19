# Documentation Changelog

Append one dated line per status-changing documentation merge. The canonical status of the product is [roadmap/05_IMPLEMENTATION_STATUS.md](roadmap/05_IMPLEMENTATION_STATUS.md); this log records *when and why* it (and other load-bearing docs) changed. Supersedes the archived `archive/root/DOCS_CHANGELOG_2026-02-26.md`.

## 2026-06-19 (Tetris — domain core started)
- New pure-domain module `apps/mobile/lib/domain/tetris/` (tetromino + SRS rotation/kicks, W×H board with gravity collapse, falling piece, 7-bag, scoring, engine) + 5 unit-test files. Plan + remaining work: [architecture/05_TETRIS_IMPLEMENTATION_PLAN.md](architecture/05_TETRIS_IMPLEMENTATION_PLAN.md). ADR-002 updated with the implementation note. Presentation/input/wiring still to come; SRS tables to be confirmed by running the tests on a real toolchain.

## 2026-06-19 (P0 remediation)
- **P0-3 fixed:** `BlockPuzzleGame` DI factory now passes the required `haptics` arg (`di_container.dart`).
- **P0-2 fixed:** added `ValidatedAnalyticsTracker` decorator; production now validates the analytics schema before sending to Firebase ([adr/001](adr/001-analytics-tracker-choice.md)). Added unit test.
- **P0-1 implemented (pending deploy/verify):** real Google Play billing — `GooglePlayBillingService` + `CloudFunctionsReceiptValidator` + `verifyPurchase` Cloud Function; added `in_app_purchase`/`cloud_functions` deps; wired production billing in DI ([adr/003](adr/003-billing-receipt-validation.md)).
- ADR-001 → Accepted/implemented; ADR-003 → Accepted/implemented (pending deploy + Play sandbox). `05_IMPLEMENTATION_STATUS.md`, `README.md`, and `lib/infra/billing/README.md` updated to match.
- Caveat: flutter/dart not available in the authoring environment — all P0 code changes are unverified by `analyze`/`test` and must be re-checked on a real toolchain.

## 2026-06-19
- Full project audit published: [audit/01_FULL_PROJECT_AUDIT_2026-06-19.md](audit/01_FULL_PROJECT_AUDIT_2026-06-19.md). Release readiness assessed at ~38% (NO-GO). Method: static analysis only (flutter/dart toolchain not available).
- Multi-game engine plan + Tetris & Match-3 feasibility published: [architecture/04_MULTI_GAME_ENGINE_PLAN.md](architecture/04_MULTI_GAME_ENGINE_PLAN.md).
- `05_IMPLEMENTATION_STATUS.md` reconciled with code: Hive persistence and Firebase Crashlytics moved to **Implemented In Code**; "release-safe analytics queue" reworded as orphaned; billing clarified as scaffold-only; Daily Challenge (Classic variant) recorded as shipped and distinguished from the standalone Phase 4 mode.
- `README.md` "What Is Implemented / Simulated" synced to the above.
- Added explicit "STATUS" banners to `apps/mobile/lib/infra/billing/README.md` and `apps/mobile/lib/l10n/README.md` so specs are not mistaken for shipped code.
- Introduced documentation governance: this changelog + the ADR register under [adr/](adr/).

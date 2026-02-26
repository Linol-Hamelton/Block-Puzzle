# Lumina Blocks - Project Documentation Hub

This repository contains the current implementation and operational documentation for **Lumina Blocks** (Flutter + Flame).

## Current Product State
- Core gameplay loop is implemented and playable on Android/Web/Desktop.
- Sprints 1-7 are implemented (with ad-free strategy selected for monetization).
- Sprint 8 is in progress (soft launch iteration loop with rollout gates).
- Branding was migrated from default placeholders to `Lumina Blocks` assets.

## Repo Areas
- `apps/mobile` - game client (Flutter + Flame).
- `docs` - product, architecture, operations, release, roadmap.
- `data` - analytics/dashboard contracts and run metrics snapshots.
- `scripts` - tuning, rollout-gates, export, smoke-pack automation.
- `distribution` - store metadata and submission assets checklist.

## Build and Test
From `apps/mobile`:
```bash
flutter pub get
flutter analyze
flutter test
```

Run internal smoke pack from repo root:
```powershell
.\scripts\mobile_smoke_pack_v1.ps1
```

## Artifact Locations
Common local artifacts:
- `artifacts/block-puzzle-internal-debug.apk` (internal smoke debug APK)
- `artifacts/block-puzzle-store-release.apk` (store-mode APK for manual install tests)
- `artifacts/android/block-puzzle-release.aab` (store upload bundle)
- `artifacts/block-puzzle-web-build-YYYY-MM-DD.zip` (web build zip)
- `artifacts/windows/block-puzzle-windows-release.zip` (desktop package)

## Main Documentation
- [Product Vision & KPI](docs/product/01_PRODUCT_VISION_KPI.md)
- [Technical Requirements](docs/product/02_TECHNICAL_REQUIREMENTS_SPEC.md)
- [Architecture Catalog](docs/architecture/02_ARCHITECTURE_MODULE_CATALOG.md)
- [Operations Index (Sprint docs)](docs/operations)
- [Roadmap and Status](docs/roadmap/01_ROADMAP_AND_SPRINTS.md)
- [Implementation Status (Actual)](docs/roadmap/05_IMPLEMENTATION_STATUS.md)
- [Roadmap Completeness Audit](docs/roadmap/06_ROADMAP_COMPLETENESS_AUDIT_2026-02-25.md)

## Source of Truth Rule
If documents conflict:
1. `docs/roadmap/05_IMPLEMENTATION_STATUS.md` defines implemented scope.
2. `apps/mobile` code is authoritative for runtime behavior.
3. Older planning docs are treated as historical context unless updated.

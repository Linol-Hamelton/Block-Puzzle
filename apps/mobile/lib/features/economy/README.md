# economy

> **Статус модуля (per DEC-0026 / F6, W4):** Не начато. Каталог сохранён как архитектурный скелет Phase 3 для поддержания ссылочной целостности спецификаций ([docs/roadmap/01_ROADMAP_AND_SPRINTS.md](../../../../docs/roadmap/01_ROADMAP_AND_SPRINTS.md), [docs/architecture/02_ARCHITECTURE_MODULE_CATALOG.md](../../../../docs/architecture/02_ARCHITECTURE_MODULE_CATALOG.md)).

Phase 3 Workstream 3A.

Scope:
- `SoftCurrencyWallet`: Shards (earned in-game) + Crystals (IAP only)
- Persisted to Hive, synced to Firestore under `wallets/{uid}`
- Drip schedule, daily bonus, mission rewards, wheel prizes all flow through this module
- Backend anti-abuse: Cloud Function validates mutations

Empty in Phase 0.

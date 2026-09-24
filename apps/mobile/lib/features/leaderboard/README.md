# leaderboard

> **Статус модуля (per DEC-0026 / F6, W4):** Не начато. Каталог сохранён как архитектурный скелет Phase 4 для поддержания ссылочной целостности спецификаций ([docs/roadmap/01_ROADMAP_AND_SPRINTS.md](../../../../docs/roadmap/01_ROADMAP_AND_SPRINTS.md), [docs/architecture/02_ARCHITECTURE_MODULE_CATALOG.md](../../../../docs/architecture/02_ARCHITECTURE_MODULE_CATALOG.md)).

Phase 4.

Scope:
- Firestore collection `leaderboards/{modeId}/{weekId}/scores`
- Weekly boards per mode (Classic, Time Rush, Daily Challenge, Event)
- Anti-cheat: Cloud Function validates score against session events; throttling; shadow-ban flag
- Friends/social layer in Phase 5

Empty in Phase 0. Hard-frozen until Phase 2 gates pass.

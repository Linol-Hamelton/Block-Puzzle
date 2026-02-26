# services/config-api

Planned service boundary for:
- remote config
- feature flags
- AB assignment
- config audit history

In current repository state, client-side in-memory config is used for development/test loops.
Service implementation can be introduced without breaking client module boundaries.

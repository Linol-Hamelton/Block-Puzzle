# settings

Phase 1 (Restore Purchases button) and Phase 3 (Theme, Language, Accessibility toggles, Haptics toggle).

Scope:
- `RestorePurchasesButton` — Phase 1 Week 3 Day 15
- Theme picker — Phase 3 Workstream 3C
- Language picker — Phase 3 Workstream 3E (localization)
- Accessibility: text scaling, color-blind palette, haptics toggle — Phase 3 Workstream 3E

Settings state today is scattered across [../../domain/progression/player_progress_state.dart](../../domain/progression/player_progress_state.dart) and [../../ui/screens/home_screen.dart](../../ui/screens/home_screen.dart). This feature module will centralize it.

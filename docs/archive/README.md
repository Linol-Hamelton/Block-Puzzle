# Docs Archive

Historical documents moved out of the active decision loop.

## Purpose
- Preserve legacy planning, bisection audits, and historical changelog context.
- Prevent outdated documentation from competing with active source-of-truth files.

## Rule
- Do not use archive docs to infer current implementation status unless active docs explicitly link here.
- Active documentation lives in `docs/` (see `docs/roadmap/05_IMPLEMENTATION_STATUS.md` and `docs/DOCS_CHANGELOG.md`).

## Archive Structure
- `roadmap/`: Completed development and execution plans (`12_DEVELOPMENT_PLAN_2026-09-14.md`, `13_PRIORITIZED_EXECUTION_PLAN_2026-09-14.md`, `14_EXECUTION_PLAN_2026-09-14.md`, `15_POST_DEC0024_PLAN_2026-09-21.md`, and early completeness audits).
- `design/`: Step-by-step diagnostic and bisection reviews from the DEC-0024 investigation (Steps 1b–1k, Reviews 05–15). Active synthesis: `docs/design/01_PERFORMANCE_AND_GRAPHICS_LESSONS.md`.
- `architecture/`: Completed domain design plans for Tetris and Match-3 engines (`04_MULTI_GAME_ENGINE_PLAN.md`, `05_TETRIS_IMPLEMENTATION_PLAN.md`).
- `audit/`: Historical repo audits (Audits 01 through 09). Active review standard: `docs/audit/10_MANDATORY_ADVERSARIAL_REVIEW_PROMPT.md`.
- `root/`: Legacy pre-protocol technical assignments and changelogs.

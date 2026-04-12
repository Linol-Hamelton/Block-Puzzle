# apps/mobile/assets

Assets consumed directly by the Flutter client.

## Folders
- `audio` - runtime SFX assets
- `branding` - app icon and brand images referenced by UI

## Current Status
- `assets/audio/*` - implemented and used at runtime
- `assets/branding/lumina_icon.png` - restored from branded store exports and used by the home screen
- `sprites`, `shaders`, `themes` - planned directories, not active source-of-truth yet

## Asset Pipeline
- Canonical brand guidance lives in `brand_pack/docs/`
- Store exports live in `brand_pack/04_store_google_play` and `brand_pack/05_store_rustore`
- Submission-ready copies live in `distribution/assets/checklist`
- `python generate_assets_from_source.py` now supports fallback restoration when the old `Gemini_*` master sheet is missing

## Rules
- Do not point runtime UI to missing or draft-only assets
- Do not claim an asset is final if it is restored from fallback exports
- Keep brand asset references aligned with `brand_pack` and `distribution/assets/checklist`

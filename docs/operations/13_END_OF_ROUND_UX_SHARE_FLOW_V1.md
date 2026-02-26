# End-of-Round UX + Share Flow v1

## 1. Goal
Improve end-of-round clarity and add optional social sharing path without forcing external SDK complexity.

## 2. UX Improvements
1. Upgraded game-over card with:
- round summary header
- key metrics tiles: `Score`, `Best`, `Level`, `Moves`
- progress strip: daily goals + streak snapshot

2. Action hierarchy:
- `Restart` as primary CTA
- `Revive` (when available)
- optional `Share`

3. New-best feedback:
- explicit `New Best` badge when current score reaches best score.

## 3. Optional Share Flow
1. Config keys:
- `social.share_enabled`
- `social.share_score_hashtag`

2. Current channel:
- `clipboard` (copy result text for manual sharing in messengers/social apps)

3. Result text includes:
- score, best score, level, moves
- daily goals progress
- branded hashtag

## 4. Telemetry
1. `share_score_tapped`
- required: `round_id`, `channel`, `score_total`, `best_score`, `level`, `moves_played`

2. `share_score_result`
- required: `round_id`, `channel`, `success`
- optional: `failure_reason`

3. Both events include UX/balance variant context in optional fields for AB attribution.

## 5. Guardrails
1. Share button is hidden when `social.share_enabled = false`.
2. Clipboard failure is non-blocking for gameplay and only shown as non-fatal feedback.
3. Restart flow remains one-tap and unaffected by share path.

# Publish Execution Checklist (Android)

## 1. Inputs from Product Owner
1. Final store display names:
- RU: `Lumina Blocks: Дзен Пазл`
- EN: `Lumina Blocks: Puzzle Flow`
2. Support email
3. Public privacy policy URL
4. Release version:
- build name (for example `1.0.1`)
- build number (for example `2`)

## 2. Inputs from Engineering Owner
1. Upload keystore (`.jks`)
2. Keystore alias/passwords
3. GitHub secrets configured:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

## 3. Inputs from Marketing/Design
1. Final icon source
2. Store screenshots (phone/tablet)
3. Feature graphic
4. Optional trailer URL

## 4. Release Runbook
1. Trigger GitHub Action `Android Release`.
2. Download signed `AAB` artifact.
3. Upload build to Google Play and RuStore.
4. Fill listing copy from `distribution/metadata`.
5. Complete content rating/data safety forms.
6. Submit for moderation.

## 5. Post-Submission Monitoring
1. Monitor crash-free sessions and ANR trends.
2. Track first real cohort retention/session metrics.
3. Re-run Sprint 8 rollout gates after each cohort window.

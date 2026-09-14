# Publish Execution Checklist (Android)

## 0. BLOCKING PRE-FLIGHT - applicationId is irreversible

> **Scope of this block: distribution and upload, not local builds.**
> A local `flutter build` is reversible and is in fact how the packaged id gets
> verified, so it is allowed. What is blocked until sign-off is anything that
> leaves the machine: uploading to Play, any test track, any shared artifact.
> After the first upload the `applicationId` can never be changed for the life
> of the product - a wrong string means a new listing and the loss of every
> install and review on the old one.

- [x] Owner confirmed the exact string on 2026-09-14: **`ru.luminablocks.game`**,
      recorded in [DEC-0017](../../.ai/DECISIONS.md), which supersedes DEC-0009.
      Reverse-DNS here is a naming convention chosen by the project, not a
      platform requirement; `namespace` and `applicationId` are aligned by
      choice, and changing `namespace` must account for the Kotlin package and
      `MainActivity`.
- [ ] The same string appears in all five places and they match exactly:
  - `apps/mobile/android/app/build.gradle` - `applicationId`
  - `apps/mobile/android/app/build.gradle` - `namespace`
  - the Firebase Android app registration (`google-services.json`)
  - `ANDROID_PACKAGE_NAME` for the `verifyPurchase` function
  - the Play Console listing
- [ ] `flutter build appbundle` output inspected to confirm the packaged id.
- [ ] Build produced **with** `--dart-define` for `APP_ENV`/`APP_FLAVOR`
      (DEC-0007): confirm DI resolved production adapters, not the debug ones.

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

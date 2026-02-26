# Android Publishing Playbook (No iOS)

Last updated: 2026-02-26

## 1. Scope
Included now:
1. Google Play
2. RuStore

Excluded for current phase:
1. iOS/App Store

## 2. Current Readiness
1. Local Android release outputs are generated (`apk`, `aab`).
2. Signed release CI workflow exists: `.github/workflows/android-release.yml`.
3. Android identity is configured:
- `applicationId`: `com.blockpuzzle.game`
- `android:label`: `Lumina Blocks`

## 3. Pre-Publish Checklist
1. Create and secure upload keystore.
2. Configure GitHub secrets:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`
3. Run `Android Release` workflow with target version.
4. Verify artifacts in Actions:
- `block-puzzle-android-release-aab`
- `block-puzzle-android-release-apk`
5. Execute final QA pass on at least:
- 2 phones
- 1 tablet

## 4. Store Listing Content
Use canonical metadata sources:
- `distribution/metadata/google-play`
- `distribution/metadata/rustore`

## 5. Legal and Compliance
1. Provide public privacy policy URL.
2. Provide support email.
3. Complete content rating and data safety questionnaires.

## 6. Market Notes (RU)
1. Google Play billing has regional constraints for Russia.
2. RuStore remains the primary RU monetization distribution channel.

## 7. References
1. https://support.google.com/googleplay/android-developer/answer/11950272
2. https://developer.android.com/guide/app-bundle
3. https://developer.android.com/distribute/google-play/launch
4. https://www.rustore.ru/help/sdk/release-notes

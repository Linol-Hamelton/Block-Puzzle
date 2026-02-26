# GitHub Actions Build Setup

## 1. Security First
1. Never commit PAT or secrets to repository files.
2. Revoke leaked tokens immediately.
3. Use GitHub Actions secrets for signing credentials.

## 2. Workflows in Repository
1. `mobile-ci.yml`
- analyze + test
- Android debug APK build
- Web release build
- artifacts:
  - `block-puzzle-android-debug-apk`
  - `block-puzzle-web-release`

2. `android-release.yml`
- analyze + test
- signed Android release AAB + APK
- artifacts:
  - `block-puzzle-android-release-aab`
  - `block-puzzle-android-release-apk`

## 3. Required Setup
1. Push project to GitHub.
2. Enable Actions in repo settings.
3. For release workflow configure secrets:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

## 4. How to Download Builds
1. Open `Actions` tab.
2. Open workflow run.
3. Download required artifact from `Artifacts` section.

## 5. Optional Sprint 8 Gate Automation
When real cohort metrics are committed, run in CI:
```powershell
.\scripts\run_soft_launch_iteration_002.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json" `
  -FailOnHold
```

This enforces:
1. strict tuning validation
2. dashboard export
3. rollout gate evaluation with `ops_*`
4. CI fail on `hold_and_iterate`

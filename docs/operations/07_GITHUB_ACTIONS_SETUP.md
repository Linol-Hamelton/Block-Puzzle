# GitHub Actions Build Setup

## 1. Security First
1. Revoke the exposed PAT immediately in GitHub settings.
2. Create a new PAT only if needed.
3. Do not store PAT tokens in repository files.

## 2. Workflow in Repository
CI file is already prepared:
[mobile-ci.yml](/d:/Block-Puzzle/.github/workflows/mobile-ci.yml)

It runs:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --debug`
5. `flutter build web --release`
6. Uploads build artifacts

## 3. What You Need to Do
1. Create a GitHub repository.
2. Push this project to `main`.
3. Open GitHub -> `Actions` tab and enable workflows if prompted.
4. Run workflow manually (`Run workflow`) or trigger by push.

## 4. Where to Download Builds
After workflow completes:
1. Open workflow run.
2. Scroll to `Artifacts`.
3. Download:
- `block-puzzle-android-debug-apk`
- `block-puzzle-web-release`

## 5. Recommended Next Step
After CI is stable, add a second workflow for signed Android release (`aab`) with secrets:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

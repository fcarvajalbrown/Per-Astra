# ADR-013: CI/CD Pipeline

**Status:** Accepted
**Date:** 2026-06-23

---

## Decision

**GitHub Actions for CI. Fastlane for distribution. Two workflows.**

---

## Workflow 1: PR Check (`.github/workflows/pr.yml`)

Triggers: every pull request to `main`.

Steps:
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter analyze`
4. `flutter test`

Fails fast on any analysis error or test failure. Required to pass before merge.

---

## Workflow 2: Release Build (`.github/workflows/release.yml`)

Triggers: push of a version tag (`v*.*.*`).

Steps:
1. `flutter pub get` + `build_runner`
2. Build iOS `.ipa` (`flutter build ipa --release`)
3. Build Android `.aab` (`flutter build appbundle --release`)
4. Fastlane `ios` lane: upload `.ipa` to TestFlight
5. Fastlane `android` lane: upload `.aab` to Google Play internal track
6. Create GitHub Release with build artifacts attached

Signing secrets (certificates, keystores, API keys) stored as GitHub Actions encrypted secrets. Never in the repo.

---

## Fastlane Configuration

`fastlane/Fastfile` with two lanes:

```ruby
lane :ios do
  upload_to_testflight(ipa: 'build/ios/ipa/per_astra.ipa')
end

lane :android do
  upload_to_play_store(
    track: 'internal',
    aab: 'build/app/outputs/bundle/release/app-release.aab'
  )
end
```

---

## Packages / Tools

- GitHub Actions (free for public repos)
- Fastlane (`gem install fastlane`)
- `match` (Fastlane) for iOS code signing certificate management

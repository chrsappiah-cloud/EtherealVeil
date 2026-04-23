# EtherealVeil iOS Production Release Checklist

## Completed in codebase

- Disabled CloudKit dependency in persistence startup (`cloudKitDatabase = .none`).
- Added resilient SwiftData fallback to an in-memory container to avoid launch-time crashes if persistent store initialization fails.
- Removed development-only app entitlements so the app no longer declares push or iCloud capabilities by default.
- Disabled SwiftUI previews for the Release target configuration.
- Enabled additional Release stripping/optimization settings (`COPY_PHASE_STRIP`, `DEAD_CODE_STRIPPING`, `STRIP_INSTALLED_PRODUCT`, `SWIFT_OPTIMIZATION_LEVEL`).
- Added repeatable release preflight script at `scripts/release_preflight.sh`.
- Normalized target versioning to `MARKETING_VERSION = 1.0.0`, `CURRENT_PROJECT_VERSION = 1`.
- Aligned test bundle identifiers to production-style suffixes (`.tests`, `.uitests`).
- Set reverse-DNS bundle identifiers: `com.worldclassscholars.etherealveil` (app), `.tests`, `.uitests`.

## Required before App Store submission

- In [Apple Developer Identifiers](https://developer.apple.com/account/resources/identifiers/list), register App IDs for the app and test bundles (or let Xcode Automatic Signing create them on first build):
  - `com.worldclassscholars.etherealveil`
  - `com.worldclassscholars.etherealveil.tests`
  - `com.worldclassscholars.etherealveil.uitests`
- In [App Store Connect](https://appstoreconnect.apple.com/), create the app record using bundle id `com.worldclassscholars.etherealveil` (must match the Xcode target).
- Confirm signing team and profiles are valid for App Store distribution in Xcode Signing & Capabilities.
- Increment `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` for the release.
- Archive with `Any iOS Device (arm64)` and validate in Organizer.
- Fill App Store Connect metadata: privacy details, screenshots, keywords, support URL, and age rating.
- If you add push notifications, iCloud/CloudKit, camera, microphone, or photo library access later, re-add only required capabilities/usage descriptions before submission.

## Recommended validation gates

- Run preflight before every archive: `bash scripts/release_preflight.sh`.
- Initialize and update production tracker: `python3 scripts/appstore_tracker.py ...` (see `APP_STORE_TRACKING_SYSTEM.md`).
- Run a full release build and verify app launch on physical device.
- Verify offline behavior for drawing/painting flows and error states for music streaming URLs.
- Confirm no debug-only UI or logs are exposed in Release builds.

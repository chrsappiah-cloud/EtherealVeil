# Ethereal Veil — Apple Distribution Guide

## Version

- **Marketing:** 1.0.1
- **Build:** 101 (CI stamps `100 + run_number` on release tags)

## Bundle ID

`com.worldclassscholars.etherealveil`

## Team

`TM2WG7HH96` (World Class Scholars)

## CI (every push / PR)

Workflow: `.github/workflows/ci.yml`

- XcodeGen project generation
- Plist lint, SwiftLint (strict), YAML validation
- `swift test` (87 tests)
- Unsigned Release `xcodebuild build` for iOS

## CD (TestFlight / App Store Connect)

Workflow: `.github/workflows/cd.yml`

**Trigger:** push tag `v1.0.2` (semver) or **workflow_dispatch**.

### Required GitHub secrets

| Secret | Purpose |
|--------|---------|
| `BUILD_CERTIFICATE_BASE64` | Apple Distribution `.p12` (base64) |
| `P12_PASSWORD` | Certificate password |
| `BUILD_PROVISION_PROFILE_BASE64` | App Store provisioning profile (base64) |
| `KEYCHAIN_PASSWORD` | Ephemeral CI keychain password |
| `ASC_KEY_ID` | App Store Connect API key ID |
| `ASC_ISSUER_ID` | App Store Connect issuer ID |
| `ASC_PRIVATE_KEY_BASE64` | `.p8` API key (base64) |

### Required GitHub environment

Create environment **`production`** (Settings → Environments) and attach the secrets above.

## Regenerate assets

```bash
pip install pillow
python3 scripts/generate_distribution_assets.py
```

Outputs:

- `EtherealVeil/Assets.xcassets/AppIcon.appiconset/*.png`
- `distribution/app-store/screenshots/en-US/iphone_67_*.png`
- `distribution/app-store/asset_manifest.json`

## App Store Connect checklist

1. Upload build via CD or Xcode Organizer.
2. Paste metadata from `distribution/app-store/metadata/en-US/`.
3. Upload screenshots from `distribution/app-store/screenshots/en-US/`.
4. Complete review notes from `distribution/app-store/review_information.md`.
5. Submit for review when TestFlight beta is approved.

## Local archive (signed machine)

```bash
xcodegen generate
xcodebuild archive \
  -project EtherealVeil.xcodeproj \
  -scheme EtherealVeil \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath build/EtherealVeil.xcarchive
xcodebuild -exportArchive \
  -archivePath build/EtherealVeil.xcarchive \
  -exportOptionsPlist EtherealVeil/ExportOptions.plist \
  -exportPath build/export
```

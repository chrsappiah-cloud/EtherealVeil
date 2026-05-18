# GitHub Secrets — Automated TestFlight Setup

## Quick start (one-time, on your Mac)

```bash
# 1. Export base64 values to paste into GitHub (or use step 2)
P12_PATH=~/Downloads/distribution.p12 \
PP_PATH=~/Downloads/EtherealVeil_AppStore.mobileprovision \
P8_PATH=~/Downloads/AuthKey_XXXXXX.p8 \
P12_PASSWORD='your-p12-password' \
ASC_KEY_ID='XXXXXXXXXX' \
ASC_ISSUER_ID='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' \
./scripts/export_signing_secrets.sh

# 2. Push secrets via GitHub CLI (recommended)
P12_PATH=... PP_PATH=... P8_PATH=... \
P12_PASSWORD=... KEYCHAIN_PASSWORD=$(openssl rand -base64 24) \
ASC_KEY_ID=... ASC_ISSUER_ID=... \
./scripts/push_github_secrets.sh

# 3. Create production environment (if not exists)
gh api --method PUT "repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/environments/production"

# 4. Validate
gh workflow run "Distribution — Validate Setup"

# 5. Deploy to TestFlight
git tag v1.1.2 && git push origin v1.1.2
# or
gh workflow run "CD — TestFlight (Production)" -f marketing_version=1.1.0
```

## Required secrets

| Secret | Purpose |
|--------|---------|
| `BUILD_CERTIFICATE_BASE64` | Apple Distribution `.p12` (base64) |
| `P12_PASSWORD` | Certificate export password |
| `BUILD_PROVISION_PROFILE_BASE64` | App Store `.mobileprovision` (base64) |
| `KEYCHAIN_PASSWORD` | Ephemeral CI keychain password (any strong random string) |
| `ASC_KEY_ID` | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_PRIVATE_KEY_BASE64` | API `.p8` key file (base64) |

Attach all secrets to the **`production`** environment (Settings → Environments → production).

## Automated workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| **CD — TestFlight** | Tag `v*.*.*` or manual | Tests → archive → validate IPA → upload TestFlight → bundle artifacts |
| **Distribution — Release Bundle** | Tag `v*.*.*` | Regenerates images/PDF → GitHub Release + zip |
| **Distribution — Validate Setup** | Manual | Fails fast if any secret is missing |

## App Store Connect checklist

1. Register bundle ID: `com.worldclassscholars.etherealveil`
2. Create app **Ethereal Veil**
3. Create subscription group **Studio Pro** with products in `distribution/app-store/connect/products.json`
4. Upload screenshots from `Promotional/` or `distribution/app-store/screenshots/en-US/`
5. Paste metadata from `distribution/app-store/metadata/en-US/`

## Local TestFlight (without GitHub)

```bash
chmod +x scripts/local_testflight_archive.sh
./scripts/local_testflight_archive.sh
```

Or use Fastlane: `bundle install && ASC_KEY_PATH=AuthKey.p8 ASC_KEY_ID=... ASC_ISSUER_ID=... bundle exec fastlane beta`

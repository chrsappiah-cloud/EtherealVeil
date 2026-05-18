# GitHub Secrets — TestFlight Upload

The CD workflow **quality gate passed** on tag `v1.0.2`. The archive step failed because signing secrets are not configured in this repository yet.

## 1. Create `production` environment

GitHub → **Settings** → **Environments** → **New environment** → name: `production`

## 2. Add repository secrets (or environment secrets)

| Secret | How to obtain |
|--------|----------------|
| `BUILD_CERTIFICATE_BASE64` | Export Apple Distribution `.p12` from Keychain → `base64 -i cert.p12 \| pbcopy` |
| `P12_PASSWORD` | Password used when exporting the `.p12` |
| `BUILD_PROVISION_PROFILE_BASE64` | Download App Store profile from Apple Developer → `base64 -i profile.mobileprovision \| pbcopy` |
| `KEYCHAIN_PASSWORD` | Any strong random string (CI-only ephemeral keychain) |
| `ASC_KEY_ID` | App Store Connect → Users and Access → Keys |
| `ASC_ISSUER_ID` | Same page (Issuer ID at top) |
| `ASC_PRIVATE_KEY_BASE64` | Download `.p8` once → `base64 -i AuthKey_XXXX.p8 \| pbcopy` |

## 3. Re-run deployment

After secrets are saved:

```bash
git tag -d v1.0.2   # local only, optional
git push origin v1.0.2  # re-run if you delete remote tag
# or
gh workflow run "CD — TestFlight (Production)" \
  --ref feature/tabs-music-drawing-painting-studio \
  -f marketing_version=1.0.1
```

## 4. App Store Connect

1. Register bundle ID: `com.worldclassscholars.etherealveil`
2. Create app record **Ethereal Veil**
3. Upload screenshots from `distribution/app-store/screenshots/en-US/`
4. Paste metadata from `distribution/app-store/metadata/en-US/`

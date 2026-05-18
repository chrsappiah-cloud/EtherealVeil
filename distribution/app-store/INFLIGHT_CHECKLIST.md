# In-flight version checklist

**App Store Connect:** [iOS version in flight](https://appstoreconnect.apple.com/apps/6763116253/distribution/ios/version/inflight)

| Field | Current in ASC | Action |
|--------|----------------|--------|
| Version | **1.0** | Change to **1.1.0** in ASC *or* upload a build with marketing version 1.0 |
| Locale | en-AU (primary) | Paste metadata from `metadata/en-AU/` |
| Build | **Uploaded 2026-05-19** (1.1.0 / 110) | Wait for processing in ASC, then select on this page |
| Screenshots | Missing | Upload from `screenshots/en-AU/iphone_67_*.png` |
| Age rating | Incomplete | Complete questionnaire (see `submission_responses.md`) |
| Review notes | Missing | Paste from `review_information.md` |

## Paste — Description (en-AU)

See `metadata/en-AU/description.txt`.

## Paste — Keywords

See `metadata/en-AU/keywords.txt`.

## Paste — What's New

See `metadata/en-AU/release_notes.txt`.

## Paste — Subtitle

Gold creative studio

## Paste — Promotional text

Draw, paint, and listen — your gold studio on iPhone and iPad.

## Paste — Support URL

https://github.com/chrsappiah-cloud/EtherealVeil

## Paste — Privacy Policy URL

https://github.com/chrsappiah-cloud/EtherealVeil/blob/master/distribution/PRIVACY.md

## Paste — Review notes

See `review_information.md` section **Notes for reviewer**.

## Version alignment

The repo builds **1.1.0 (110)**. The in-flight record is **1.0**. After the first upload, set the App Store version string to **1.1.0** on this page, then select build **110**.

## API automation

Requires `AuthKey_FTCDLIFPW2IU.p8` (App Manager) in `~/Downloads` or `ASC_KEY_PATH`:

```bash
export ASC_ISSUER_ID=70c46c69-5d6d-438d-b300-31df2b93163a
export ASC_KEY_ID=FTCDLIFPW2IU
export ASC_KEY_PATH=~/Downloads/AuthKey_FTCDLIFPW2IU.p8
python3 scripts/app_store_connect_deploy.py --all
```

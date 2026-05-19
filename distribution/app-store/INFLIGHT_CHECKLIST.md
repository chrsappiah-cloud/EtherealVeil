# App Store version 1.1.0 — submitted for review

**Status:** `WAITING_FOR_REVIEW` (submitted 2026-05-19)  
**Build:** 1.1.0 (110) — VALID  
**Release:** Manual (you release after approval)

| Link | URL |
|------|-----|
| Version | https://appstoreconnect.apple.com/apps/6763116253/distribution/ios/version/inflight |
| App Review | https://appstoreconnect.apple.com/apps/6763116253/distribution/appstore/reviewsubmissions |
| Resolution Center | https://appstoreconnect.apple.com/apps/6763116253/distribution/activity/ios/resolutioncenter |

## Completed

| Item | Status |
|------|--------|
| Version string | **1.1.0** |
| Locale | en-AU (primary) |
| Build 110 | Attached |
| Screenshots | 5× iPhone 6.7, 2× iPhone 6.5, 2× iPad Pro 12.9" |
| Metadata | Description, keywords, URLs, review contact |
| Age rating | Completed via API |
| App Privacy | Published (required for submit) |
| Pricing | Free (AUS base) |
| Content rights | Does not use third-party content |
| Submit for review | **Done** |

## After approval

1. Open the version page in App Store Connect.
2. Confirm **Release** is set to **Manually release this version** (current).
3. When status is **Pending Developer Release** or **Ready for Sale**, click **Release this version**.

## If Apple requests changes

1. Read the message in **Resolution Center**.
2. Fix the issue in the repo, bump build (e.g. 111), upload via TestFlight/CD or `scripts/local_testflight_archive.sh`.
3. Attach the new build on the same version (or create 1.1.1 if needed).
4. Resubmit:

```bash
export ASC_ISSUER_ID=70c46c69-5d6d-438d-b300-31df2b93163a
export ASC_KEY_ID=TN35FDL978
export ASC_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_TN35FDL978.p8
export APP_VERSION=1.1.0
./scripts/finish_app_store_submission.sh
```

## Desktop package

Refresh: `./scripts/copy_submission_to_desktop.sh` → `~/Desktop/EtherealVeil-AppStore-Submission/`

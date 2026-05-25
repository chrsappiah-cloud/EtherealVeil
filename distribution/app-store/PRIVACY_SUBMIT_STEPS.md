# App Privacy (required before submit)

Apple removed the public `appDataUsages` API. Privacy labels must be published once in App Store Connect:

1. Open [App Privacy](https://appstoreconnect.apple.com/apps/6763116253/distribution/privacy)
2. Choose **Data Not Collected** (the app stores art locally; optional iCloud is user-controlled; no ads or tracking).
3. Click **Publish**.

Then re-run submission:

```bash
export ASC_ISSUER_ID=70c46c69-5d6d-438d-b300-31df2b93163a
export ASC_KEY_ID=TN35FDL978
export ASC_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_TN35FDL978.p8
export APP_VERSION=1.1.0
./scripts/finish_app_store_submission.sh
```

Reference JSON (for future fastlane if API returns): `distribution/app-store/app_privacy_details.json`

# App Store Connect — Distribution & Review Responses

App: **Ethereal Veil** · Apple ID `6763116253` · Bundle `com.worldclassscholars.etherealveil`  
API Key: `A863K5FF84` · Issuer: `70c46c69-5d6d-438d-b300-31df2b93163a`

**Status (2026-05-26):** Version 1.1.0 · Build **113** · responding to information request  
**Review submission:** `821ef3ad-bd58-4dd3-9407-dc6a0275c494`

---

## Apple information request (2026-05-25)

| Question | Answer |
|----------|--------|
| Username/password login? | **No** — local email + display name only; no password field |
| Create account? | Account tab → email + display name → **Sign in or create account** |
| IAP location after demo? | Account tab → **Studio Pro subscriptions (In-App Purchase)** (first section below header) |

Resolution Center reply: `resolution_center_response.md`

---

## Rejection responses (May 2026 — build 112)

| Guideline | Issue | Resolution |
|-----------|--------|------------|
| **2.1(a)** | Could not access all features | **Enable Full Feature Demo** on Account tab |
| **2.1(b)** | IAPs not submitted | Studio Pro monthly + yearly submitted with version |
| **2.5.4** | `UIBackgroundModes` audio | Removed; foreground music only |

Build **113** additionally clarifies account model and always shows IAP section on Account tab.

---

## App Review Information

| Field | Response |
|--------|----------|
| **Sign-in required** | No |
| **Demo account** | Not required — use **Enable Full Feature Demo** |
| **Notes** | See `review_information.md` |

---

## In-App Purchases (Studio Pro)

| Product ID | ASC subscription ID | State |
|------------|---------------------|--------|
| `com.worldclassscholars.etherealveil.studio.monthly` | `6772456273` | Ready with version |
| `com.worldclassscholars.etherealveil.studio.yearly` | `6772456583` | Ready with version |

Subscription group: **Studio Pro** (`22109037`)

---

## Submit / resubmit

```bash
export ASC_ISSUER_ID=70c46c69-5d6d-438d-b300-31df2b93163a
export ASC_KEY_ID=A863K5FF84
export ASC_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_A863K5FF84.p8
export APP_VERSION=1.1.0
export APP_BUILD_NUMBER=113
./scripts/finish_app_store_submission.sh
```

Configure subscriptions: `python3 scripts/configure_studio_pro_subscriptions.py`

Reply in Resolution Center: paste `distribution/app-store/resolution_center_response.md`

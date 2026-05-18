# App Store Connect — Distribution & Review Responses

App: **Ethereal Veil** · Apple ID `6763116253` · Bundle `com.worldclassscholars.etherealveil`  
Issuer ID: `70c46c69-5d6d-438d-b300-31df2b93163a` · API Key ID: `FTCDLIFPW2IU`

---

## Version metadata (en-AU primary)

| Field | Response |
|--------|----------|
| **Name** | Ethereal Veil |
| **Subtitle** | Gold creative studio |
| **Description** | See `metadata/en-AU/description.txt` |
| **Keywords** | See `metadata/en-AU/keywords.txt` |
| **What's New** | See `metadata/en-AU/release_notes.txt` |
| **Promotional text** | See `metadata/en-AU/promotional_text.txt` |
| **Support URL** | https://github.com/chrsappiah-cloud/EtherealVeil |
| **Privacy Policy URL** | https://github.com/chrsappiah-cloud/EtherealVeil/blob/master/distribution/PRIVACY.md |

---

## App Review Information

| Field | Response |
|--------|----------|
| **First name** | Christopher |
| **Last name** | Appiah-Thompson |
| **Email** | chrsappiah@gmail.com |
| **Phone** | (set in App Store Connect contact) |
| **Sign-in required** | No — core studio works without login |
| **Demo account** | Not required |

### Notes for reviewer

1. **Draw / Paint** — Open Draw or Paint, drag on the canvas. Toolbar: tools, colours, undo/redo, Save to Library.
2. **Music** — Tap Play on the gold music strip or open **Playlist**. Streams royalty-free MP3 from archive.org (`NSAppTransportSecurity` exception in Info.plist).
3. **Library** — Appears after Save in Draw or Paint.
4. **Cloud** — Backup toggles and checkpoints; CloudKit on signed builds with the configured container.
5. **Account / Studio Pro** — Optional StoreKit subscriptions (`studio.monthly` / `studio.yearly`). Sandbox purchases can be tested with a Sandbox Apple ID.
6. **Encryption** — `ITSAppUsesNonExemptEncryption` = false (HTTPS only, no custom cryptography).

---

## Export compliance

| Question | Answer |
|----------|--------|
| Uses encryption? | Yes — standard HTTPS/TLS only |
| Exempt from export documentation? | **Yes** — qualifies for exemption (only Apple OS crypto + HTTPS) |
| Info.plist | `ITSAppUsesNonExemptEncryption` = **false** |

---

## Age rating (questionnaire)

| Topic | Answer |
|--------|--------|
| Cartoon/fantasy violence | None |
| Realistic violence | None |
| Sexual content | None |
| Profanity | None |
| Horror | None |
| Mature themes | None |
| Gambling | None |
| Unrestricted web access | **No** — in-app browser not provided; music URLs are app-controlled |
| User-generated content | **No** — art stays on device / user's iCloud |
| Messaging/chat | None |
| Advertising | **No** third-party ads |
| Made for kids | **No** |
| **Suggested rating** | **4+** |

---

## Content rights

| Question | Answer |
|----------|--------|
| Third-party content | Music from archive.org (public domain / royalty-free classical). App UI and assets are original. |
| Licensed content | None requiring separate licence upload |

---

## App Privacy (nutrition labels)

| Data type | Collected | Linked to user | Tracking |
|-----------|-----------|----------------|----------|
| Purchases | Yes (StoreKit) | Yes | No |
| User content (drawings) | On device / optional iCloud | User's iCloud | No |
| Identifiers | None for ads | — | No |

---

## In-App Purchases

| Product ID | Type |
|------------|------|
| `com.worldclassscholars.etherealveil.studio.monthly` | Auto-renewable subscription |
| `com.worldclassscholars.etherealveil.studio.yearly` | Auto-renewable subscription |

Subscription group: **Studio Pro** — configure pricing and localisation in App Store Connect if not already live.

---

## Submission checklist

- [ ] Build uploaded and processing complete in TestFlight / App Store Connect
- [ ] Build selected on version **1.1.0** (or aligned marketing version)
- [ ] Screenshots for required device sizes (6.7", 6.5", iPad Pro 12.9" if universal)
- [ ] Age rating questionnaire completed
- [ ] App Privacy questionnaire completed
- [ ] IAP products approved or ready for review with app
- [ ] Export compliance answered
- [ ] Submit for Review

Automate: `python3 scripts/app_store_connect_deploy.py --metadata --age-rating --review --submit`

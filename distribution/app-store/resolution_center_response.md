# Resolution Center — Reply to App Review (1.1.0, build 113)

Paste into **App Store Connect → Resolution Center** when replying to the information request on submission `821ef3ad-bd58-4dd3-9407-dc6a0275c494`.

---

Hello App Review,

Thank you for the follow-up questions on submission `821ef3ad-bd58-4dd3-9407-dc6a0275c494`. We have clarified the account model in build **113** (version **1.1.0**) and updated the Account tab so Studio Pro subscriptions are always visible.

### How do users login with the username and password?

**Ethereal Veil does not use a username/password login.** There is no password field, no remote authentication server, and no credentials to provide.

Users sign in locally on the **Account** tab by entering an **email** and **display name**, then tapping **Sign in or create account**. This creates or restores a local studio profile stored on the device only.

### How do users create a new account within the app?

1. Open the **Account** tab.
2. Enter any email (for example, `reviewer@example.com`) and a display name.
3. Tap **Sign in or create account**.

If the email is new, the app creates a local free-tier profile automatically. No Apple ID, email verification, or password is required for this local account.

### Where can reviewers locate the IAP after Enable Full Feature Demo?

Studio Pro subscriptions remain on the **Account** tab in the section titled **Studio Pro subscriptions (In-App Purchase)** — the **first section below the Account header** (above the demo controls).

In build **113** you will see:

- **Studio Pro Monthly** — `com.worldclassscholars.etherealveil.studio.monthly`
- **Studio Pro Yearly** — `com.worldclassscholars.etherealveil.studio.yearly`

Tap a plan to start the App Store purchase sheet. If prices are still loading, tap **Reload subscription plans**.

**Enable Full Feature Demo** unlocks every feature for review but does **not** remove or hide the subscription section above it.

Please review **build 113** (original App Store icon artwork restored). Contact: chrsappiah@gmail.com

---

**Active submission:** `821ef3ad-bd58-4dd3-9407-dc6a0275c494` (build **113** attached 2026-05-26)

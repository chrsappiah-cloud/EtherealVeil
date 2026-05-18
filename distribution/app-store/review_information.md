# App Store Review Information — Ethereal Veil 1.0.1

## Contact

- **First name:** Christopher
- **Last name:** Appiah-Thompson
- **Phone:** (provide in App Store Connect)
- **Email:** chrsappiah@gmail.com

## Demo account

Not required. All features work without login.

## Notes for reviewer

1. **Drawing & painting** — Open the Draw or Paint tab and drag on the canvas. Use toolbar controls for tools, colors, undo/redo, and Save to add a session to Library.
2. **Music** — Tap Play on the gold music strip. Playlist is available from the hero **Playlist** button. Audio streams royalty-free MP3 files from archive.org (ATS exception declared in Info.plist).
3. **Library** — Saved sessions appear after using Save in Draw or Paint.
4. **Cloud** — Backup toggles and manual checkpoints are UI state backed by SwiftData; CloudKit requires the configured container on a signed build.
5. **Encryption** — `ITSAppUsesNonExemptEncryption` is `false` (HTTPS only, no custom cryptography).

## Export compliance

Uses standard HTTPS for music streaming. No proprietary encryption beyond Apple OS APIs.

## Age rating guidance

4+ — creative tools, no user-generated public content, no social features.

## TestFlight

CI/CD uploads on semver tag `v*.*.*` via GitHub Actions workflow `CD — TestFlight (Production)`.

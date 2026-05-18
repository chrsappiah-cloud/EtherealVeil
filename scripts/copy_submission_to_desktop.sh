#!/usr/bin/env bash
# Copy all App Store submission assets to Desktop for drag-and-drop into App Store Connect.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/Desktop/EtherealVeil-AppStore-Submission"

rm -rf "$DEST"
mkdir -p "$DEST/metadata" "$DEST/screenshots" "$DEST/review"

cp -R "$ROOT/distribution/app-store/metadata/en-AU/"* "$DEST/metadata/"
cp "$ROOT/distribution/app-store/screenshots/en-AU/"*.png "$DEST/screenshots/"
cp "$ROOT/distribution/app-store/review_information.md" "$DEST/review/"
cp "$ROOT/distribution/app-store/submission_responses.md" "$DEST/"
cp "$ROOT/distribution/PRIVACY.md" "$DEST/"
cp "$ROOT/distribution/app-store/INFLIGHT_CHECKLIST.md" "$DEST/README_SUBMIT.md"
cp -R "$ROOT/Promotional/Promo_"*.png "$DEST/promotional/" 2>/dev/null || mkdir -p "$DEST/promotional" && cp "$ROOT/Promotional/Promo_"*.png "$DEST/promotional/"

cat > "$DEST/SUBMIT_STEPS.txt" <<'EOF'
Ethereal Veil — App Store submission (build 110 ready)

1. Open: https://appstoreconnect.apple.com/apps/6763116253/distribution/ios/version/inflight
2. Set Version to 1.1.0 (build 110 is marketing version 1.1.0)
3. Build → select build 110
4. App Information: paste metadata/*.txt fields (en-AU)
5. Screenshots: upload all files in screenshots/ (iPhone 6.7)
6. App Review: paste review/review_information.md notes
7. Age Rating, App Privacy, Export compliance (see submission_responses.md)
8. Add for Review → Submit

Automate later: place AuthKey_FTCDLIFPW2IU.p8 (App Manager) and run:
  ./scripts/generate_github_secrets.sh && ./scripts/app_store_submit.sh
EOF

echo "Copied submission package to: $DEST"
open "https://appstoreconnect.apple.com/apps/6763116253/distribution/ios/version/inflight" 2>/dev/null || true

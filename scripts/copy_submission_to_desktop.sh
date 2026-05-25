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

BUILD="$(/usr/libexec/PlistBuddy -c "Print :CURRENT_PROJECT_VERSION" "$ROOT/project.yml" 2>/dev/null | sed 's/"//g' || echo "111")"
cat > "$DEST/SUBMIT_STEPS.txt" <<EOF
Ethereal Veil — App Store 1.1.0 (build ${BUILD})

STATUS: Resubmit after review fixes (build ${BUILD})

Track review:
  https://appstoreconnect.apple.com/apps/6763116253/distribution/appstore/reviewsubmissions

After approval (manual release):
  1. Open version inflight URL
  2. Click "Release this version"

Resubmit after rejection:
  export ASC_ISSUER_ID=70c46c69-5d6d-438d-b300-31df2b93163a
  export ASC_KEY_ID=TN35FDL978
  export ASC_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_TN35FDL978.p8
  ./scripts/finish_app_store_submission.sh
EOF

echo "Copied submission package to: $DEST"
open "https://appstoreconnect.apple.com/apps/6763116253/distribution/ios/version/inflight" 2>/dev/null || true

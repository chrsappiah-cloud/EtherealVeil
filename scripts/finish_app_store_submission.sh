#!/usr/bin/env bash
# Finalize App Store submission: refresh Desktop bundle, try API submit, open ASC.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FTCD="$HOME/.appstoreconnect/private_keys/AuthKey_FTCDLIFPW2IU.p8"
if [[ ! -f "$FTCD ]]; then FTCD="$HOME/Downloads/AuthKey_FTCDLIFPW2IU.p8"; fi

"$ROOT/scripts/copy_submission_to_desktop.sh"

if [[ -f "$FTCD" ]]; then
  echo "Found App Manager key — running automated deliver + submit..."
  export ASC_ISSUER_ID="${ASC_ISSUER_ID:-70c46c69-5d6d-438d-b300-31df2b93163a}"
  export ASC_KEY_ID=FTCDLIFPW2IU
  export ASC_KEY_PATH="$FTCD"
  export APP_VERSION="${APP_VERSION:-1.1.0}"
  "$ROOT/scripts/generate_github_secrets.sh" 2>/dev/null || true
  "$ROOT/scripts/prepare_deliver_metadata.sh"
  cd "$ROOT/fastlane" && bundle exec fastlane deliver_submit
  echo "Submitted via API."
  exit 0
fi

echo ""
echo "Build 110 (1.1.0) is VALID. Complete submission in App Store Connect:"
echo "  https://appstoreconnect.apple.com/apps/6763116253/distribution/ios/version/inflight"
echo ""
echo "Desktop package: ~/Desktop/EtherealVeil-AppStore-Submission/"
echo "Steps: SUBMIT_STEPS.txt"
echo ""
echo "For full automation, add AuthKey_FTCDLIFPW2IU.p8 then re-run this script."

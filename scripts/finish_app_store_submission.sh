#!/usr/bin/env bash
# Finalize App Store submission: refresh Desktop bundle, try API submit, open ASC.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ASC_KEY="${ASC_KEY_PATH:-}"
if [[ -z "$ASC_KEY" || ! -f "$ASC_KEY" ]]; then
  for candidate in \
    "$HOME/.appstoreconnect/private_keys/AuthKey_TN35FDL978.p8" \
    "$HOME/Downloads/AuthKey_TN35FDL978.p8"; do
    if [[ -f "$candidate" ]]; then
      ASC_KEY="$candidate"
      break
    fi
  done
fi

"$ROOT/scripts/copy_submission_to_desktop.sh"
python3 "$ROOT/scripts/generate_distribution_assets.py"
"$ROOT/scripts/prepare_deliver_metadata.sh"

if [[ -f "$ASC_KEY" ]]; then
  echo "Running App Store Connect automation (TN35FDL978)..."
  export ASC_ISSUER_ID="${ASC_ISSUER_ID:-70c46c69-5d6d-438d-b300-31df2b93163a}"
  export ASC_KEY_ID="${ASC_KEY_ID:-TN35FDL978}"
  export ASC_KEY_PATH="$ASC_KEY"
  export APP_VERSION="${APP_VERSION:-1.1.0}"
  python3 "$ROOT/scripts/app_store_connect_deploy.py" --content-rights --pricing --review --attach-build
  cd "$ROOT/fastlane" && bundle exec fastlane deliver_submit || SUBMIT_EXIT=$?
  if [[ "${SUBMIT_EXIT:-0}" -ne 0 ]]; then
    echo ""
    echo "If submit failed on App Privacy, publish labels in App Store Connect:"
    echo "  https://appstoreconnect.apple.com/apps/6763116253/distribution/privacy"
    echo "  Steps: distribution/app-store/PRIVACY_SUBMIT_STEPS.md"
    open "https://appstoreconnect.apple.com/apps/6763116253/distribution/privacy" 2>/dev/null || true
    exit "${SUBMIT_EXIT}"
  fi
  echo "Submitted for App Store review."
  exit 0
fi

echo ""
echo "Build 110 (1.1.0) is VALID. Complete submission in App Store Connect:"
echo "  https://appstoreconnect.apple.com/apps/6763116253/distribution/ios/version/inflight"
echo ""
echo "Desktop package: ~/Desktop/EtherealVeil-AppStore-Submission/"
echo "Steps: SUBMIT_STEPS.txt"
echo ""
echo "For full automation, add AuthKey_TN35FDL978.p8 then re-run this script."

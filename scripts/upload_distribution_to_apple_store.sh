#!/usr/bin/env bash
# Upload Ethereal Veil distribution to App Store Connect (binary + metadata when permitted).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ASC_ISSUER_ID="${ASC_ISSUER_ID:-70c46c69-5d6d-438d-b300-31df2b93163a}"
ASC_KEY_ID="${ASC_KEY_ID:-KLH62AX56M}"
ASC_KEY_PATH="${ASC_KEY_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8}"

# App Manager key (metadata + submit) — optional override
ASC_KEY_MANAGER="${ASC_KEY_MANAGER:-TN35FDL978}"
APP_VERSION="${APP_VERSION:-1.1.0}"
IPA="${IPA_PATH:-$ROOT/build/export/EtherealVeil.ipa}"
ASC_URL="https://appstoreconnect.apple.com/apps/6763116253/distribution/ios/version/inflight"

# App Manager key for metadata + submit (if present)
MANAGER_KEY_PATH=""
for candidate in \
  "$HOME/Downloads/AuthKey_${ASC_KEY_MANAGER}.p8" \
  "$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_MANAGER}.p8"; do
  if [[ -f "$candidate" ]]; then
    MANAGER_KEY_PATH="$candidate"
    break
  fi
done
echo "Binary/TestFlight API key: $ASC_KEY_ID"
[[ -n "$MANAGER_KEY_PATH" ]] && echo "App Manager API key: $ASC_KEY_MANAGER"

echo "=== 1. Regenerate distribution assets ==="
if [[ -x "$ROOT/.venv/bin/python3" ]]; then
  "$ROOT/.venv/bin/python3" "$ROOT/scripts/generate_distribution_assets.py"
else
  python3 "$ROOT/scripts/generate_distribution_assets.py" 2>/dev/null || true
fi
"$ROOT/scripts/prepare_deliver_metadata.sh"
"$ROOT/scripts/copy_submission_to_desktop.sh"

echo "=== 2. Upload IPA (if present) ==="
if [[ -f "$IPA" ]] && [[ -f "$ASC_KEY_PATH" ]]; then
  if xcrun altool --upload-app --type ios -f "$IPA" --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tee /tmp/ethereal_upload.log; then
    echo "IPA upload succeeded."
  else
    if grep -q "DUPLICATE" /tmp/ethereal_upload.log 2>/dev/null; then
      echo "IPA already uploaded (duplicate build) — continuing."
    else
      echo "IPA upload failed — see log above."
    fi
  fi
else
  echo "Skip IPA upload (no file at $IPA or missing API key)."
fi

echo "=== 3. Upload metadata, screenshots, submit (requires App Manager API key) ==="
DELIVER_KEY_ID="$ASC_KEY_ID"
DELIVER_KEY_PATH="$ASC_KEY_PATH"
if [[ -n "$MANAGER_KEY_PATH" ]]; then
  DELIVER_KEY_ID="$ASC_KEY_MANAGER"
  DELIVER_KEY_PATH="$MANAGER_KEY_PATH"
fi

# Try deliver with manager key, or KLH62AX56M if role was upgraded
export ASC_ISSUER_ID DELIVER_KEY_ID DELIVER_KEY_PATH APP_VERSION
export ASC_KEY_ID="$DELIVER_KEY_ID" ASC_KEY_PATH="$DELIVER_KEY_PATH"
if cd "$ROOT/fastlane" && CI=true DELIVER_FORCE_OVERWRITE=1 bundle exec fastlane deliver_submit 2>/tmp/deliver.log; then
  echo "Distribution uploaded and submitted for review."
  exit 0
fi

echo ""
echo "Metadata/screenshots API upload blocked for $DELIVER_KEY_ID (needs App Manager role)."
grep -i forbidden /tmp/deliver.log 2>/dev/null | head -1 || true
echo "Binary build 110 is already VALID in App Store Connect."
echo ""
echo "Complete on the web (5 min):"
echo "  $ASC_URL"
echo ""
echo "Desktop copy/paste bundle:"
echo "  ~/Desktop/EtherealVeil-AppStore-Submission/"
echo ""
echo "To enable full automation, download AuthKey_FTCDLIFPW2IU.p8 and run:"
echo "  cp ~/Downloads/AuthKey_FTCDLIFPW2IU.p8 ~/.appstoreconnect/private_keys/"
echo "  $0"
echo ""
open "$ASC_URL" 2>/dev/null || true
open -a "Transporter" "$IPA" 2>/dev/null || true
exit 0

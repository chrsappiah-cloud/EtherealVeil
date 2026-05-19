#!/usr/bin/env bash
# Install App Store Connect App Manager key FTCDLIFPW2IU and push GitHub secrets.
set -euo pipefail

KEY_ID=FTCDLIFPW2IU
ISSUER_ID=70c46c69-5d6d-438d-b300-31df2b93163a
DEST_DIR="$HOME/.appstoreconnect/private_keys"
DEST="$DEST_DIR/AuthKey_${KEY_ID}.p8"

mkdir -p "$DEST_DIR"

if [[ -n "${1:-}" ]]; then
  SRC="$1"
elif [[ -f "$HOME/Downloads/AuthKey_${KEY_ID}.p8" ]]; then
  SRC="$HOME/Downloads/AuthKey_${KEY_ID}.p8"
else
  cat <<EOF
App Manager API key: ${KEY_ID}
Issuer ID: ${ISSUER_ID}

The .p8 private key file was not found. Apple only lets you download it ONCE when the key is created.

1. Open: https://appstoreconnect.apple.com/access/integrations/api
2. Find key ID ${KEY_ID} (or create new key with App Manager access)
3. Download AuthKey_${KEY_ID}.p8 to ~/Downloads/
4. Re-run:
   ./scripts/install_ftcd_api_key.sh ~/Downloads/AuthKey_${KEY_ID}.p8

Or paste the path to your .p8 file as the first argument.
EOF
  open "https://appstoreconnect.apple.com/access/integrations/api" 2>/dev/null || true
  exit 1
fi

cp "$SRC" "$DEST"
chmod 600 "$DEST"
echo "Installed: $DEST"

# Verify write access
python3 <<PY
import jwt, time, pathlib, requests
key = pathlib.Path("$DEST").read_text()
token = jwt.encode(
    {"iss": "$ISSUER_ID", "exp": int(time.time())+1200, "aud": "appstoreconnect-v1"},
    key, algorithm="ES256", headers={"kid": "$KEY_ID", "typ": "JWT"},
)
r = requests.patch(
    "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/dbf6e9b3-82db-488e-b5d5-999ba9fc83ce",
    headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    json={"data": {"type": "appStoreVersionLocalizations", "id": "dbf6e9b3-82db-488e-b5d5-999ba9fc83ce",
                  "attributes": {"promotionalText": "Draw, paint, and listen."}}},
    timeout=30,
)
print("Write test:", r.status_code, "OK" if r.status_code == 200 else r.json().get("errors",[{}])[0].get("detail",""))
if r.status_code != 200:
    raise SystemExit(1)
PY

export P8_PATH="$DEST" ASC_KEY_ID="$KEY_ID" ASC_ISSUER_ID="$ISSUER_ID"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Signing secrets (reuse existing cert export or wcs dist.p12)
if [[ -z "${P12_PATH:-}" ]]; then
  if [[ -f "$HOME/.wcs_release_secrets/dist.p12" ]] && [[ -n "${P12_PASSWORD:-}" ]]; then
    P12_PATH="$HOME/.wcs_release_secrets/dist.p12"
  else
    echo "Exporting Distribution cert from keychain..."
    P12_PASSWORD="${P12_PASSWORD:-$(openssl rand -base64 24)}"
    P12_PATH="$(mktemp /tmp/etherealveil_dist_XXXXXX.p12)"
    security export -P "$P12_PASSWORD" -f pkcs12 -o "$P12_PATH" -t identities
  fi
fi
PP_PATH="${PP_PATH:-$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles/68460d04-49b1-4308-a36b-3f95db0923af.mobileprovision}"
KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-$(openssl rand -base64 24)}"
export P12_PATH PP_PATH P12_PASSWORD KEYCHAIN_PASSWORD

"$ROOT/scripts/push_github_secrets.sh"
echo ""
echo "Next: ./scripts/upload_distribution_to_apple_store.sh"

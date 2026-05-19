#!/usr/bin/env bash
# Discover local signing assets and push GitHub production secrets (requires gh auth).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ASC_ISSUER_ID="${ASC_ISSUER_ID:-70c46c69-5d6d-438d-b300-31df2b93163a}"

# App Store Connect API key (.p8)
if [[ -z "${P8_PATH:-}" ]]; then
  for candidate in \
    "$HOME/Downloads/AuthKey_TN35FDL978.p8" \
    "$HOME/.appstoreconnect/private_keys/AuthKey_TN35FDL978.p8" \
    "$HOME/Downloads/AuthKey_FTCDLIFPW2IU.p8" \
    "$HOME/.appstoreconnect/private_keys/AuthKey_FTCDLIFPW2IU.p8" \
    "$HOME/.wcs_release_secrets/AuthKey_FTCDLIFPW2IU.p8" \
    "$HOME/Downloads/AuthKey_${ASC_KEY_ID:-TN35FDL978}.p8" \
    "$HOME/.appstoreconnect/private_keys/AuthKey_KLH62AX56M.p8" \
    "$HOME/Downloads/AuthKey_KLH62AX56M.p8"; do
    if [[ -f "$candidate" ]]; then
      P8_PATH="$candidate"
      ASC_KEY_ID="$(basename "$candidate" .p8 | sed 's/AuthKey_//')"
      break
    fi
  done
fi
: "${P8_PATH:?No AuthKey_*.p8 found. Set P8_PATH.}"
ASC_KEY_ID="${ASC_KEY_ID:-$(basename "$P8_PATH" .p8 | sed 's/AuthKey_//')}"
if [[ "$ASC_KEY_ID" == "TN35FDL978" ]] || [[ "$ASC_KEY_ID" == "FTCDLIFPW2IU" ]]; then
  echo "Using App Manager key $ASC_KEY_ID (metadata + submit enabled)." >&2
elif [[ "$ASC_KEY_ID" == "KLH62AX56M" ]]; then
  echo "Note: KLH62AX56M = builds/TestFlight only. Add AuthKey_TN35FDL978.p8 for metadata/submit." >&2
fi

# App Store provisioning profile (etherealveil bundle)
if [[ -z "${PP_PATH:-}" ]]; then
  PP_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
  while IFS= read -r -d '' f; do
    bid=$(security cms -D -i "$f" 2>/dev/null | plutil -extract Entitlements.application-identifier raw -o - - 2>/dev/null || true)
    if [[ "$bid" == *"com.worldclassscholars.etherealveil" ]]; then
      name=$(security cms -D -i "$f" 2>/dev/null | plutil -extract Name raw -o - - 2>/dev/null || true)
      if [[ "$name" == *"Store"* ]]; then
        PP_PATH="$f"
        break
      fi
    fi
  done < <(find "$PP_DIR" -name "*.mobileprovision" -print0 2>/dev/null)
  if [[ -z "${PP_PATH:-}" ]]; then
    PP_PATH="$PP_DIR/68460d04-49b1-4308-a36b-3f95db0923af.mobileprovision"
  fi
fi
: "${PP_PATH:?No App Store profile for com.worldclassscholars.etherealveil}"

# Distribution certificate (.p12)
if [[ -z "${P12_PATH:-}" ]]; then
  if [[ -f "$HOME/.wcs_release_secrets/dist.p12" ]] && [[ -n "${P12_PASSWORD:-}" ]]; then
    P12_PATH="$HOME/.wcs_release_secrets/dist.p12"
  else
    echo "Exporting Apple Distribution identity from keychain..."
    P12_PASSWORD="${P12_PASSWORD:-$(openssl rand -base64 24)}"
    P12_PATH="$(mktemp /tmp/etherealveil_dist_XXXXXX.p12)"
    security export -P "$P12_PASSWORD" -f pkcs12 -o "$P12_PATH" -t identities
    openssl pkcs12 -in "$P12_PATH" -passin pass:"$P12_PASSWORD" -nokeys -legacy -out /dev/null
    echo "  Exported: $P12_PATH"
  fi
fi
: "${P12_PATH:?Set P12_PATH or allow keychain export}"
: "${P12_PASSWORD:?Set P12_PASSWORD for existing .p12, or omit to auto-export from keychain}"

KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-$(openssl rand -base64 24)}"

echo "Using:"
echo "  P12_PATH=$P12_PATH"
echo "  PP_PATH=$PP_PATH"
echo "  P8_PATH=$P8_PATH"
echo "  ASC_KEY_ID=$ASC_KEY_ID"
echo "  ASC_ISSUER_ID=$ASC_ISSUER_ID"

gh api --method PUT "repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/environments/production" >/dev/null 2>&1 || true

export P12_PATH PP_PATH P8_PATH P12_PASSWORD KEYCHAIN_PASSWORD ASC_KEY_ID ASC_ISSUER_ID
"$ROOT/scripts/push_github_secrets.sh"

echo ""
echo "Validate: gh workflow run \"Distribution — Validate Setup\""
echo "Deploy:   gh workflow run \"CD — TestFlight (Production)\" -f marketing_version=1.1.0"

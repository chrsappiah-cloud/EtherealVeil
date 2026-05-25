#!/usr/bin/env bash
# Encode local signing assets for GitHub Secrets (prints to stdout; does not upload).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  P12_PATH=~/certs/dist.p12 \
  PP_PATH=~/certs/EtherealVeil_AppStore.mobileprovision \
  P8_PATH=~/keys/AuthKey_XXXXXX.p8 \
  ./scripts/export_signing_secrets.sh

Optional env:
  P12_PASSWORD   — required when verifying the .p12 can be read
  KEYCHAIN_PASSWORD — suggested random string for CI keychain
  ASC_KEY_ID, ASC_ISSUER_ID — printed as plain text reminders
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

: "${P12_PATH:?Set P12_PATH to your Apple Distribution .p12}"
: "${PP_PATH:?Set PP_PATH to your App Store .mobileprovision}"
: "${P8_PATH:?Set P8_PATH to your App Store Connect .p8 API key}"

echo "=== Copy these into GitHub Secrets (production environment) ==="
echo ""
echo "BUILD_CERTIFICATE_BASE64=$(base64 < "$P12_PATH" | tr -d '\n')"
echo ""
echo "BUILD_PROVISION_PROFILE_BASE64=$(base64 < "$PP_PATH" | tr -d '\n')"
echo ""
echo "ASC_PRIVATE_KEY_BASE64=$(base64 < "$P8_PATH" | tr -d '\n')"
echo ""
echo "P12_PASSWORD=${P12_PASSWORD:-<your-p12-password>}"
echo "KEYCHAIN_PASSWORD=${KEYCHAIN_PASSWORD:-$(openssl rand -base64 24)}"
echo "ASC_KEY_ID=${ASC_KEY_ID:-<your-api-key-id>}"
echo "ASC_ISSUER_ID=${ASC_ISSUER_ID:-<your-issuer-id>}"
echo ""
echo "Provisioning profile UUID:"
security cms -D -i "$PP_PATH" 2>/dev/null | plutil -extract UUID xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p'

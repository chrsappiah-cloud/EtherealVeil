#!/usr/bin/env bash
# Push distribution secrets to GitHub (requires: gh auth login, admin on repo).
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-}"
if [[ -z "$REPO" ]]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)
fi
if [[ -z "$REPO" ]]; then
  echo "Set GITHUB_REPOSITORY or run inside a git repo with gh configured."
  exit 1
fi

: "${P12_PATH:?}"
: "${PP_PATH:?}"
: "${P8_PATH:?}"
: "${P12_PASSWORD:?}"
: "${KEYCHAIN_PASSWORD:?}"
: "${ASC_KEY_ID:?}"
: "${ASC_ISSUER_ID:?}"

echo "Setting secrets on $REPO (environment: production when available)..."

set_secret() {
  local name=$1
  local value=$2
  if gh secret set "$name" --env production --body "$value" 2>/dev/null; then
    echo "  ✓ $name (production environment)"
  else
    gh secret set "$name" --body "$value"
    echo "  ✓ $name (repository)"
  fi
}

set_secret BUILD_CERTIFICATE_BASE64 "$(base64 < "$P12_PATH" | tr -d '\n')"
set_secret BUILD_PROVISION_PROFILE_BASE64 "$(base64 < "$PP_PATH" | tr -d '\n')"
set_secret ASC_PRIVATE_KEY_BASE64 "$(base64 < "$P8_PATH" | tr -d '\n')"
set_secret P12_PASSWORD "$P12_PASSWORD"
set_secret KEYCHAIN_PASSWORD "$KEYCHAIN_PASSWORD"
set_secret ASC_KEY_ID "$ASC_KEY_ID"
set_secret ASC_ISSUER_ID "$ASC_ISSUER_ID"

echo "Done. Trigger TestFlight: gh workflow run \"CD — TestFlight (Production)\" -f marketing_version=1.1.0"

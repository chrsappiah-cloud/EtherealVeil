#!/usr/bin/env bash
# Validates required GitHub Actions secrets for TestFlight CD.
set -euo pipefail

required=(
  BUILD_CERTIFICATE_BASE64
  P12_PASSWORD
  BUILD_PROVISION_PROFILE_BASE64
  KEYCHAIN_PASSWORD
  ASC_KEY_ID
  ASC_ISSUER_ID
  ASC_PRIVATE_KEY_BASE64
)

missing=()
for name in "${required[@]}"; do
  value="${!name-}"
  if [[ -z "${value}" ]]; then
    missing+=("$name")
  fi
done

if ((${#missing[@]} > 0)); then
  echo "::error::Missing required distribution secrets: ${missing[*]}"
  echo ""
  echo "Configure the GitHub 'production' environment or repository secrets."
  echo "Run locally: ./scripts/export_signing_secrets.sh  (prints base64 values)"
  echo "Then:       ./scripts/push_github_secrets.sh     (requires gh auth)"
  echo "Docs:       distribution/GITHUB_SECRETS_SETUP.md"
  exit 1
fi

echo "All required distribution secrets are present."

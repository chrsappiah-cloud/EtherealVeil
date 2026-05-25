#!/usr/bin/env bash
# Upload metadata, screenshots, binary (optional), and submit for App Store review.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ASC_ISSUER_ID="${ASC_ISSUER_ID:-70c46c69-5d6d-438d-b300-31df2b93163a}"
ASC_KEY_ID="${ASC_KEY_ID:-KLH62AX56M}"
ASC_KEY_PATH="${ASC_KEY_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8}"
APP_VERSION="${APP_VERSION:-1.1.0}"
IPA_PATH="${IPA_PATH:-$ROOT/build/export/EtherealVeil.ipa}"

if [[ ! -f "$ASC_KEY_PATH" ]]; then
  echo "Missing API key: $ASC_KEY_PATH"
  echo "Place AuthKey_${ASC_KEY_ID}.p8 or set ASC_KEY_PATH (App Manager role required for metadata)."
  exit 1
fi

export ASC_ISSUER_ID ASC_KEY_ID ASC_KEY_PATH APP_VERSION

"$ROOT/scripts/prepare_deliver_metadata.sh"
python3 scripts/generate_distribution_assets.py 2>/dev/null || .venv/bin/python3 scripts/generate_distribution_assets.py

if [[ -f "$IPA_PATH" ]]; then
  echo "Uploading IPA: $IPA_PATH"
  xcrun altool --upload-app --type ios -f "$IPA_PATH" --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
else
  echo "No IPA at $IPA_PATH — metadata/screenshots only."
fi

cd "$ROOT/fastlane"
if ! command -v bundle >/dev/null; then
  gem install bundler
fi
bundle install --quiet 2>/dev/null || bundle install

bundle exec fastlane deliver_submit

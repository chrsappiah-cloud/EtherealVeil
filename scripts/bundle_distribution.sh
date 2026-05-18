#!/usr/bin/env bash
# Bundle App Store metadata, screenshots, and investor PDF for upload or release assets.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${1:-$ROOT/dist}"
VERSION="${2:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/EtherealVeil/Resources/Info.plist")}"

STAMP="EtherealVeil-Distribution-v${VERSION}"
ZIP="$OUT_DIR/${STAMP}.zip"

mkdir -p "$OUT_DIR"
rm -f "$ZIP"

cd "$ROOT"
zip -r "$ZIP" \
  distribution/app-store/metadata \
  distribution/app-store/screenshots \
  distribution/app-store/review_information.md \
  distribution/app-store/connect \
  distribution/EtherealVeil_Investor_Report.pdf \
  Promotional \
  distribution/DISTRIBUTION.md \
  distribution/GITHUB_SECRETS_SETUP.md \
  -x "*.DS_Store" >/dev/null

echo "Wrote $ZIP"

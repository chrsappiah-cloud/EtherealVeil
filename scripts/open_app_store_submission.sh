#!/usr/bin/env bash
# Open App Store Connect in-flight page and print copy-paste checklist.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
URL="https://appstoreconnect.apple.com/apps/6763116253/distribution/ios/version/inflight"

echo "=== Ethereal Veil — Manual submission (API key lacks App Manager write) ==="
echo ""
echo "Build 110 (1.1.0) is VALID in App Store Connect."
echo "In-flight App Store version is still 1.0 — set version to 1.1.0 and select build 110."
echo ""
echo "1. Open: $URL"
open "$URL" 2>/dev/null || true
echo ""
echo "2. Version → set to 1.1.0 | Build → select 110"
echo "3. Paste metadata from: $ROOT/distribution/app-store/metadata/en-AU/"
echo "4. Upload screenshots: $ROOT/distribution/app-store/screenshots/en-AU/"
echo "5. Review notes: $ROOT/distribution/app-store/review_information.md"
echo "6. Complete Age Rating + App Privacy + Export compliance"
echo "7. Submit for Review"
echo ""
echo "To automate (requires AuthKey_FTCDLIFPW2IU.p8 with App Manager role):"
echo "  cp AuthKey_FTCDLIFPW2IU.p8 ~/.appstoreconnect/private_keys/"
echo "  ASC_KEY_ID=FTCDLIFPW2IU ASC_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_FTCDLIFPW2IU.p8 \\"
echo "    ./scripts/generate_github_secrets.sh"
echo "  ./scripts/app_store_submit.sh"

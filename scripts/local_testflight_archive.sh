#!/usr/bin/env bash
# Local signed archive + export (run on a Mac with Xcode signing configured).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

command -v xcodegen >/dev/null && xcodegen generate

MARKETING=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" EtherealVeil/Resources/Info.plist)
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" EtherealVeil/Resources/Info.plist)

echo "Archiving Ethereal Veil $MARKETING ($BUILD)..."

xcodebuild archive \
  -project EtherealVeil.xcodeproj \
  -scheme EtherealVeil \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ROOT/build/EtherealVeil.xcarchive" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=TM2WG7HH96

xcodebuild -exportArchive \
  -archivePath "$ROOT/build/EtherealVeil.xcarchive" \
  -exportOptionsPlist EtherealVeil/ExportOptions.plist \
  -exportPath "$ROOT/build/export" \
  -allowProvisioningUpdates

echo "IPA ready: $ROOT/build/export/EtherealVeil.ipa"
echo "Upload with: xcrun altool --upload-app --type ios --file build/export/EtherealVeil.ipa --apiKey \$ASC_KEY_ID --apiIssuer \$ASC_ISSUER_ID"

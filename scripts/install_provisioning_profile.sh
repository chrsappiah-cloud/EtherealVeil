#!/usr/bin/env bash
# Install a .mobileprovision into the Xcode profiles folder using its UUID filename.
set -euo pipefail

PROFILE_PATH="${1:?Usage: install_provisioning_profile.sh /path/to/profile.mobileprovision}"

UUID=$(security cms -D -i "$PROFILE_PATH" | plutil -extract UUID raw -o - -)
DEST="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$DEST"
cp "$PROFILE_PATH" "$DEST/${UUID}.mobileprovision"
echo "Installed provisioning profile: $UUID"

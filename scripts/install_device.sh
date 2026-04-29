#!/usr/bin/env bash
# Install EtherealVeil on a physical iPhone via devicectl.
# Requires: Xcode command-line tools, device unlocked + trusted, Developer Mode on.
#
# Usage:
#   bash scripts/install_device.sh
#   bash scripts/install_device.sh 9D1F4302-903A-5348-B555-308AAB62C9B2
#
# If xcodebuild fails with:
#   "No available simulator runtimes for platform iphonesimulator"
# reboot the Mac (or restore Simulator runtimes in Xcode → Settings → Platforms),
# then rerun. Alternatively install from an existing archive (no rebuild):
#   APP="/Applications/EtherealVeil/build/EtherealVeil.xcarchive/Products/Applications/EtherealVeil.app"
#   xcrun devicectl device install app --device "<UUID>" "$APP"

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${ROOT}/EtherealVeil.xcodeproj"
SCHEME="${SCHEME:-EtherealVeil}"
CONFIG="${CONFIG:-Release}"
ARCHIVE_APP="${ROOT}/build/EtherealVeil.xcarchive/Products/Applications/EtherealVeil.app"
DERIVED="${DERIVED_DATA_PATH:-${TMPDIR:-/tmp}EtherealVeil-Install-${CONFIG}}"

DEVICE="${1:-${DEVICE_IDENTIFIER:-}}"

if [[ -z "${DEVICE}" ]]; then
  DEVICE="$(
    xcrun devicectl list devices 2>/dev/null | awk '
      $1 != "Name" && $1 != "----" && $1 != "" && $(NF-1) == "connected" {
        for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27,}$/) { print $i; exit }
      }
    ')"
fi

if [[ -z "${DEVICE}" ]]; then
  echo "No connected device UUID found. Plug in iPhone, unlock it, tap Trust, then run:" >&2
  echo "  xcrun devicectl list devices" >&2
  exit 1
fi

echo "==> Device: ${DEVICE}"

APP=""
if [[ -d "${ARCHIVE_APP}" ]]; then
  APP="${ARCHIVE_APP}"
  echo "==> Using existing archive app: ${APP}"
else
  echo "==> Building ${CONFIG} (generic/iOS) → ${DERIVED}"
  rm -rf "${DERIVED}"
  xcodebuild \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIG}" \
    -destination "generic/platform=iOS" \
    -derivedDataPath "${DERIVED}" \
    build
  APP="${DERIVED}/Build/Products/${CONFIG}-iphoneos/EtherealVeil.app"
fi

if [[ ! -d "${APP}" ]]; then
  echo "Built app not found at: ${APP}" >&2
  exit 1
fi

echo "==> Installing…"
xcrun devicectl device install app --device "${DEVICE}" "${APP}"

echo "==> Launching…"
xcrun devicectl device process launch --device "${DEVICE}" "com.worldclassscholars.etherealveil"

echo "==> Done."

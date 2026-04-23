#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="${PROJECT_PATH:-/Applications/EtherealVeil/EtherealVeil.xcodeproj}"
SCHEME="${SCHEME:-EtherealVeil}"
DERIVED_DATA="${DERIVED_DATA:-./EtherealVeil/.DerivedData-Preflight}"

echo "==> iOS release preflight"
echo "Project: ${PROJECT_PATH}"
echo "Scheme: ${SCHEME}"
echo "DerivedData: ${DERIVED_DATA}"

echo "==> Cleaning preflight derived data"
rm -rf "${DERIVED_DATA}"

echo "==> Running unit tests"
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -derivedDataPath "${DERIVED_DATA}" \
  test

echo "==> Building Release for generic iOS device"
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -derivedDataPath "${DERIVED_DATA}" \
  build

echo "==> Preflight completed successfully"

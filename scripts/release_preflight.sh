#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="${PROJECT_PATH:-/Applications/EtherealVeil/EtherealVeil.xcodeproj}"
SCHEME="${SCHEME:-EtherealVeil}"
DERIVED_DATA="${DERIVED_DATA:-${TMPDIR:-/tmp}EtherealVeil-DerivedData-Preflight}"
TEST_SCOPE="${TEST_SCOPE:-unit}"

echo "==> iOS release preflight"
echo "Project: ${PROJECT_PATH}"
echo "Scheme: ${SCHEME}"
echo "DerivedData: ${DERIVED_DATA}"
echo "Test scope: ${TEST_SCOPE}"

echo "==> Cleaning preflight derived data"
rm -rf "${DERIVED_DATA}"

discover_sim_destination() {
  xcodebuild -project "${PROJECT_PATH}" -scheme "${SCHEME}" -showdestinations 2>/dev/null | \
    awk -F'[{},]' '
      /Available destinations for/ { in_available=1; next }
      /Ineligible destinations for/ { in_available=0 }
      in_available && /platform:iOS Simulator/ && $0 !~ /name:Any iOS Simulator Device/ {
        for (i = 1; i <= NF; i++) {
          if ($i ~ /name:/) {
            gsub(/^.*name:[[:space:]]*/, "", $i)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
            if (length($i) > 0) {
              print "platform=iOS Simulator,name=" $i
              exit
            }
          }
        }
      }
    '
}

SIM_DESTINATION="${SIM_DESTINATION:-}"
if [[ -z "${SIM_DESTINATION}" ]]; then
  SIM_DESTINATION="$(discover_sim_destination || true)"
fi

if [[ -n "${SIM_DESTINATION}" ]]; then
  if [[ "${TEST_SCOPE}" == "all" ]]; then
    echo "==> Running all tests on ${SIM_DESTINATION}"
    xcodebuild \
      -project "${PROJECT_PATH}" \
      -scheme "${SCHEME}" \
      -configuration Debug \
      -destination "${SIM_DESTINATION}" \
      -derivedDataPath "${DERIVED_DATA}" \
      test
  else
    echo "==> Running unit tests only on ${SIM_DESTINATION}"
    xcodebuild \
      -project "${PROJECT_PATH}" \
      -scheme "${SCHEME}" \
      -configuration Debug \
      -destination "${SIM_DESTINATION}" \
      -derivedDataPath "${DERIVED_DATA}" \
      -only-testing:EtherealVeilTests \
      test
  fi
else
  echo "==> No concrete iOS simulator destination available; skipping simulator tests in preflight"
fi

echo "==> Building Release for generic iOS device"
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -derivedDataPath "${DERIVED_DATA}" \
  build

echo "==> Preflight completed successfully"

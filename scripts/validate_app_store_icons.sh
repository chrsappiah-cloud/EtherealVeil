#!/usr/bin/env bash
# Ensure the shipped AppIcon set matches the canonical App Store originals.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CANONICAL="$ROOT/distribution/app-store/icons"
APPICON="$ROOT/EtherealVeil/Assets.xcassets/AppIcon.appiconset"

check_icon() {
  local name="$1"
  local expected="$2"
  local dir="$3"
  local file="$dir/$name"

  if [[ ! -f "$file" ]]; then
    echo "Missing icon: $file" >&2
    exit 1
  fi

  local actual
  actual=$(shasum "$file" | awk '{print $1}')
  if [[ "$actual" != "$expected" ]]; then
    echo "Icon hash mismatch for $file" >&2
    echo "  expected $expected" >&2
    echo "  got      $actual" >&2
    exit 1
  fi
}

for dir in "$CANONICAL" "$APPICON"; do
  check_icon "AppIcon.png" "fe36bbe3fe4b7b195cd14d24fe5935a2daf6b55e" "$dir"
  check_icon "AppIcon-Dark.png" "ab11abee15708d318968ff529bdc33c4b2c0de32" "$dir"
  check_icon "AppIcon-Tinted.png" "c15104397449ec9b610bacad93f7875249fd9be4" "$dir"
done

echo "App Store icon originals validated."

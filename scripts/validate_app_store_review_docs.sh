#!/usr/bin/env bash
# Ensure App Store review docs answer Apple's recurring information requests.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REVIEW="$ROOT/distribution/app-store/review_information.md"
RESOLUTION="$ROOT/distribution/app-store/resolution_center_response.md"

require_phrase() {
  local file="$1"
  local phrase="$2"
  if ! grep -Fq "$phrase" "$file"; then
    echo "Missing required phrase in $(basename "$file"): $phrase" >&2
    exit 1
  fi
}

for file in "$REVIEW" "$RESOLUTION"; do
  [[ -f "$file" ]] || { echo "Missing $file" >&2; exit 1; }
done

require_phrase "$REVIEW" "no username/password"
require_phrase "$REVIEW" "Studio Pro subscriptions (In-App Purchase)"
require_phrase "$REVIEW" "Sign in or create account"
require_phrase "$RESOLUTION" "does not use a username/password login"
require_phrase "$RESOLUTION" "Studio Pro subscriptions (In-App Purchase)"
require_phrase "$RESOLUTION" "com.worldclassscholars.etherealveil.studio.monthly"

echo "App Store review documentation validated."

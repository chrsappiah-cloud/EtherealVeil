#!/usr/bin/env bash
# Map distribution metadata/screenshots into fastlane deliver layout (en-AU primary).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
META_SRC="$ROOT/distribution/app-store/metadata/en-AU"
SHOT_SRC="$ROOT/distribution/app-store/screenshots/en-AU"
DELIVER="$ROOT/fastlane/deliver"

rm -rf "$DELIVER/metadata" "$DELIVER/screenshots"
mkdir -p "$DELIVER/metadata/en-AU"
mkdir -p "$DELIVER/screenshots/en-AU/iPhone 6.7 Display"

for f in description keywords release_notes promotional_text subtitle support_url privacy_url; do
  if [[ -f "$META_SRC/${f}.txt" ]]; then
  case "$f" in
    release_notes) cp "$META_SRC/release_notes.txt" "$DELIVER/metadata/en-AU/release_notes.txt" ;;
    promotional_text) cp "$META_SRC/promotional_text.txt" "$DELIVER/metadata/en-AU/promotional_text.txt" ;;
    support_url) cp "$META_SRC/support_url.txt" "$DELIVER/metadata/en-AU/support_url.txt" ;;
    privacy_url) cp "$META_SRC/privacy_url.txt" "$DELIVER/metadata/en-AU/privacy_url.txt" ;;
    *) cp "$META_SRC/${f}.txt" "$DELIVER/metadata/en-AU/${f}.txt" ;;
  esac
  fi
done

# App info localization fields
cp "$META_SRC/subtitle.txt" "$DELIVER/metadata/en-AU/subtitle.txt" 2>/dev/null || true
echo "Ethereal Veil" > "$DELIVER/metadata/en-AU/name.txt"

i=1
for shot in "$SHOT_SRC"/iphone_67_*.png; do
  [[ -f "$shot" ]] || continue
  cp "$shot" "$DELIVER/screenshots/en-AU/iPhone 6.7 Display/$(printf '%02d' "$i").png"
  i=$((i + 1))
done

# Review information
mkdir -p "$DELIVER/metadata/review_information"
cat > "$DELIVER/metadata/review_information/first_name.txt" <<EOF
Christopher
EOF
cat > "$DELIVER/metadata/review_information/last_name.txt" <<EOF
Appiah-Thompson
EOF
cat > "$DELIVER/metadata/review_information/email_address.txt" <<EOF
chrsappiah@gmail.com
EOF
cat > "$DELIVER/metadata/review_information/notes.txt" <<'EOF'
Open Draw or Paint and sketch on the canvas. Tap Play for classical music from archive.org. Account tab offers optional Studio Pro StoreKit subscriptions (sandbox testable). No login required for core features. ITSAppUsesNonExemptEncryption is false.
EOF

echo "Deliver metadata ready under fastlane/deliver/"

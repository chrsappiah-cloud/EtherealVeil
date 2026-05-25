#!/usr/bin/env bash
# Map distribution metadata/screenshots into fastlane deliver layout (en-AU primary).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
META_SRC="$ROOT/distribution/app-store/metadata/en-AU"
SHOT_SRC="$ROOT/distribution/app-store/screenshots/en-AU"
DELIVER="$ROOT/fastlane/deliver"

rm -rf "$DELIVER/metadata" "$DELIVER/screenshots"
mkdir -p "$DELIVER/metadata/en-AU"
mkdir -p "$DELIVER/screenshots/en-AU"

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

cp "$META_SRC/subtitle.txt" "$DELIVER/metadata/en-AU/subtitle.txt" 2>/dev/null || true
echo "Ethereal Veil" > "$DELIVER/metadata/en-AU/name.txt"

# Deliver reads PNGs only from the locale folder (not device subfolders).
# Filenames must hint iPad Pro 3rd gen: ipadPro129 / IPAD_PRO_3GEN_129 in the name.
i=1
for shot in "$SHOT_SRC"/iphone_67_*.png; do
  [[ -f "$shot" ]] || continue
  cp "$shot" "$DELIVER/screenshots/en-AU/iphone67_$(printf '%02d' "$i").png"
  i=$((i + 1))
done
i=1
for shot in "$SHOT_SRC"/iphone_65_*.png; do
  [[ -f "$shot" ]] || continue
  cp "$shot" "$DELIVER/screenshots/en-AU/iphone65_$(printf '%02d' "$i").png"
  i=$((i + 1))
done
i=1
for shot in "$SHOT_SRC"/ipad_pro129_*.png; do
  [[ -f "$shot" ]] || continue
  cp "$shot" "$DELIVER/screenshots/en-AU/ipadPro129_$(printf '%02d' "$i").png"
  i=$((i + 1))
done

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
cat > "$DELIVER/metadata/review_information/phone_number.txt" <<EOF
+61400000000
EOF
python3 - "$ROOT/distribution/app-store/review_information.md" > "$DELIVER/metadata/review_information/notes.txt" <<'PY'
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
start = text.find("## Notes for reviewer")
if start < 0:
    raise SystemExit("Missing ## Notes for reviewer in review_information.md")
chunk = text[start:].split("## Export compliance")[0]
lines = [ln.strip() for ln in chunk.splitlines() if ln.strip() and not ln.startswith("#")]
print("\n".join(lines)[:4000])
PY

echo "Deliver metadata ready under fastlane/deliver/"

#!/usr/bin/env python3
"""Generate App Store icons and marketing screenshots for Ethereal Veil."""

from __future__ import annotations

import json
import math
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as exc:  # pragma: no cover
    raise SystemExit("Install Pillow: pip install pillow") from exc

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "EtherealVeil/Assets.xcassets/AppIcon.appiconset"
SHOT_DIR = ROOT / "distribution/app-store/screenshots/en-US"

GOLD = (0.88, 0.69, 0.29)
GOLD_DK = (0.67, 0.49, 0.17)
BG_TOP = (0.03, 0.02, 0.01)
BG_BOTTOM = (0.22, 0.16, 0.08)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def gradient_bg(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(size - 1, 1)
        color = tuple(
            int(255 * lerp(BG_TOP[i], BG_BOTTOM[i], t)) for i in range(3)
        )
        draw.line([(0, y), (size, y)], fill=color)
    return img


def draw_sparkle_ring(draw: ImageDraw.ImageDraw, cx: int, cy: int, radius: int) -> None:
    for i in range(24):
        angle = (math.pi * 2 * i) / 24
        x1 = cx + int(math.cos(angle) * (radius - 8))
        y1 = cy + int(math.sin(angle) * (radius - 8))
        x2 = cx + int(math.cos(angle) * radius)
        y2 = cy + int(math.sin(angle) * radius)
        draw.line([(x1, y1), (x2, y2)], fill=tuple(int(255 * c) for c in GOLD), width=3)


def render_app_icon(size: int = 1024) -> Image.Image:
    img = gradient_bg(size)
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    outer = int(size * 0.36)
    inner = int(size * 0.28)

    draw.ellipse(
        [cx - outer, cy - outer, cx + outer, cy + outer],
        outline=tuple(int(255 * c) for c in GOLD),
        width=max(6, size // 80),
    )
    draw_sparkle_ring(draw, cx, cy, outer)

    draw.ellipse(
        [cx - inner, cy - inner, cx + inner, cy + inner],
        fill=tuple(int(255 * c) for c in GOLD_DK),
        outline=(255, 255, 255),
        width=max(4, size // 120),
    )

    font_size = size // 5
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", font_size)
    except OSError:
        font = ImageFont.load_default()
    text = "EV"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text((cx - tw // 2, cy - th // 2 - size // 40), text, fill=(0, 0, 0), font=font)
    return img


def render_screenshot(width: int, height: int, headline: str, subtitle: str) -> Image.Image:
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / max(height - 1, 1)
        color = tuple(int(255 * lerp(BG_TOP[i], BG_BOTTOM[i], t)) for i in range(3))
        draw.line([(0, y), (width, y)], fill=color)

    pad = width // 14
    panel_top = height // 5
    panel_bottom = height - height // 6
    draw.rounded_rectangle(
        [pad, panel_top, width - pad, panel_bottom],
        radius=48,
        outline=tuple(int(255 * c) for c in GOLD),
        width=4,
        fill=(20, 14, 6),
    )

    try:
        title_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", width // 14)
        body_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", width // 26)
        small_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", width // 34)
    except OSError:
        title_font = body_font = small_font = ImageFont.load_default()

    draw.text((pad + 40, panel_top + 40), "Ethereal Veil", fill=tuple(int(255 * c) for c in GOLD), font=title_font)
    draw.text((pad + 40, panel_top + 40 + width // 10), headline, fill=(255, 255, 255), font=body_font)
    draw.text((pad + 40, panel_top + 40 + width // 6), subtitle, fill=(200, 190, 170), font=small_font)

    # Mock tab bar
    bar_y = panel_bottom - 120
    draw.rounded_rectangle(
        [pad + 20, bar_y, width - pad - 20, panel_bottom - 30],
        radius=30,
        fill=(30, 22, 10),
        outline=tuple(int(255 * c) for c in GOLD),
        width=2,
    )
    tabs = ["Draw", "Paint", "Library", "Cloud"]
    slot = (width - 2 * pad - 40) // len(tabs)
    for i, label in enumerate(tabs):
        cx = pad + 20 + slot * i + slot // 2
        draw.ellipse([cx - 28, bar_y + 18, cx + 28, bar_y + 74], fill=tuple(int(255 * c) for c in GOLD) if i == 0 else (60, 50, 30))
        draw.text((cx - 18, bar_y + 78), label, fill=(255, 255, 255), font=small_font)

    draw.text((pad, height - 80), "World Class Scholars", fill=(180, 160, 120), font=small_font)
    return img


def write_icon(name: str, image: Image.Image) -> None:
    path = ICON_DIR / name
    image.save(path, format="PNG")
    print(f"Wrote {path}")


def main() -> None:
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    SHOT_DIR.mkdir(parents=True, exist_ok=True)

    icon = render_app_icon(1024)
    write_icon("AppIcon.png", icon)
    write_icon("AppIcon-Dark.png", icon)
    write_icon("AppIcon-Tinted.png", icon)

    frames = [
        ("iphone_67_01_draw.png", 1290, 2796, "Draw with gold studio controls", "Pencil, brush, marker, eraser, undo, and cloud save."),
        ("iphone_67_02_paint.png", 1290, 2796, "Paint with artist brushes", "Round, flat, fan, palette knife, watercolor, and oil."),
        ("iphone_67_03_music.png", 1290, 2796, "Classical music while you create", "CC0 Chopin playlist with favorites and playlist sheet."),
        ("iphone_67_04_cloud.png", 1290, 2796, "CloudKit library and backups", "Saved sessions, favorites, and backup checkpoints."),
    ]
    for filename, w, h, headline, subtitle in frames:
        path = SHOT_DIR / filename
        render_screenshot(w, h, headline, subtitle).save(path, format="PNG")
        print(f"Wrote {path}")

    manifest = {
        "version": "1.0.1",
        "icons": ["AppIcon.png", "AppIcon-Dark.png", "AppIcon-Tinted.png"],
        "screenshots": [f[0] for f in frames],
    }
    manifest_path = ROOT / "distribution/app-store/asset_manifest.json"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {manifest_path}")


if __name__ == "__main__":
    main()

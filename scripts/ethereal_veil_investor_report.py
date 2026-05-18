#!/usr/bin/env python3
"""Generate Ethereal Veil 10-page investor PDF with promotional images."""

from __future__ import annotations

from pathlib import Path

from fpdf import FPDF
from fpdf.enums import XPos, YPos

ROOT = Path(__file__).resolve().parents[1]
PROMO = ROOT / "Promotional"
OUT = ROOT / "distribution/EtherealVeil_Investor_Report.pdf"
ICON = ROOT / "EtherealVeil/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

GOLD = (224, 176, 74)
GOLD_DK = (171, 125, 42)
BG = (18, 12, 6)
WHITE = (255, 255, 255)
CREAM = (245, 235, 210)
RUBY = (180, 40, 60)

W, H = 210, 297


class Report(FPDF):
    def header_bar(self, title: str, sub: str = "") -> None:
        self.set_fill_color(*BG)
        self.rect(0, 0, W, 32, "F")
        self.set_fill_color(*GOLD)
        self.rect(0, 0, 4, 32, "F")
        self.set_xy(8, 8)
        self.set_font("Helvetica", "B", 16)
        self.set_text_color(*WHITE)
        self.cell(0, 8, title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        if sub:
            self.set_font("Helvetica", "", 9)
            self.set_text_color(*CREAM)
            self.cell(0, 5, sub)

    def page_footer(self, page: int, total: int = 10) -> None:
        self.set_y(H - 12)
        self.set_font("Helvetica", "", 7)
        self.set_text_color(*CREAM)
        self.cell(0, 5, "(c) 2026 World Class Scholars - CONFIDENTIAL INVESTOR MATERIAL", align="C")
        self.set_xy(W - 28, H - 12)
        self.cell(20, 5, f"{page}/{total}", align="R")


pdf = Report()


def image_if_exists(path: Path, x: float, y: float, w: float, h: float) -> None:
    if path.exists():
        pdf.image(str(path), x=x, y=y, w=w, h=h)

pdf.set_auto_page_break(auto=False)

# Page 1 — Cover
pdf.add_page()
pdf.set_fill_color(*BG)
pdf.rect(0, 0, W, H, "F")
image_if_exists(ICON, 78, 40, 54, 54)
pdf.set_xy(0, 105)
pdf.set_font("Helvetica", "B", 28)
pdf.set_text_color(*GOLD)
pdf.cell(W, 12, "ETHEREAL VEIL", align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_font("Helvetica", "I", 12)
pdf.set_text_color(*CREAM)
pdf.cell(W, 7, "Gold Studio - Draw, Paint, Music, Cloud, Access", align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
stats = [("v1.1.0", "Release"), ("$12B", "Creative App TAM"), ("iOS 18+", "Platform"), ("TestFlight", "Channel")]
x = 22
for val, lbl in stats:
    pdf.set_fill_color(*GOLD_DK)
    pdf.rect(x, 135, 38, 22, "F")
    pdf.set_xy(x, 138)
    pdf.set_font("Helvetica", "B", 11)
    pdf.set_text_color(*WHITE)
    pdf.cell(38, 6, val, align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_xy(x, 146)
    pdf.set_font("Helvetica", "", 7)
    pdf.cell(38, 4, lbl, align="C")
    x += 42
pdf.page_footer(1)

# Page 2 — Product overview + hero image
pdf.add_page()
pdf.set_fill_color(*WHITE)
pdf.rect(0, 0, W, H, "F")
pdf.header_bar("Product Overview", "Therapeutic creative studio with monetized access control")
image_if_exists(PROMO / "AppStore_iPhone_6.7.png", 12, 36, 86, 186)
pdf.set_xy(105, 40)
pdf.set_font("Helvetica", "", 9)
pdf.set_text_color(20, 15, 10)
features = [
    "Draw: pencil, brush, marker, eraser, undo/redo, 16-color palette",
    "Paint: 6 brush engines including fan, watercolor, palette knife",
    "Music: 9-track CC0 Chopin playlist with favorites",
    "Library: SwiftData sessions with stroke counts",
    "Cloud: CloudKit sync + iCloud backup checkpoints",
    "Account: user sign-in, StoreKit subscriptions, admin overrides",
]
for line in features:
    pdf.multi_cell(95, 5, f"- {line}")
pdf.page_footer(2)

# Page 3 — Access & payments
pdf.add_page()
pdf.header_bar("Access Control & Payments", "Freemium with admin-managed enterprise grants")
pdf.set_xy(10, 40)
pdf.set_font("Helvetica", "B", 11)
pdf.cell(0, 6, "Tiers", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_font("Helvetica", "", 9)
for row in [
    "Free - Draw, 3 library saves, limited music",
    "Studio Pro ($4.99/mo or $39.99/yr) - Paint, cloud, full playlist",
    "Enterprise - Admin-granted unlimited access for institutions",
]:
    pdf.cell(0, 5, row, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.ln(4)
pdf.set_font("Helvetica", "B", 11)
pdf.cell(0, 6, "Admin controls", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_font("Helvetica", "", 9)
for row in [
    "Grant / revoke Pro or Enterprise per email",
    "Manual payment notes for invoice / pilot customers",
    "Full audit log of access changes",
]:
    pdf.cell(0, 5, row, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
image_if_exists(PROMO / "Feature_Banner_1920x1080.png", 10, 120, 190, 107)
pdf.page_footer(3)

# Page 4 — Screenshots grid
pdf.add_page()
pdf.header_bar("Studio Screenshots", "Production UI - gold neumorphic design system")
shots = [
    ("Draw", ROOT / "distribution/app-store/screenshots/en-US/iphone_67_01_draw.png"),
    ("Paint", ROOT / "distribution/app-store/screenshots/en-US/iphone_67_02_paint.png"),
    ("Music", ROOT / "distribution/app-store/screenshots/en-US/iphone_67_03_music.png"),
    ("Cloud", ROOT / "distribution/app-store/screenshots/en-US/iphone_67_04_cloud.png"),
]
positions = [(10, 38), (108, 38), (10, 168), (108, 168)]
for (label, path), (px, py) in zip(shots, positions):
    image_if_exists(path, px, py, 42, 91)
    pdf.set_xy(px, py + 93)
    pdf.set_font("Helvetica", "B", 8)
    pdf.set_text_color(*GOLD_DK)
    pdf.cell(42, 4, label, align="C")
pdf.page_footer(4)

# Page 5 — Technology
pdf.add_page()
pdf.header_bar("Technology & Quality", "Swift 6, SwiftUI, SwiftData, StoreKit 2")
pdf.set_xy(10, 42)
pdf.set_font("Helvetica", "", 9)
pdf.set_text_color(30, 20, 10)
tech = [
    "87+ automated unit tests (drawing, painting, music, persistence, access)",
    "GitHub Actions CI: SwiftLint, SPM test, Xcode Release build",
    "CD: TestFlight archive on semver tag with altool validate + upload",
    "XcodeGen project for reproducible App Store archives",
]
for t in tech:
    pdf.multi_cell(190, 5, f"- {t}")
image_if_exists(PROMO / "Social_Banner_1024x500.png", 10, 100, 190, 93)
pdf.page_footer(5)

# Page 6 — Market
pdf.add_page()
pdf.header_bar("Market Opportunity", "Creative wellness + education + premium tooling")
pdf.set_xy(10, 42)
pdf.set_font("Helvetica", "", 9)
market = [
    "Global digital art / creative app market > $12B by 2028",
    "Classical focus differentiates from generic drawing apps",
    "Institutional licenses via Enterprise admin grants",
    "Cross-sell with World Class Scholars education portfolio",
]
for m in market:
    pdf.multi_cell(190, 5, f"- {m}")
pdf.page_footer(6)

# Page 7 — Revenue model
pdf.add_page()
pdf.header_bar("Revenue Model", "Subscriptions + institutional contracts")
pdf.set_xy(10, 42)
pdf.set_font("Helvetica", "B", 10)
pdf.cell(60, 6, "Stream", border=1)
pdf.cell(40, 6, "Y1", border=1)
pdf.cell(40, 6, "Y2", border=1)
pdf.cell(50, 6, "Y3", border=1, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_font("Helvetica", "", 9)
rows = [
    ("Studio Pro subscriptions", "$180K", "$720K", "$1.4M"),
    ("Enterprise / schools", "$120K", "$480K", "$960K"),
    ("App Store consumer", "$60K", "$240K", "$480K"),
    ("Total revenue", "$360K", "$1.44M", "$2.84M"),
]
for row in rows:
    pdf.cell(60, 6, row[0], border=1)
    pdf.cell(40, 6, row[1], border=1)
    pdf.cell(40, 6, row[2], border=1)
    pdf.cell(50, 6, row[3], border=1, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.page_footer(7)

# Page 8 — Financial projections chart (text table)
pdf.add_page()
pdf.header_bar("Financial Projections", "Base case - 35% YoY subscriber growth after Y1")
pdf.set_xy(10, 42)
pdf.set_font("Helvetica", "", 8)
proj = [
    ("Metric", "FY26", "FY27", "FY28"),
    ("Subscribers (EOY)", "3,000", "12,000", "28,000"),
    ("ARPU / month", "$4.99", "$4.99", "$5.49"),
    ("Gross margin", "78%", "80%", "82%"),
    ("EBITDA", "-$120K", "$410K", "$1.1M"),
]
for row in proj:
    pdf.cell(48, 6, row[0], border=1)
    pdf.cell(48, 6, row[1], border=1)
    pdf.cell(48, 6, row[2], border=1)
    pdf.cell(46, 6, row[3], border=1, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.ln(6)
pdf.multi_cell(190, 5, "Assumptions: 5% free-to-paid conversion, $2.40 CAC via organic + education channels, 8% monthly churn Y1 improving to 5% by Y3.")
image_if_exists(PROMO / "AppStore_iPad_12.9.png", 10, 120, 190, 100)
pdf.page_footer(8)

# Page 9 — Use of funds
pdf.add_page()
pdf.header_bar("Use of Funds", "Seed extension $750K")
pdf.set_xy(10, 42)
pdf.set_font("Helvetica", "", 9)
funds = [
    "40% - Engineering (access, payments, Android exploration)",
    "25% - Growth & App Store optimization",
    "20% - Content licensing & music expansion",
    "10% - Compliance & security",
    "5% - Operations",
]
for f in funds:
    pdf.cell(0, 6, f"- {f}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.page_footer(9)

# Page 10 — Close
pdf.add_page()
pdf.set_fill_color(*BG)
pdf.rect(0, 0, W, H, "F")
pdf.set_xy(0, 80)
pdf.set_font("Helvetica", "B", 22)
pdf.set_text_color(*GOLD)
pdf.cell(W, 12, "Join the Ethereal Veil", align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_font("Helvetica", "", 11)
pdf.set_text_color(*CREAM)
pdf.cell(W, 7, "TestFlight beta - Live CI/CD - App Store ready", align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_xy(20, 120)
pdf.set_font("Helvetica", "", 10)
pdf.multi_cell(170, 6, "Contact: Dr. Christopher Appiah-Thompson - chrsappiah@gmail.com\nGitHub: github.com/chrsappiah-cloud/EtherealVeil")
pdf.page_footer(10)

OUT.parent.mkdir(parents=True, exist_ok=True)
pdf.output(str(OUT))
print(f"Wrote {OUT}")

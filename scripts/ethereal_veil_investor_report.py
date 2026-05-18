#!/usr/bin/env python3
"""Generate Ethereal Veil 10-page investor brochure (PDF + page PNGs) and copy to Desktop."""

from __future__ import annotations

import shutil
from pathlib import Path

from fpdf import FPDF
from fpdf.enums import XPos, YPos

ROOT = Path(__file__).resolve().parents[1]
PROMO = ROOT / "Promotional"
OUT_PDF = ROOT / "distribution/EtherealVeil_Investor_Brochure.pdf"
OUT_PAGES = ROOT / "distribution/investor-brochure/pages"
ICON = ROOT / "EtherealVeil/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
DESKTOP = Path.home() / "Desktop" / "EtherealVeil-Investor"

GOLD = (224, 176, 74)
GOLD_DK = (171, 125, 42)
BG = (18, 12, 6)
WHITE = (255, 255, 255)
CREAM = (245, 235, 210)

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


def image_if_exists(pdf: FPDF, path: Path, x: float, y: float, w: float, h: float) -> None:
    if path.exists():
        pdf.image(str(path), x=x, y=y, w=w, h=h)


def build_pdf() -> FPDF:
    pdf = Report()
    pdf.set_auto_page_break(auto=False)

    # Page 1 — Cover
    pdf.add_page()
    pdf.set_fill_color(*BG)
    pdf.rect(0, 0, W, H, "F")
    image_if_exists(pdf, ICON, 78, 40, 54, 54)
    pdf.set_xy(0, 105)
    pdf.set_font("Helvetica", "B", 28)
    pdf.set_text_color(*GOLD)
    pdf.cell(W, 12, "ETHEREAL VEIL", align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "I", 12)
    pdf.set_text_color(*CREAM)
    pdf.cell(
        W,
        7,
        "Gold Studio - Draw, Paint, Music, Cloud, Account & Studio Pro",
        align="C",
        new_x=XPos.LMARGIN,
        new_y=YPos.NEXT,
    )
    stats = [("v1.1.0", "Release"), ("$12B+", "Creative TAM"), ("iOS 18+", "Platform"), ("Live", "CI/CD")]
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

    # Page 2 — Product overview
    pdf.add_page()
    pdf.set_fill_color(*WHITE)
    pdf.rect(0, 0, W, H, "F")
    pdf.header_bar("Product Overview", "Therapeutic creative studio with monetized access control")
    image_if_exists(pdf, PROMO / "Promo_01_Hero.png", 12, 36, 86, 186)
    pdf.set_xy(105, 40)
    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(20, 15, 10)
    features = [
        "Draw: pencil, brush, marker, eraser, undo/redo, 16-color palette",
        "Paint: 6 brush engines (fan, watercolor, palette knife, oil)",
        "Music: 9-track CC0 Chopin playlist with favorites & playlist sheet",
        "Library: SwiftData sessions with stroke counts & timestamps",
        "Cloud: CloudKit sync toggles + iCloud backup checkpoints",
        "Account: StoreKit Studio Pro, admin grants, audit log",
    ]
    for line in features:
        pdf.multi_cell(95, 5, f"- {line}")
    pdf.page_footer(2)

    # Page 3 — Access & subscriptions
    pdf.add_page()
    pdf.header_bar("Subscriptions & Access Control", "Freemium + Studio Pro + Enterprise admin")
    pdf.set_xy(10, 40)
    pdf.set_font("Helvetica", "B", 11)
    pdf.cell(0, 6, "Studio Pro (StoreKit)", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "", 9)
    for row in [
        "Monthly: com.worldclassscholars.etherealveil.studio.monthly - $4.99/mo",
        "Yearly: com.worldclassscholars.etherealveil.studio.yearly - $39.99/yr (33% savings)",
        "Unlocks: full Paint studio, CloudKit backup, unlimited library, full playlist",
    ]:
        pdf.cell(0, 5, row, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(4)
    pdf.set_font("Helvetica", "B", 11)
    pdf.cell(0, 6, "Tiers", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "", 9)
    for row in [
        "Free - Draw tab, 3 library saves, limited music preview",
        "Studio Pro - Paint, cloud, unlimited saves, full music",
        "Enterprise - Admin-granted unlimited access for schools / pilots",
    ]:
        pdf.cell(0, 5, row, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    image_if_exists(pdf, PROMO / "Promo_04_Subscriptions.png", 10, 120, 190, 107)
    pdf.page_footer(3)

    # Page 4 — Screenshots
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
        image_if_exists(pdf, path, px, py, 42, 91)
        pdf.set_xy(px, py + 93)
        pdf.set_font("Helvetica", "B", 8)
        pdf.set_text_color(*GOLD_DK)
        pdf.cell(42, 4, label, align="C")
    pdf.page_footer(4)

    # Page 5 — Technology & CI/CD
    pdf.add_page()
    pdf.header_bar("Technology & CI/CD", "Swift 6, SwiftUI, SwiftData, StoreKit 2, GitHub Actions")
    pdf.set_xy(10, 42)
    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(30, 20, 10)
    for t in [
        "90+ automated unit tests (drawing, painting, music, persistence, access)",
        "CI: SwiftLint, yamllint, SPM tests, Xcode Release build (iphoneos)",
        "CD: TestFlight on semver tag v*.*.* with signed archive + ASC upload",
        "Distribution release workflow: promotional images + investor brochure",
        "XcodeGen + Fastlane + App Store Connect API deploy scripts",
    ]:
        pdf.multi_cell(190, 5, f"- {t}")
    image_if_exists(pdf, PROMO / "Promo_05_Investor_CI.png", 10, 100, 190, 93)
    pdf.page_footer(5)

    # Page 6 — Market
    pdf.add_page()
    pdf.header_bar("Market Opportunity", "Creative wellness + education + premium tooling")
    pdf.set_xy(10, 42)
    pdf.set_font("Helvetica", "", 9)
    for m in [
        "Global digital art / creative app market > $12B by 2028",
        "Classical music focus differentiates from generic drawing apps",
        "Institutional licenses via Enterprise admin grants (schools, therapy)",
        "Cross-sell with World Class Scholars education portfolio",
        "iPad + iPhone universal binary (TARGETED_DEVICE_FAMILY 1,2)",
    ]:
        pdf.multi_cell(190, 5, f"- {m}")
    image_if_exists(pdf, PROMO / "Promo_02_Draw_Paint.png", 10, 120, 190, 100)
    pdf.page_footer(6)

    # Page 7 — Revenue model
    pdf.add_page()
    pdf.header_bar("Revenue Model", "Subscriptions (primary) + institutional contracts")
    pdf.set_xy(10, 42)
    pdf.set_font("Helvetica", "B", 10)
    pdf.cell(55, 6, "Stream", border=1)
    pdf.cell(38, 6, "Y1", border=1)
    pdf.cell(38, 6, "Y2", border=1)
    pdf.cell(49, 6, "Y3", border=1, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "", 9)
    rows = [
        ("Studio Pro subscriptions", "$180K", "$720K", "$1.40M"),
        ("Enterprise / schools", "$120K", "$480K", "$960K"),
        ("App Store consumer add-ons", "$60K", "$240K", "$480K"),
        ("Total revenue", "$360K", "$1.44M", "$2.84M"),
    ]
    for row in rows:
        pdf.cell(55, 6, row[0], border=1)
        pdf.cell(38, 6, row[1], border=1)
        pdf.cell(38, 6, row[2], border=1)
        pdf.cell(49, 6, row[3], border=1, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(4)
    pdf.set_font("Helvetica", "", 8)
    pdf.multi_cell(
        190,
        4,
        "Pricing: $4.99/mo or $39.99/yr. Apple retains 15-30% after year one. "
        "Enterprise priced per-seat $8-15/mo for 50+ seat contracts.",
    )
    pdf.page_footer(7)

    # Page 8 — Financial projections (simple model)
    pdf.add_page()
    pdf.header_bar("Financial Projections (Base Case)", "35% YoY paid subscriber growth after Y1")
    pdf.set_xy(10, 42)
    pdf.set_font("Helvetica", "", 8)
    proj = [
        ("Metric", "FY26", "FY27", "FY28"),
        ("Paid subscribers (EOY)", "3,000", "12,000", "28,000"),
        ("Blended ARPU / month", "$4.99", "$4.99", "$5.49"),
        ("Gross margin", "78%", "80%", "82%"),
        ("Operating expenses", "$280K", "$520K", "$780K"),
        ("EBITDA", "-$120K", "$410K", "$1.10M"),
        ("CAC (blended)", "$2.40", "$1.90", "$1.50"),
        ("Monthly churn", "8.0%", "6.5%", "5.0%"),
    ]
    for row in proj:
        pdf.cell(52, 6, row[0], border=1)
        pdf.cell(46, 6, row[1], border=1)
        pdf.cell(46, 6, row[2], border=1)
        pdf.cell(46, 6, row[3], border=1, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(5)
    pdf.multi_cell(
        190,
        4,
        "Assumptions: 5% free-to-paid conversion, 40% annual plan mix, organic + education "
        "channels. Sensitivity: at 2% conversion Y3 revenue ~$1.1M; at 8% conversion ~$4.2M.",
    )
    image_if_exists(pdf, PROMO / "Promo_03_Music_Cloud.png", 10, 155, 190, 75)
    pdf.page_footer(8)

    # Page 9 — Use of funds
    pdf.add_page()
    pdf.header_bar("Use of Funds", "Seed extension target: $750K")
    pdf.set_xy(10, 42)
    pdf.set_font("Helvetica", "", 9)
    for f in [
        "40% - Engineering (Android exploration, collaboration, AI assist brushes)",
        "25% - Growth & App Store optimization (ASA, creative campaigns)",
        "20% - Content licensing & expanded royalty-free music catalog",
        "10% - Compliance, security review, accessibility (WCAG)",
        "5% - Operations & customer success for Enterprise pilots",
    ]:
        pdf.cell(0, 6, f"- {f}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(4)
    pdf.set_font("Helvetica", "B", 10)
    pdf.cell(0, 6, "Milestones (12 months)", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "", 9)
    for m in [
        "M1-M3: App Store launch, 1K paid subs, 3 school pilots",
        "M4-M6: iPad marketing push, 5K subs, first Enterprise contract",
        "M7-M12: Break-even EBITDA, 12K subs, Series A readiness",
    ]:
        pdf.cell(0, 5, f"- {m}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
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
    pdf.cell(
        W,
        7,
        "TestFlight live - CI/CD enforced - App Store in flight",
        align="C",
        new_x=XPos.LMARGIN,
        new_y=YPos.NEXT,
    )
    pdf.set_xy(20, 120)
    pdf.set_font("Helvetica", "", 10)
    pdf.multi_cell(
        170,
        6,
        "Contact: Dr. Christopher Appiah-Thompson - chrsappiah@gmail.com\n"
        "GitHub: github.com/chrsappiah-cloud/EtherealVeil\n"
        "App Store Connect: app 6763116253",
    )
    pdf.page_footer(10)
    return pdf


def export_page_images(pdf_path: Path, out_dir: Path) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    try:
        import fitz  # PyMuPDF
    except ImportError as exc:
        raise SystemExit("Install pymupdf: pip install pymupdf") from exc

    doc = fitz.open(str(pdf_path))
    paths: list[Path] = []
    for i, page in enumerate(doc):
        pix = page.get_pixmap(matrix=fitz.Matrix(2.5, 2.5))
        out = out_dir / f"EtherealVeil_Brochure_Page_{i + 1:02d}.png"
        pix.save(str(out))
        paths.append(out)
    doc.close()
    return paths


def copy_to_desktop(pdf_path: Path, page_paths: list[Path]) -> Path:
    desktop_root = DESKTOP
    promo_dst = desktop_root / "promotional-images"
    brochure_dst = desktop_root / "brochure"
    promo_dst.mkdir(parents=True, exist_ok=True)
    brochure_dst.mkdir(parents=True, exist_ok=True)

    shutil.copy2(pdf_path, brochure_dst / pdf_path.name)
    for p in page_paths:
        shutil.copy2(p, brochure_dst / p.name)

    for promo in sorted(PROMO.glob("Promo_*.png")):
        shutil.copy2(promo, promo_dst / promo.name)

    for name in [
        "AppStore_iPhone_6.7.png",
        "AppStore_iPhone_5.5.png",
        "AppStore_iPad_12.9.png",
        "Feature_Banner_1920x1080.png",
        "Social_Banner_1024x500.png",
    ]:
        src = PROMO / name
        if src.exists():
            shutil.copy2(src, promo_dst / name)

    return desktop_root


def main() -> None:
    OUT_PDF.parent.mkdir(parents=True, exist_ok=True)
    pdf = build_pdf()
    pdf.output(str(OUT_PDF))
    print(f"Wrote {OUT_PDF}")

    page_paths = export_page_images(OUT_PDF, OUT_PAGES)
    for p in page_paths:
        print(f"Wrote {p}")

    desktop = copy_to_desktop(OUT_PDF, page_paths)
    print(f"Desktop copies: {desktop}")


if __name__ == "__main__":
    main()

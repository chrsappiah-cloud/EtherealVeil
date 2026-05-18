#!/usr/bin/env python3
"""Push App Store metadata, age rating, review notes, and submit for review via App Store Connect API."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

import jwt
import requests

ROOT = Path(__file__).resolve().parents[1]
CONNECT = ROOT / "distribution/app-store/connect/app.json"
META = ROOT / "distribution/app-store/metadata"
REVIEW = ROOT / "distribution/app-store/review_information.md"

API = "https://api.appstoreconnect.apple.com/v1"


def load_connect() -> dict:
    return json.loads(CONNECT.read_text())


def resolve_key(connect: dict) -> tuple[str, Path]:
    preferred = os.environ.get("ASC_KEY_ID") or connect.get("ascKeyIdPreferred", "")
    issuer = os.environ.get("ASC_ISSUER_ID") or connect["ascIssuerId"]
    candidates: list[tuple[str, Path]] = []
    if preferred:
        candidates.append((preferred, Path.home() / "Downloads" / f"AuthKey_{preferred}.p8"))
        candidates.append((preferred, Path.home() / "private_keys" / f"AuthKey_{preferred}.p8"))
    appstore_keys = Path.home() / ".appstoreconnect" / "private_keys"
    for kid, path in [
        ("KLH62AX56M", appstore_keys / "AuthKey_KLH62AX56M.p8"),
        ("KLH62AX56M", Path.home() / "Downloads" / "AuthKey_KLH62AX56M.p8"),
        ("5NNSQ6MBCX", appstore_keys / "AuthKey_5NNSQ6MBCX.p8"),
    ]:
        candidates.append((kid, path))
    env_path = os.environ.get("ASC_KEY_PATH")
    if env_path:
        p = Path(env_path)
        candidates.insert(0, (preferred or p.stem.replace("AuthKey_", ""), p))
    for kid, path in candidates:
        if path.exists():
            return kid, path
    raise SystemExit(
        f"No .p8 key found for {preferred or 'ASC'}. "
        f"Place AuthKey_{preferred}.p8 in ~/Downloads or set ASC_KEY_PATH."
    )


def bearer(issuer: str, kid: str, key_path: Path) -> str:
    key = key_path.read_text()
    return jwt.encode(
        {"iss": issuer, "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": kid, "typ": "JWT"},
    )


def read_meta(locale: str, name: str) -> str | None:
    path = META / locale / f"{name}.txt"
    return path.read_text().strip() if path.exists() else None


def patch(session: requests.Session, url: str, body: dict) -> requests.Response:
    return session.patch(url, json=body, timeout=60)


def post(session: requests.Session, url: str, body: dict) -> requests.Response:
    return session.post(url, json=body, timeout=60)


def age_rating_body(declaration_id: str) -> dict:
    none = "NONE"
    attrs = {
        "advertising": False,
        "alcoholTobaccoOrDrugUseOrReferences": none,
        "contests": none,
        "gambling": False,
        "gamblingSimulated": none,
        "gunsOrOtherWeapons": none,
        "healthOrWellnessTopics": False,
        "lootBox": False,
        "medicalOrTreatmentInformation": none,
        "messagingAndChat": False,
        "parentalControls": False,
        "profanityOrCrudeHumor": none,
        "sexualContentGraphicAndNudity": none,
        "sexualContentOrNudity": none,
        "horrorOrFearThemes": none,
        "matureOrSuggestiveThemes": none,
        "unrestrictedWebAccess": False,
        "userGeneratedContent": False,
        "violenceCartoonOrFantasy": none,
        "violenceRealisticProlongedGraphicOrSadistic": none,
        "violenceRealistic": none,
    }
    return {
        "data": {
            "type": "ageRatingDeclarations",
            "id": declaration_id,
            "attributes": attrs,
        }
    }


def review_notes() -> str:
    if REVIEW.exists():
        text = REVIEW.read_text()
        start = text.find("## Notes for reviewer")
        if start >= 0:
            chunk = text[start:].split("## Export compliance")[0]
            lines = [ln.strip() for ln in chunk.splitlines() if ln.strip() and not ln.startswith("#")]
            return "\n".join(lines)
    return (
        "Open Draw or Paint and sketch on the canvas. Music streams from archive.org. "
        "Account tab offers optional StoreKit Studio Pro subscriptions. No login required for core features."
    )


def attach_latest_build(session: requests.Session, app_id: str, version_id: str) -> bool:
    r = session.get(f"{API}/apps/{app_id}/builds", params={"limit": 5, "sort": "-uploadedDate"})
    r.raise_for_status()
    builds = r.json().get("data", [])
    if not builds:
        print("No builds in App Store Connect — upload IPA first (CD workflow or local_testflight_archive.sh).")
        return False
    build = builds[0]
    state = build["attributes"].get("processingState")
    if state != "VALID":
        print(f"Latest build {build['id']} state={state}; wait for VALID before submit.")
        return False
    bid = build["id"]
    pr = patch(
        session,
        f"{API}/appStoreVersions/{version_id}",
        {
            "data": {
                "type": "appStoreVersions",
                "id": version_id,
                "relationships": {"build": {"data": {"type": "builds", "id": bid}}},
            }
        },
    )
    if pr.status_code not in (200, 204):
        print("Attach build failed:", pr.status_code, pr.text[:500])
        return False
    print(f"Attached build {bid} ({build['attributes'].get('version')}) to version {version_id}")
    return True


def main() -> None:
    parser = argparse.ArgumentParser(description="Deploy App Store Connect metadata and submit")
    parser.add_argument("--metadata", action="store_true", help="Push en-AU metadata")
    parser.add_argument("--age-rating", action="store_true", help="Complete age rating questionnaire")
    parser.add_argument("--review", action="store_true", help="Create/update review contact + notes")
    parser.add_argument("--version", default="1.1.0", help="Marketing version string in ASC")
    parser.add_argument("--attach-build", action="store_true", help="Attach newest VALID build")
    parser.add_argument("--submit", action="store_true", help="Submit version for App Review")
    parser.add_argument("--all", action="store_true", help="metadata + age-rating + review + attach + submit")
    args = parser.parse_args()
    if args.all:
        args.metadata = args.age_rating = args.review = args.attach_build = args.submit = True

    connect = load_connect()
    kid, key_path = resolve_key(connect)
    issuer = os.environ.get("ASC_ISSUER_ID") or connect["ascIssuerId"]
    session = requests.Session()
    session.headers["Authorization"] = f"Bearer {bearer(issuer, kid, key_path)}"

    locale = connect.get("primaryLocale", "en-AU")
    version_id = connect["inflightVersionId"]
    loc_id = connect["versionLocalizationId"]
    info_loc_id = connect["appInfoLocalizationId"]
    age_id = connect["ageRatingDeclarationId"]
    app_id = connect["appleAppId"]

    if args.metadata:
        pr = patch(
            session,
            f"{API}/appStoreVersions/{version_id}",
            {"data": {"type": "appStoreVersions", "id": version_id, "attributes": {"versionString": args.version}}},
        )
        print("Version string:", pr.status_code, pr.text[:200] if pr.status_code >= 400 else args.version)

        loc_attrs = {
            "description": read_meta(locale, "description"),
            "keywords": read_meta(locale, "keywords"),
            "whatsNew": read_meta(locale, "release_notes"),
            "promotionalText": read_meta(locale, "promotional_text"),
            "supportUrl": read_meta(locale, "support_url"),
        }
        loc_attrs = {k: v for k, v in loc_attrs.items() if v}
        r = patch(
            session,
            f"{API}/appStoreVersionLocalizations/{loc_id}",
            {"data": {"type": "appStoreVersionLocalizations", "id": loc_id, "attributes": loc_attrs}},
        )
        print("Version localization:", r.status_code)
        if r.status_code >= 400:
            print(r.text[:600])

        info_attrs = {
            "name": "Ethereal Veil",
            "subtitle": read_meta(locale, "subtitle"),
            "privacyPolicyUrl": read_meta(locale, "privacy_url"),
        }
        info_attrs = {k: v for k, v in info_attrs.items() if v}
        r2 = patch(
            session,
            f"{API}/appInfoLocalizations/{info_loc_id}",
            {"data": {"type": "appInfoLocalizations", "id": info_loc_id, "attributes": info_attrs}},
        )
        print("App info localization:", r2.status_code)
        if r2.status_code >= 400:
            print(r2.text[:600])

    if args.age_rating:
        r = patch(session, f"{API}/ageRatingDeclarations/{age_id}", age_rating_body(age_id))
        print("Age rating:", r.status_code)
        if r.status_code >= 400:
            print(r.text[:800])

    if args.review:
        notes = review_notes()
        body = {
            "data": {
                "type": "appStoreReviewDetails",
                "attributes": {
                    "contactFirstName": "Christopher",
                    "contactLastName": "Appiah-Thompson",
                    "contactEmail": "chrsappiah@gmail.com",
                    "notes": notes[:4000],
                },
                "relationships": {
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
                },
            }
        }
        existing = session.get(f"{API}/appStoreVersions/{version_id}/appStoreReviewDetail")
        if existing.json().get("data"):
            detail_id = existing.json()["data"]["id"]
            body["data"]["id"] = detail_id
            r = patch(session, f"{API}/appStoreReviewDetails/{detail_id}", body)
        else:
            r = post(session, f"{API}/appStoreReviewDetails", body)
        print("Review detail:", r.status_code)
        if r.status_code >= 400:
            print(r.text[:600])

    if args.attach_build:
        attach_latest_build(session, app_id, version_id)

    if args.submit:
        if not args.attach_build:
            attach_latest_build(session, app_id, version_id)
        r = post(
            session,
            f"{API}/appStoreVersionSubmissions",
            {
                "data": {
                    "type": "appStoreVersionSubmissions",
                    "relationships": {
                        "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
                    },
                }
            },
        )
        print("Submit for review:", r.status_code)
        if r.status_code >= 400:
            print(r.text[:1000])
        else:
            print("Submitted successfully.")

    if not any([args.metadata, args.age_rating, args.review, args.attach_build, args.submit, args.all]):
        parser.print_help()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Create Studio Pro subscriptions in App Store Connect (group, products, pricing, screenshots)."""

from __future__ import annotations

import hashlib
import json
import os
import sys
import time
from pathlib import Path

import jwt
import requests

ROOT = Path(__file__).resolve().parents[1]
PRODUCTS = json.loads((ROOT / "distribution/app-store/connect/products.json").read_text())
API = "https://api.appstoreconnect.apple.com/v1"
APP_ID = "6763116253"


def resolve_key() -> tuple[str, Path]:
    kid = os.environ.get("ASC_KEY_ID", "A863K5FF84")
    for path in [
        Path(os.environ["ASC_KEY_PATH"]) if os.environ.get("ASC_KEY_PATH") else None,
        Path.home() / ".appstoreconnect/private_keys" / f"AuthKey_{kid}.p8",
        Path.home() / "Downloads" / f"AuthKey_{kid}.p8",
    ]:
        if path and path.exists():
            return kid, path
    raise SystemExit(f"Missing AuthKey_{kid}.p8")


def session() -> requests.Session:
    kid, key_path = resolve_key()
    issuer = os.environ.get("ASC_ISSUER_ID", "70c46c69-5d6d-438d-b300-31df2b93163a")
    token = jwt.encode(
        {"iss": issuer, "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"},
        key_path.read_text(),
        algorithm="ES256",
        headers={"kid": kid, "typ": "JWT"},
    )
    s = requests.Session()
    s.headers["Authorization"] = f"Bearer {token}"
    s.headers["Content-Type"] = "application/json"
    return s


def price_point_id(s: requests.Session, subscription_id: str, aud_price: str) -> str:
    url = f"{API}/subscriptions/{subscription_id}/pricePoints?filter[territory]=AUS&limit=200"
    while url:
        r = s.get(url, timeout=60)
        r.raise_for_status()
        for point in r.json().get("data", []):
            if point["attributes"].get("customerPrice") == aud_price:
                return point["id"]
        url = r.json().get("links", {}).get("next")
    raise SystemExit(f"No AUS price point for {aud_price} on {subscription_id}")


def set_worldwide_prices(s: requests.Session, subscription_id: str, aus_price: str) -> None:
    pid = price_point_id(s, subscription_id, aus_price)
    ids: list[str] = []
    url = f"{API}/subscriptionPricePoints/{pid}/equalizations?limit=200"
    while url:
        r = s.get(url, timeout=60)
        r.raise_for_status()
        ids.extend(p["id"] for p in r.json().get("data", []))
        url = r.json().get("links", {}).get("next")
    for ppid in ids:
        s.post(
            f"{API}/subscriptionPrices",
            json={
                "data": {
                    "type": "subscriptionPrices",
                    "relationships": {
                        "subscription": {"data": {"type": "subscriptions", "id": subscription_id}},
                        "subscriptionPricePoint": {
                            "data": {"type": "subscriptionPricePoints", "id": ppid}
                        },
                    },
                }
            },
            timeout=30,
        )
    print(f"  Pricing: {subscription_id} ({len(ids)} territories)")


def upload_review_screenshot(s: requests.Session, subscription_id: str, image: Path) -> None:
    data = image.read_bytes()
    checksum = hashlib.md5(data).hexdigest()
    r = s.post(
        f"{API}/subscriptionAppStoreReviewScreenshots",
        json={
            "data": {
                "type": "subscriptionAppStoreReviewScreenshots",
                "attributes": {"fileSize": len(data), "fileName": image.name},
                "relationships": {
                    "subscription": {"data": {"type": "subscriptions", "id": subscription_id}}
                },
            }
        },
        timeout=30,
    )
    r.raise_for_status()
    sc_id = r.json()["data"]["id"]
    for op in r.json()["data"]["attributes"]["uploadOperations"]:
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        chunk = data[op.get("offset", 0) : op.get("offset", 0) + op.get("length", len(data))]
        requests.put(op["url"], data=chunk, headers=headers, timeout=120).raise_for_status()
    s.patch(
        f"{API}/subscriptionAppStoreReviewScreenshots/{sc_id}",
        json={
            "data": {
                "type": "subscriptionAppStoreReviewScreenshots",
                "id": sc_id,
                "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
            }
        },
        timeout=30,
    ).raise_for_status()
    print(f"  Screenshot: {subscription_id}")


def main() -> None:
    s = session()
    group_name = PRODUCTS.get("subscriptionGroup", "Studio Pro")

    groups = s.get(f"{API}/apps/{APP_ID}/subscriptionGroups").json().get("data", [])
    group_id = groups[0]["id"] if groups else None
    if not group_id:
        r = s.post(
            f"{API}/subscriptionGroups",
            json={
                "data": {
                    "type": "subscriptionGroups",
                    "attributes": {"referenceName": group_name},
                    "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
                }
            },
            timeout=30,
        )
        r.raise_for_status()
        group_id = r.json()["data"]["id"]
        print(f"Created group {group_id}")

    screenshot = ROOT / "distribution/app-store/screenshots/en-AU/iphone_67_01_draw.png"
    if not screenshot.exists():
        screenshot = ROOT / "fastlane/deliver/screenshots/en-AU/iphone67_01.png"

    period_map = {"1 month": "ONE_MONTH", "1 year": "ONE_YEAR"}
    price_map = {"$4.99": "4.99", "$39.99": "39.99"}

    for product in PRODUCTS["products"]:
        pid = product["productId"]
        existing = s.get(
            f"{API}/apps/{APP_ID}/subscriptions",
            params={"filter[productId]": pid},
            timeout=30,
        )
        sub_id = None
        if existing.status_code == 200 and existing.json().get("data"):
            sub_id = existing.json()["data"][0]["id"]
        if not sub_id:
            r = s.post(
                f"{API}/subscriptions",
                json={
                    "data": {
                        "type": "subscriptions",
                        "attributes": {
                            "name": product["referenceName"],
                            "productId": pid,
                            "subscriptionPeriod": period_map[product["duration"]],
                            "reviewNote": "Studio Pro unlocks painting, cloud backup, music, unlimited saves.",
                        },
                        "relationships": {
                            "group": {"data": {"type": "subscriptionGroups", "id": group_id}}
                        },
                    }
                },
                timeout=30,
            )
            r.raise_for_status()
            sub_id = r.json()["data"]["id"]
            print(f"Created subscription {pid} -> {sub_id}")

        for locale, name, desc in [
            ("en-AU", product["referenceName"], "Full Studio Pro access."),
            ("en-US", product["referenceName"], "Full Studio Pro access."),
        ]:
            s.post(
                f"{API}/subscriptionLocalizations",
                json={
                    "data": {
                        "type": "subscriptionLocalizations",
                        "attributes": {"name": name, "description": desc, "locale": locale},
                        "relationships": {
                            "subscription": {"data": {"type": "subscriptions", "id": sub_id}}
                        },
                    }
                },
                timeout=30,
            )

        s.post(
            f"{API}/subscriptionAvailabilities",
            json={
                "data": {
                    "type": "subscriptionAvailabilities",
                    "attributes": {"availableInNewTerritories": False},
                    "relationships": {
                        "subscription": {"data": {"type": "subscriptions", "id": sub_id}},
                        "availableTerritories": {"data": [{"type": "territories", "id": "AUS"}]},
                    },
                }
            },
            timeout=30,
        )
        set_worldwide_prices(s, sub_id, price_map[product["priceTier"]])
        upload_review_screenshot(s, sub_id, screenshot)

        state = s.get(f"{API}/subscriptions/{sub_id}", timeout=30).json()["data"]["attributes"]["state"]
        print(f"  State: {state}")

    print("Done. Submit IAPs with the app version in App Store Connect (first subscription must ship with a version).")


if __name__ == "__main__":
    main()

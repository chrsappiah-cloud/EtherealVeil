#!/usr/bin/env python3
"""
App Store production tracker for EtherealVeil.

Stores release process state in JSON so each stage is visible and auditable.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List


DEFAULT_TRACKER_PATH = Path(
    "release_tracking/appstore_production_tracker.json"
)
STAGES = [
    "preflight",
    "release_build",
    "archive",
    "export_ipa",
    "upload_app_store_connect",
    "processing",
    "testflight_internal",
    "testflight_external",
    "app_review",
    "released",
]
VALID_STATUS = {"pending", "in_progress", "done", "blocked", "skipped"}


@dataclass
class Tracker:
    path: Path
    data: Dict

    @staticmethod
    def now_iso() -> str:
        return datetime.now(timezone.utc).replace(microsecond=0).isoformat()

    @classmethod
    def load(cls, path: Path) -> "Tracker":
        if not path.exists():
            return cls(
                path=path,
                data={"releases": [], "last_updated": cls.now_iso()},
            )
        return cls(path=path, data=json.loads(path.read_text(encoding="utf-8")))

    def save(self) -> None:
        self.data["last_updated"] = self.now_iso()
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(self.data, indent=2), encoding="utf-8")

    def find_release(self, release_id: str) -> Dict:
        for rel in self.data["releases"]:
            if rel["id"] == release_id:
                return rel
        raise SystemExit(f"Release '{release_id}' not found.")


def stage_template() -> Dict[str, Dict[str, str]]:
    now = Tracker.now_iso()
    return {
        stage: {"status": "pending", "updated_at": now, "note": ""}
        for stage in STAGES
    }


def cmd_init(args: argparse.Namespace) -> None:
    tracker = Tracker.load(args.path)
    tracker.save()
    print(f"Tracker initialized at {args.path}")


def cmd_create(args: argparse.Namespace) -> None:
    tracker = Tracker.load(args.path)
    release_id = f"{args.version}+{args.build}"
    try:
        tracker.find_release(release_id)
        raise SystemExit(f"Release '{release_id}' already exists.")
    except SystemExit as exc:
        if "not found" not in str(exc):
            raise

    now = Tracker.now_iso()
    release = {
        "id": release_id,
        "version": args.version,
        "build": args.build,
        "created_at": now,
        "delivery_uuid": args.delivery_uuid or "",
        "stages": stage_template(),
        "notes": [],
    }
    if args.note:
        release["notes"].append({"at": now, "message": args.note})
    tracker.data["releases"].append(release)
    tracker.save()
    print(f"Created release {release_id}")


def cmd_update(args: argparse.Namespace) -> None:
    if args.status not in VALID_STATUS:
        raise SystemExit(
            f"Invalid status '{args.status}'. Valid: {sorted(VALID_STATUS)}"
        )
    if args.stage not in STAGES:
        raise SystemExit(f"Invalid stage '{args.stage}'. Valid: {STAGES}")

    tracker = Tracker.load(args.path)
    release = tracker.find_release(args.release)
    stage = release["stages"][args.stage]
    stage["status"] = args.status
    stage["updated_at"] = Tracker.now_iso()
    if args.note is not None:
        stage["note"] = args.note
    if args.delivery_uuid:
        release["delivery_uuid"] = args.delivery_uuid
    tracker.save()
    print(f"Updated {args.release} :: {args.stage} -> {args.status}")


def cmd_note(args: argparse.Namespace) -> None:
    tracker = Tracker.load(args.path)
    release = tracker.find_release(args.release)
    release["notes"].append({"at": Tracker.now_iso(), "message": args.message})
    tracker.save()
    print(f"Added note to {args.release}")


def release_progress(release: Dict) -> str:
    stages = release["stages"]
    done = sum(1 for stage in STAGES if stages[stage]["status"] == "done")
    return f"{done}/{len(STAGES)}"


def print_release(release: Dict) -> None:
    progress = release_progress(release)
    print(
        f"- {release['id']}  version={release['version']} "
        f"build={release['build']}  progress={progress}"
    )
    if release.get("delivery_uuid"):
        print(f"  delivery_uuid: {release['delivery_uuid']}")
    for stage in STAGES:
        meta = release["stages"][stage]
        line = f"  [{meta['status']:<11}] {stage}"
        if meta.get("note"):
            line += f" :: {meta['note']}"
        print(line)


def cmd_show(args: argparse.Namespace) -> None:
    tracker = Tracker.load(args.path)
    releases: List[Dict]
    if args.release:
        releases = [tracker.find_release(args.release)]
    else:
        releases = tracker.data["releases"]

    if not releases:
        print("No releases tracked yet.")
        return
    for rel in releases:
        print_release(rel)


def cmd_next(args: argparse.Namespace) -> None:
    tracker = Tracker.load(args.path)
    release = tracker.find_release(args.release)
    for stage in STAGES:
        status = release["stages"][stage]["status"]
        if status in {"pending", "blocked", "in_progress"}:
            print(f"{release['id']} next_stage={stage} status={status}")
            return
    print(f"{release['id']} has no remaining pending stages.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Track App Store production status."
    )
    parser.add_argument(
        "--path",
        type=Path,
        default=DEFAULT_TRACKER_PATH,
        help=f"Tracker JSON path (default: {DEFAULT_TRACKER_PATH})",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser(
        "init",
        help="Create tracker file if missing",
    ).set_defaults(func=cmd_init)

    p_create = sub.add_parser("create", help="Create a tracked release")
    p_create.add_argument(
        "--version",
        required=True,
        help="Marketing version, e.g. 1.0.0",
    )
    p_create.add_argument(
        "--build",
        required=True,
        help="Build number, e.g. 12",
    )
    p_create.add_argument(
        "--delivery-uuid",
        help="App Store delivery UUID if available",
    )
    p_create.add_argument("--note", help="Optional initial note")
    p_create.set_defaults(func=cmd_create)

    p_update = sub.add_parser(
        "update",
        help="Update stage status for a release",
    )
    p_update.add_argument(
        "--release",
        required=True,
        help="Release ID: <version>+<build>",
    )
    p_update.add_argument(
        "--stage",
        required=True,
        help=f"One of: {', '.join(STAGES)}",
    )
    p_update.add_argument(
        "--status",
        required=True,
        help=f"One of: {', '.join(sorted(VALID_STATUS))}",
    )
    p_update.add_argument("--note", help="Optional stage note")
    p_update.add_argument("--delivery-uuid", help="Set/update delivery UUID")
    p_update.set_defaults(func=cmd_update)

    p_note = sub.add_parser("note", help="Append release-level note")
    p_note.add_argument(
        "--release",
        required=True,
        help="Release ID: <version>+<build>",
    )
    p_note.add_argument("--message", required=True, help="Note text")
    p_note.set_defaults(func=cmd_note)

    p_show = sub.add_parser("show", help="Display one or all releases")
    p_show.add_argument("--release", help="Release ID: <version>+<build>")
    p_show.set_defaults(func=cmd_show)

    p_next = sub.add_parser("next", help="Show next pending stage")
    p_next.add_argument(
        "--release",
        required=True,
        help="Release ID: <version>+<build>",
    )
    p_next.set_defaults(func=cmd_next)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

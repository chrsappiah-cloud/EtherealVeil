# App Store Tracking System

This project includes a lightweight production tracker for monitoring iOS release progress from preflight through App Store release.

## Files

- `scripts/appstore_tracker.py` - CLI for tracking release stages.
- `release_tracking/appstore_production_tracker.json` - persistent tracker state.

## Tracked stages

1. `preflight`
2. `release_build`
3. `archive`
4. `export_ipa`
5. `upload_app_store_connect`
6. `processing`
7. `testflight_internal`
8. `testflight_external`
9. `app_review`
10. `released`

## Quick start

Initialize tracker file:

```bash
python3 scripts/appstore_tracker.py init
```

Create a release entry:

```bash
python3 scripts/appstore_tracker.py create --version 1.0.0 --build 12 --note "Production kickoff"
```

Show current status:

```bash
python3 scripts/appstore_tracker.py show --release 1.0.0+12
```

Update stages as work progresses:

```bash
python3 scripts/appstore_tracker.py update --release 1.0.0+12 --stage preflight --status done
python3 scripts/appstore_tracker.py update --release 1.0.0+12 --stage release_build --status done
python3 scripts/appstore_tracker.py update --release 1.0.0+12 --stage archive --status done
python3 scripts/appstore_tracker.py update --release 1.0.0+12 --stage export_ipa --status done
python3 scripts/appstore_tracker.py update --release 1.0.0+12 --stage upload_app_store_connect --status done --delivery-uuid "<DELIVERY_UUID>"
```

Add notes (e.g. App Review feedback):

```bash
python3 scripts/appstore_tracker.py note --release 1.0.0+12 --message "App Review requested metadata clarification."
```

See next action:

```bash
python3 scripts/appstore_tracker.py next --release 1.0.0+12
```

## Status values

- `pending` - not started
- `in_progress` - currently being worked on
- `done` - completed
- `blocked` - waiting on an external dependency
- `skipped` - intentionally not required for this release

## Recommended operating model

- Update tracker after every major production command.
- Record Delivery UUID immediately after successful upload.
- Keep processing/TestFlight/App Review states current daily during release week.
- Treat tracker JSON as a source-of-truth artifact and commit updates with release notes.

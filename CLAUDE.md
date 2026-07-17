# AppConfigShelf — AI Agent Instructions

Flutter Desktop (Windows-only) app: backup/restore application configurations before Windows reinstall. Pre-code phase; architecture is fully specified.

## Read this first

All architecture decisions live in `docs/plan/`. Start at `docs/plan/00-index.md` and read only the files relevant to your task. Do not re-derive or contradict decisions recorded there; if a decision must change, update the relevant plan doc in the same PR.

## Key facts

- Monorepo (melos): `apps/shelf_app` (Flutter, fluent_ui, Riverpod MVVM) + pure-Dart engine packages under `packages/` (`shelf_core`, `shelf_rules`, `shelf_detect`, `shelf_backup`, `shelf_db`, `shelf_win32`).
- Dependency direction: UI → app layer → engines. Engines never import Flutter.
- App database is a **separate repo** (`appconfigshelf-db`): YAML source, compiled+signed JSON releases.
- Backup package format `.acshelf` = ZIP + `manifest.json`. Format spec: `docs/plan/05-backup-format.md`.
- Backup = best-effort with report. Restore = conservative, staged, per-app atomic, always produces an undo bundle.
- Paths stored tokenized (`%APPDATA%`, ...), resolved via Known Folders API, never env vars.
- Errors in engines are typed sealed-class failures returned as values, not exceptions.

## Development order

Follow `docs/plan/12-roadmap.md` (milestones M0–M5). Engines before UI; format specs before engines.

## Conventions

- Windows-specific I/O only inside `shelf_win32` behind interfaces; everything else must run (and be tested) on Linux CI.
- Every cross-boundary payload (manifest, db bundle, IPC) is versioned JSON.
- Security constraints in `docs/plan/10-security.md` are hard requirements, not suggestions.

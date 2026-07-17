# Roadmap: MVP, Milestones, Dev Order, Risks

## MVP definition

**In:**
- Detection: registry Uninstall keys + path probes.
- Database: fetch signed bundle from db-repo releases, with a bundled fallback copy.
- Backup: file-based only (AppData / LocalAppData / Documents — user-writable), zip package, manifest, hashes, per-app selection.
- **Custom items:** user-defined folders/files with names + excludes, persisted locally, first-class in the package.
- Restore: detection-gated for db entries, **complete or selective restore** (checkbox tree, tri-state groups), conflict prompts, undo bundle.
- ~50 curated db entries (VS Code, browsers, terminals, git config, 7-Zip, ... — dev-tool audience first).
- Fluent UI wizard flows, progress + report screens, logging, crash handler.

**Out (explicitly):** registry backup, elevation/ProgramData, winget install, encryption, compression beyond zip, plugins, cloud, profiles, portable-app detection.

**Why this cut:** the end-to-end product promise (backup → reinstall → restore) with zero elevated risk surface. Registry restore is the highest-danger feature — ship it only after the file path is proven. Custom items and selective restore are in because both are cheap on top of the existing design and core to product value.

## Milestones

- **M0 (2–3 wk):** monorepo scaffold, `shelf_core` entities, db schema v1 + validator, format spec ADRs.
- **M1 (3–4 wk):** detection engine + resolver, registry via win32 FFI, detected-apps list UI.
- **M2 (3–4 wk):** rule engine, backup pipeline, custom items, `.acshelf` writer, backup wizard.
- **M3 (3–4 wk):** restore pipeline (complete + selective), undo, round-trip test gate, restore wizard.
- **M4 (2–3 wk):** db repo public + CONTRIBUTING, db auto-update in app, 50 entries, signing.
- **M5 (2 wk):** polish, MSIX, winget submission, docs → **v1.0**.
- **v1.x:** winget-install of missing apps; registry backup/restore + elevated helper; portable detection.
- **v2.x:** encryption, zstd, profiles, snapshot diff, plugins.

## Recommended development order

1. Format specs + ADRs first (db schema, `.acshelf`, manifest) — paper is cheap, format breaks are not.
2. `shelf_core` + `shelf_rules` with fixture tests (pure Dart, no Windows needed).
3. `shelf_win32` registry read + known folders, verified on a real machine.
4. Detection engine — early visible win (app list on screen).
5. Backup pipeline + package writer (incl. custom items).
6. Restore + selective selection + undo + round-trip gate.
7. UI wizards (thin layer over proven engines).
8. Db repo + community docs **before** 1.0 — seed contributors during beta.

**Why engines before UI:** UI over an unstable engine is rework twice; CLI-driveable engines also provide a free smoke-test harness.

## Technical risks

| Risk | Severity | Mitigation |
|---|---|---|
| Restore corrupts user config | Critical | Undo bundle, staging writes, round-trip gate, conservative policy |
| Db PR supply-chain attack | High | Schema constraints + runtime enforcement + signing + review ([10-security.md](10-security.md)) |
| Locked files (running browsers) | High | MVP: detect + warn + skip; later VSS via Rust helper |
| Long paths / unicode / junctions | Medium | Explicit test matrix from day 1; `\\?\` handling in file layer |
| Fuzzy app identity (installers churn GUIDs/names) | Medium | Multi-evidence resolver + confidence + aliases |
| Flutter desktop win32 gaps | Medium | Tier strategy ([03-windows-native.md](03-windows-native.md)); Rust escape hatch |
| Community doesn't show up → stale db | Medium | Unknown-apps flywheel, dead-simple YAML entries, "export as db draft" tool |
| SmartScreen scares users pre-signing | Low-Med | Winget distribution, signing budget |

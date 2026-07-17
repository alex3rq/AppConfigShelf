# Backup Package Format (`.acshelf`)

A single `.acshelf` file = **ZIP container with a manifest**.

```
backup-2026-07-17.acshelf (zip)
├── manifest.json        format version, app version, db version, machine info,
│                        entry list (apps + custom items), per-file sha256,
│                        sizes, timestamps
├── apps/
│   ├── vscode/
│   │   ├── files/       mirrored tree of backed-up files
│   │   └── registry.reg (future)
│   └── firefox/...
├── custom/
│   └── <slug>/
│       └── files/       mirrored tree, same structure as apps
└── logs/scan-report.json
```

**Why ZIP:** inspectable with any archive tool — trust plus disaster recovery. If the app dies in ten years, the user can still extract their files by hand. The manifest carries everything needed to restore on a machine that has never seen the backup. Per-file hashes enable integrity verification before restore.

## Manifest entries

Every entry has `source: database` or `source: custom`.

- **Database entries** (`apps/<id>/`): reference the db `id`; restore is detection-gated.
- **Custom entries** (`custom/<slug>/`): user-defined name + the rules used (paths, include/exclude); restore is **not** detection-gated (no app to detect) and is always offered.

## Path storage

- Paths are stored **tokenized** (`%APPDATA%/Code/User/settings.json`) whenever they fall under a known folder — they must survive a different username or drive on the new install.
- Custom-item paths outside any known folder are stored absolute with `absolute: true`; restore warns if the drive/root doesn't exist on the target machine.
- Tokens resolve via the Known Folders API, never environment variables.

## Format versioning

`manifest.json` carries an integer format version from day 1. The app maintains read compatibility with **all** past format versions forever — a 5-year-old backup must restore; that is the core promise. Future zstd compression or encryption arrives as a new format version; old readers remain supported.

## Undo bundle

Every restore writes displaced files into a `.acshelf-undo` bundle (same container format) before overwriting. See [06-workflows.md](06-workflows.md).

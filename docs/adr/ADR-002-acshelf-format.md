# ADR-002: `.acshelf` Backup Package Format v1

Status: accepted · Date: 2026-07-17

## Context

The backup package must be restorable on a machine that has never seen it, inspectable without AppConfigShelf, and readable by every future app version forever ([docs/plan/05-backup-format.md](../plan/05-backup-format.md)).

## Decision

`.acshelf` = standard ZIP (deflate), containing:

```
manifest.json                required, at archive root
apps/<entryId>/files/...     mirrored file tree per database entry
custom/<slug>/files/...      mirrored file tree per custom item
logs/scan-report.json        operation log of the backup run
```

### manifest.json (format v1)

```jsonc
{
  "formatVersion": 1,
  "createdAt": "2026-07-17T12:00:00Z",        // UTC ISO-8601
  "appVersion": "0.1.0",
  "dbSchemaVersion": 1,
  "dbContentVersion": "2026.07.1",
  "machine": { "hostname": "...", "windowsBuild": "..." },
  "entries": [
    {
      "source": "database",                    // "database" | "custom"
      "id": "vscode",                          // db id, or custom slug
      "name": "Visual Studio Code",
      "risk": "safe",
      "rules": [ /* the BackupRules used, serialized */ ],
      "files": [
        {
          "storedPath": "apps/vscode/files/APPDATA/Code/User/settings.json",
          "targetPath": "%APPDATA%\\Code\\User\\settings.json",
          "absolute": false,                   // true only for custom items
          "sha256": "...",
          "size": 1234,
          "modifiedAt": "..."
        }
      ],
      "skipped": [ { "targetPath": "...", "reason": "fileLocked" } ]
    }
  ]
}
```

Key rules:

- `targetPath` is **tokenized** whenever the file lies under a known folder; `absolute: true` (custom items only) stores the original absolute path and triggers a restore-time warning if the root is missing.
- Inside the archive, token roots become plain directory names (`APPDATA/`, `USERPROFILE/`; absolute roots become `ABS/C/...`) so the zip is browsable by hand.
- Every file has a `sha256`; restore verifies before writing.
- `skipped` records what backup could not capture (best-effort policy) so the user knows.

### Compatibility contract

- `formatVersion` is an integer. Readers must support **all** past versions forever; a 5-year-old backup must restore.
- Unknown manifest fields are ignored (forward compatibility). Compression change (zstd) or encryption = new `formatVersion`, old readers keep working on old packages.
- Undo bundles (`.acshelf-undo`) use this same container format.

## Consequences

- Any archive tool can extract user files if the app is gone — disaster-recovery insurance and a trust signal.
- Manifest is self-contained: restore needs no local state, only the package and a current db (for detection gating of `database` entries; `custom` entries restore without detection).
- Selective restore is a pure manifest filter — no format implications.

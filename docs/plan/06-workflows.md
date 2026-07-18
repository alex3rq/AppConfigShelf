# Backup & Restore Workflows

## Backup workflow

1. Detect apps ([07-engines.md](07-engines.md)) → list with per-app estimated size and risk tag.
2. User selects apps and optional sub-items (rules can define selectable groups, e.g. "extensions" vs "settings").
3. **Custom items:** user adds arbitrary folders/files via picker, names each item, optionally sets exclude globs. Saved custom items persist in local app state (drift DB) and are pre-listed on the next backup.
4. Pre-flight: locked-file check, disk-space check, warn about running apps.
5. Execute in an isolate: enumerate → filter (include/exclude/ignore-cache rules) → hash → stream into the package. Progress as an event stream to the UI.
6. Verify pass: re-read hashes.
7. Emit manifest + summary report.

**Why an isolate:** enumerating large config dirs blocks the UI thread otherwise. **Why hash at backup time:** enables restore-time verification and future dedup.

Policy: backup is **best-effort with report** — skip a locked file, record it, keep going.

## Restore workflow

1. Open package → verify manifest + hashes.
2. Load current database → run detection on the new system.
3. Match backup entries ↔ detected apps (db `id`, fallback alias match). Custom items skip matching entirely.
4. **Selection step — complete or selective restore.** The wizard shows the full manifest as a tree: app entries (groupable), custom items — each with a checkbox and tri-state group selection.
   - *Complete restore:* everything restorable pre-checked.
   - *Selective restore:* user picks single apps, groups, or individual custom items.
   Selection simply filters the restore plan; the pipeline is identical for both modes.
5. Per-entry status shown in the tree: **restorable** (app detected, or custom item), **app missing** (offer winget install later), **conflict** (existing config present → user picks overwrite / skip / keep-copy). A db-sourced entry whose id the current database (official + local library) doesn't know — typically a "My library" entry from the old machine — is restorable with a warning ("entry not in database — restores to recorded paths") when all its targets are tokenized.
6. Pre-restore checks: target apps not running (process detection); custom-item absolute paths verified to exist as roots.
7. Execute: per entry, per file — token→path expansion, write to a staging temp location, then atomic move. Existing files are saved into a `.acshelf-undo` bundle first.
8. Report: per-entry success/skip/fail, with an undo option. The undo bundle covers exactly what was restored (relevant for selective restores).

Policy: restore is **conservative** — verify everything up front, per-entry atomicity, halt that entry's restore on first write failure, always offer undo.

**Why staging + undo:** restore is the dangerous half — it overwrites live config. Atomic per-file writes, journaled, resumable; the undo bundle is the trust feature competitors lack.

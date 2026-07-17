# Quality: Testing, Logging, Errors, Performance

## Testing strategy

- **Unit (the bulk):** rule engine, resolver, manifest, token expansion — pure Dart against fake `FileSystemView`/`RegistryView`; runs on cheap Linux CI.
- **Golden fixtures:** sanitized real-world registry exports and directory-tree snapshots (JSON) for detector tests.
- **Integration (Windows runners):** load registry hive fixtures via `reg load` (never mutate the runner's real HKCU where avoidable); real backup/restore round-trips in temp dirs; explicit matrix: paths >260 chars, unicode filenames, junctions/symlinks, read-only attributes.
- **Round-trip property test (the product gate):** backup → wipe staging → restore → tree-diff equals original. This test *is* the product guarantee; it gates releases.
- **Db CI:** every entry validates against schema and compiles through `shelf_rules`.
- **UI:** widget tests for wizards; skip fragile desktop E2E automation initially.

## Logging

- Structured JSON-lines via the `logging` package with a custom sink → `%LOCALAPPDATA%\AppConfigShelf\logs`, rotated, 7-file retention.
- Every backup/restore embeds its **operation log inside the package/undo bundle** — debugging a restore years later starts from the artifact itself.
- File sink = debug level; dev console = info.
- **No telemetry in MVP.** If ever added: opt-in only — this is a privacy-sensitive tool and trust is the product.
- Scrub usernames from any shareable logs (tokenize paths — same mechanism as the package format).

## Error handling

- Engine packages return **typed failures** (sealed classes: `AccessDenied`, `FileLocked`, `PathTooLong`, `HashMismatch`, ...) as values (`Result` style), never thrown across package boundaries. **Why:** the backup pipeline must aggregate per-file failures and continue; exceptions unwind, values accumulate.
- Policy split: **backup = best-effort with report**; **restore = conservative** (up-front verification, per-entry atomicity, undo). See [06-workflows.md](06-workflows.md).
- Every failure maps to an actionable UI message ("File locked by Code.exe — close VS Code and retry"), never a raw errno.
- Global crash handler → log + crash-report file the user can attach to a GitHub issue.

## Performance

- All scanning/hashing/compression in isolates; the UI thread only renders progress.
- Registry Uninstall enumeration is milliseconds; file-size estimation is slow → lazy, per-selected-app, cached.
- Hash and zip via streaming — browser profiles contain multi-GB files; never load whole files into memory.
- Db load: parse the compiled JSON once at startup (<100 ms for thousands of entries), keep in memory. No SQLite needed at this scale.

# ADR-001: Database Entry Schema v1

Status: accepted · Date: 2026-07-17

## Context

The community database ([docs/plan/04-database.md](../plan/04-database.md)) needs a stable, human-writable entry format. Format breaks are expensive once entries exist, so the schema is pinned before any code beyond the parser.

## Decision

YAML source, one file per app, compiled to JSON for release. Schema v1 fields:

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes | `^[a-z0-9][a-z0-9-]*$`, unique across db |
| `name` | string | yes | display name |
| `publisher` | string | no | |
| `aliases` | string[] | no | for fuzzy detection matching |
| `detect` | rule[] | yes, ≥1 | OR semantics |
| `backup` | rule[] | yes, ≥1 | |
| `registry` | — | reserved | registry backup rules, schema v2 |
| `winget` | string | no | winget package id |
| `risk` | enum | no | `safe` (default) \| `caution` \| `expert` |

Detection rule = exactly one of:
- `{registry: <key path>}` — key path must start with `HKCU`/`HKLM` (long forms accepted)
- `{path: <tokenized path>}`
- `{msix: <package family name>}`

Backup rule:
- `path` (required): tokenized path — **absolute paths and `..`/`.` segments are schema errors** (security, [docs/plan/10-security.md](../plan/10-security.md))
- `include` (string[]): globs relative to `path`; empty = everything
- `exclude` (string[]): globs; **exclude always wins over include**
- `optional` (bool, default false): unchecked by default in UI
- `sizeWarning` (bool, default false): UI must surface size

Tokenized path = `%TOKEN%\segments...` where token ∈ `%APPDATA%`, `%LOCALAPPDATA%`, `%PROGRAMDATA%`, `%USERPROFILE%`, `%DOCUMENTS%`. Resolved via Known Folders API at runtime, never environment variables.

Unknown top-level fields are **warnings, not errors** — forward compatibility: an old app build can consume a db bundle containing future fields.

## Canonical implementation

`packages/shelf_rules/lib/src/entry_parser.dart` (`parseAppEntryYaml` / `parseAppEntry`). The db repo's CI validator imports this same parser — the schema has exactly one implementation, so app and db cannot drift.

Versioning: `schemaVersion` integer in the compiled bundle; app declares a supported range. This document is amended (new ADR) for schema v2+.

## Consequences

- Contributors write small YAML files; CI errors carry dotted field paths (`backup[0].path`).
- Security constraints are parse-time hard errors and re-checked at runtime (defense in depth).
- `%DOCUMENTS%` is a distinct token (not `%USERPROFILE%\Documents`) because Documents can be relocated/redirected.

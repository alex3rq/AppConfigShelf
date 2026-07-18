# Community Database

Separate repo: `appconfigshelf-db`. Inspired by Winapp2 but structured.

## Data provenance & licensing

Seed data will likely be derived from [Winapp2](https://github.com/MoscaDotTo/Winapp2) (`winapp2.ini`), converted and heavily modified/optimized to our schema and backup-oriented needs (Winapp2 is cleaning-oriented; we invert its intent — its "delete these" paths are often exactly our "back these up" paths, minus caches).

Winapp2 is licensed **CC-BY-SA-4.0**, which obligates us to:

1. **Attribution** — credit Winapp2 and its contributors.
2. **Indicate modifications** — state that entries were converted/modified.
3. **Share-alike** — derived entries must remain under CC-BY-SA-4.0.

Consequence for repo licensing (this is a driver of the app/db split, alongside cadence and contributor-pool reasons):

- `appconfigshelf-db` → **CC-BY-SA-4.0**, with an ATTRIBUTION/NOTICE file crediting Winapp2 and describing the conversion. Community contributions enter under the same license.
- `appconfigshelf` (app) → permissive license (MIT or Apache-2.0). The app only *consumes* the compiled data bundle at runtime; it contains no Winapp2-derived content, so share-alike does not propagate to the app code.
- Keep the boundary clean: no db-derived entry data hardcoded in the app repo (the bundled fallback db copy ships as a clearly-marked CC-BY-SA data asset, not source code).
- Per-entry provenance field (e.g. `origin: winapp2 | original`) in the db so purely original entries are identifiable if licensing strategy ever needs it.

## Format decision

**YAML source files (one per app) → compiled JSON bundle per release → app caches parsed form.**

| Format | Pros | Cons |
|---|---|---|
| INI (Winapp2 style) | Familiar to Winapp2 contributors | No nesting; structured detection/backup/restore rules don't fit; parsing hacks accumulate |
| JSON per app | Universal, diffable | No comments, verbose for humans |
| **YAML per app** (chosen source) | Human-friendly, comments, PR-reviewable, small diffs | Ambiguity footguns — use a strict subset, validate hard |
| SQLite / binary | Fast queries / compact | Un-reviewable PRs kill community contribution |

**Why:** community contribution is the whole point, so the source of truth must be text with one app per file (small diffs, few merge conflicts, per-vendor CODEOWNERS possible). The release pipeline validates and compiles everything into a single `db.json` + `db-version.json` (schema version, content version, sha256, signature). The app downloads the compiled artifact — it never parses thousands of YAML files at runtime.

## Versioning

- `schemaVersion` (integer, moves rarely) — the app declares a supported range.
- `contentVersion` (CalVer, e.g. `2026.07.1`) — content is snapshot-like; SemVer is meaningless for it.

Database releases stay backward-compatible within a schema major. App updates and db updates are fully decoupled: the app auto-checks for new db releases on launch (opt-out) without needing an app update.

## Entry format (sketch — formal JSON Schema lives in the db repo)

```yaml
id: vscode
name: Visual Studio Code
publisher: Microsoft
aliases: [code, vs-code]
detect:
  - registry: HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\{771FD6B0-...}
  - path: "%LOCALAPPDATA%\\Programs\\Microsoft VS Code\\Code.exe"
backup:
  - path: "%APPDATA%\\Code\\User"
    include: ["settings.json", "keybindings.json", "snippets/**"]
    exclude: ["workspaceStorage/**", "**/Cache*/**"]
  - path: "%USERPROFILE%\\.vscode\\extensions"
    optional: true
    sizeWarning: true
registry: []          # future: registry backup rules
winget: Microsoft.VisualStudioCode
risk: safe            # safe | caution | expert
```

Fields planned: names, publishers, aliases, detection rules, AppData/LocalAppData/ProgramData/Documents paths, registry keys, ignore/cache folders, backup rules, restore rules, winget id, risk tier, future metadata.

## Ignore list

`ignore.yaml` at the db repo root: case-insensitive display-name glob
patterns for software that is never a backup candidate (runtimes,
redistributables, SDKs, drivers). Compiled into the bundle as an optional
`ignore` array (schema stays v1 — old readers skip unknown fields). The app
moves matching unknown apps into a collapsed "Hidden" section; users also
have a personal hide list (`%APPDATA%\AppConfigShelf\ignored.json`, exact
names). Independently, the registry detector honors Windows conventions:
uninstall entries with `SystemComponent=1`, `ParentKeyName`, or
`ReleaseType` are never emitted at all (Control Panel precedent).

## Local entry library ("My library")

Users can create and edit database entries inside the app, without touching
the community repo:

- Stored as one JSON file per entry (same shape as compiled db entries,
  validated by the same `shelf_rules` parser) in
  `%APPDATA%\AppConfigShelf\local-entries\`.
- Created from the config finder ("Save to my library" — unknown apps become
  detection-gated Recognized apps) or by **editing any official entry**,
  which saves a customized copy under the same id.
- Merge precedence: **local overrides win over official entries** — a
  deliberate user edit beats upstream until the user resets it (delete the
  override). Scan/backup/restore all consume the merged list.
- Contributor bridge: any library entry exports as a YAML draft for a PR to
  the db repo.

## Db repo layout

```
appconfigshelf-db/
├── apps/               one YAML per app: apps/m/microsoft-vscode.yaml
├── schema/             JSON Schema for entries, versioned
├── tools/validator/    CI validation CLI (Dart, reuses shelf_rules)
├── docs/               CONTRIBUTING.md, entry-guide.md
└── .github/workflows/  validate PRs; build + sign release bundle
```

CI on PR: schema validation, id uniqueness, alias collision, glob sanity, lint (e.g. forbid backing up `Cache` dirs without a justification comment). On tag: compile `db.json`, sign (minisign/Ed25519), publish as GitHub Release. The app verifies the signature against a pinned public key.

**Why the validator reuses `shelf_rules`:** a single parser means the db can never drift from what the app accepts. Publish `shelf_rules` to pub or consume as a git dependency.

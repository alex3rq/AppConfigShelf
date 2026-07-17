# Community Database

Separate repo: `appconfigshelf-db`. Inspired by Winapp2 but structured.

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

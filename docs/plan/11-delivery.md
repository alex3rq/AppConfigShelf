# Delivery: CI/CD, Repos, Releases, Versioning

## GitHub organization

Org `AppConfigShelf` (community project: bus factor, per-repo maintainer rights):

- `appconfigshelf` — app monorepo (this repo)
- `appconfigshelf-db` — community database
- `appconfigshelf.github.io` — site/docs (later)

**Why db is a separate repo, not a folder:** different release cadence (db weekly, app monthly), different contributor pool (db contributors need zero Dart knowledge), CODEOWNERS separation.

## CI/CD

**App repo (GitHub Actions):**
- Every PR: `melos run analyze`, `melos run test` — engine packages run on **Linux runners** (pure Dart, fast, cheap); a **Windows runner** job runs integration tests + `flutter build windows`.
- On tag: build, sign, produce MSIX + portable zip, publish GitHub Release, open an automated winget-pkgs manifest PR (`wingetcreate`).

**Why the Linux/Windows split:** most tests are pure Dart; Windows runners are slow and ~2× cost — reserve them for what genuinely needs Windows (real registry/filesystem behavior mocks can't validate).

**Db repo:** PR validation (schema, uniqueness, lint); tag → compile `db.json`, sign, GitHub Release. See [04-database.md](04-database.md).

## Release strategy

- Channels: **stable** + **pre-release** (GitHub prerelease flag). No nightly until there's demand.
- Distribution: **winget primary** (dogfoods our own integration story, sidesteps SmartScreen concerns), GitHub Release assets (MSIX + portable zip).
- Db releases fully decoupled: app auto-checks db updates on launch (opt-out); app updates are manual/winget.
- Code-sign the app when budget allows — SmartScreen trust matters for a tool touching all user configs. Until then, document the SmartScreen bypass honestly.

## Versioning axes (deliberately separate)

| Axis | Scheme | Notes |
|---|---|---|
| App | SemVer `MAJOR.MINOR.PATCH` | UI churns fast |
| Backup package format | Integer in manifest | Read-compat for **all** past versions, forever |
| Db schema | Own major version | App declares supported range |
| Db content | CalVer `2026.07.1` | Snapshot-like; SemVer meaningless |

**Why separate:** coupling them forces false majors or, worse, silent format breaks. Formats must move glacially while the app moves fast.

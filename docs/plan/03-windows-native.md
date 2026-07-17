# Native Windows Integration

Three tiers; escalate only when needed.

## Tier 1 — Dart `win32` package (FFI) — default

Registry read/write, `SHGetKnownFolderPath`, process enumeration, MSI/Uninstall keys, MSIX package queries. Covers ~90% of needs with no native build complexity.

## Tier 2 — Platform channels + C++

Only if callback-heavy APIs are ever needed (e.g. shell notifications). Avoid otherwise.

## Tier 3 — Rust helper (sidecar exe)

For the hard parts: **VSS (Volume Shadow Copy)** for locked files, ACL preservation, long-path robustness. Rust over C++ because this code eventually runs elevated and touches user files — memory safety matters — and Rust cross-compiles cleanly in CI.

## Elevation model

Restoring `ProgramData`/HKLM needs admin. Do **not** elevate the whole Flutter app (bad UX, large privileged surface). Instead: a small elevated sidecar exe with a `requireAdministrator` manifest, invoked per operation, communicating over stdin/stdout JSON. The helper validates all paths itself and never trusts its caller (see [10-security.md](10-security.md)).

**MVP defers all of Tier 3:** MVP backs up only user-writable locations (AppData, LocalAppData, Documents, user-chosen custom paths), so no elevation is required at all.

## Path handling rules

- Expand tokens via **Known Folders API**, never environment variables (env can lie under elevation).
- Handle long paths (`\\?\` prefix) and unicode filenames in the file layer from day 1.
- Resolve junctions/symlinks before any write (see security doc).

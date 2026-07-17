# Security

Hard requirements, not suggestions.

## #1 risk: database supply chain

A malicious db PR could add a `backup:` path-traversal (`%APPDATA%\..\..\`) or a restore rule writing into the `Startup` folder. Mitigations (defense in depth — schema **and** runtime both enforce):

- Schema forbids `..` segments and absolute paths in db entries; the runtime re-validates independently.
- Restore writes only under locations declared restorable for that specific app entry.
- Db release bundles are signed (minisign/Ed25519); the app verifies against a pinned public key.
- Human review required to merge db PRs; risk-tier flags (`safe | caution | expert`) per entry.

## Restore sandboxing

Restore is arbitrary file write by design, so:

- Every expanded target path must resolve inside allowed known-folder roots (for db entries).
- Junctions/symlinks are resolved **before** writing — no junction-escape out of the sandboxed root.
- Nothing is written without passing the staging + hash-verification pipeline.

## Custom items

User-chosen paths, so the db allowlist doesn't apply. Still enforced:

- Junction/symlink resolution before write, same as db entries.
- Absolute-path custom items (outside known folders) require explicit user confirmation of the target at restore time, and warn when the original drive/root is missing.
- Custom-item rules stored in the manifest are treated as untrusted input on load — schema-validated like db entries.

## Secrets in backups

Backups will contain tokens, cookies, saved passwords. Therefore: warn the user in the UI; encryption is a priority post-MVP feature (new package format version); nothing is ever uploaded anywhere by default.

## Elevated helper (post-MVP)

Minimal command surface; validates all paths itself; never trusts its caller. See [03-windows-native.md](03-windows-native.md).

## Registry (future)

Never blind-import `.reg` files. Parse, validate keys against the db allowlist, write via API.

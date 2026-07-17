# Extensibility & Future Plugin Architecture

## Principle

Do **not** build a plugin host in the MVP. Design the seams now so plugins become "just more implementations" later:

- Detector providers, backup pipeline steps, and package codecs are already behind interfaces ([07-engines.md](07-engines.md), [06-workflows.md](06-workflows.md)).
- Every cross-boundary payload (manifest, db bundle, IPC) is versioned JSON — nothing structural is implicit.
- UI strings never live in engines; engines return codes/data, the UI localizes. This makes i18n a later, UI-only task.

## Plugin model (post-MVP)

**Out-of-process executables speaking versioned JSON-RPC over stdio** (the LSP model).

| Model | Pros | Cons |
|---|---|---|
| Dart dynamic loading | In-process, fast | Dart AOT cannot load code at runtime — effectively impossible |
| Embedded scripting (Lua/JS) | Sandboxable | New language surface; limited to scripted logic |
| **Out-of-process JSON-RPC** (chosen) | Any language, crash isolation, permission-gateable | IPC overhead (irrelevant at this workload) |

**Why:** Dart AOT rules out dynamic loading anyway; process isolation matters for a tool touching user files; LSP proved the model scales for community ecosystems.

## Future features this architecture already accommodates

Winget integration, portable app detection, registry backup/restore (elevated sidecar, [03-windows-native.md](03-windows-native.md)), compression (new package format version), encryption (new format version), cloud sync (new storage backend behind the package writer interface), snapshot comparison (hashes already in every manifest), profile management (selection sets over the same entries).

# AppConfigShelf — Architecture Plan Index

One file per topic. Read only what your task needs. Decisions here are authoritative; change them only by editing the doc in the same PR that changes the behavior.

| File | Contents |
|---|---|
| [01-architecture.md](01-architecture.md) | Layered architecture, melos monorepo, package map, folder structure |
| [02-flutter-app.md](02-flutter-app.md) | Flutter app architecture (MVVM + Riverpod, feature-first), package choices with rationale |
| [03-windows-native.md](03-windows-native.md) | Native integration tiers (win32 FFI → platform channels → Rust sidecar), elevation model |
| [04-database.md](04-database.md) | Community database: YAML source → compiled signed JSON, schema/content versioning, entry format, db repo layout |
| [05-backup-format.md](05-backup-format.md) | `.acshelf` package spec, manifest, tokenized paths, custom items, format versioning |
| [06-workflows.md](06-workflows.md) | Backup workflow, restore workflow (complete + selective), conflict handling, undo bundle |
| [07-engines.md](07-engines.md) | Detection engine (evidence/resolver), rule engine (AST, pure eval), custom-item handling |
| [08-extensibility.md](08-extensibility.md) | Plugin architecture (future, out-of-process JSON-RPC), extension seams, i18n posture |
| [09-quality.md](09-quality.md) | Testing strategy, logging, error handling, performance |
| [10-security.md](10-security.md) | Db supply-chain defense, restore sandboxing, secrets in backups, custom-item risks |
| [11-delivery.md](11-delivery.md) | CI/CD, GitHub org/repo layout, release strategy, versioning axes |
| [12-roadmap.md](12-roadmap.md) | MVP definition, milestones M0–M5, recommended development order, technical risks |
| [13-ideas.md](13-ideas.md) | Differentiator ideas beyond MVP |

## Product summary

Backup and restore **application configurations** (not full-system backup) around a Windows reinstall. Detect installed apps → back up their config per community-db rules plus user-defined custom items → after reinstall, detect again → restore completely or selectively → later, reinstall missing apps via Winget.

Slogans: hero — "Reinstall Windows. Not your workflow." GitHub description — "Backup your apps, restore your workflow."

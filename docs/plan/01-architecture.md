# High-Level Architecture

## Layers

Strict dependency direction (UI → App → Core; never reverse):

```
┌────────────────────────────────────────────┐
│ Presentation (Flutter UI, ViewModels)      │
├────────────────────────────────────────────┤
│ Application (use cases: Scan, Backup,      │
│ Restore, DB update, orchestration)         │
├────────────────────────────────────────────┤
│ Core Domain (entities, rule engine,        │
│ detection engine — pure Dart, zero I/O)    │
├────────────────────────────────────────────┤
│ Infrastructure (win32 registry, file I/O,  │
│ archive, network, native helper)           │
└────────────────────────────────────────────┘
```

**Why:** the core domain is pure Dart, so it is testable without Windows. Registry and filesystem sit behind interfaces, so they are mockable and portable if scope ever grows beyond Windows. The detection and rule engines are the crown jewels — kept framework-free so they survive UI rewrites (10-year rule: UIs die, engines live).

## Monorepo

Melos workspace. The app depends on engine packages; packages never depend on Flutter.

```
appconfigshelf/                  (this repo)
├── apps/
│   └── shelf_app/               Flutter desktop app
│       └── lib/
│           ├── features/        feature-first UI
│           │   ├── scan/
│           │   ├── backup/
│           │   ├── restore/
│           │   ├── database/    db update UI
│           │   └── settings/
│           ├── shared/          widgets, theme, routing
│           └── main.dart
├── packages/
│   ├── shelf_core/              entities, value objects, typed failures
│   ├── shelf_rules/             rule engine (parse/evaluate db + custom entries)
│   ├── shelf_detect/            detection engine
│   ├── shelf_backup/            package format, backup/restore pipelines
│   ├── shelf_db/                database loading, updating, schema
│   └── shelf_win32/             registry, known folders, ACL, VSS wrappers
├── tools/                       scripts, codegen
├── docs/                        this plan, ADRs, format specs
└── melos.yaml
```

**Why melos monorepo:** engines evolve with the app but stay independently testable (and publishable later). One PR can touch engine + UI. Separate repos this early would add coordination pain; extract later if the plugin ecosystem demands it.

The community database lives in a **separate repo** (`appconfigshelf-db`) — see [04-database.md](04-database.md) and [11-delivery.md](11-delivery.md).

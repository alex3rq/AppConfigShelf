# Flutter App Architecture

## Pattern: feature-first + MVVM (Riverpod)

Chosen over strict per-feature Clean Architecture and over Bloc.

| Approach | Pros | Cons |
|---|---|---|
| Strict Clean (per-feature data/domain/presentation) | Maximal decoupling | Boilerplate explosion for a desktop tool; single-call use-case wrappers |
| **MVVM + Riverpod, engines in packages** (chosen) | Testable, low ceremony; domain already isolated in `packages/` | Less dogmatic layering inside the app |
| Bloc | Event-traceable | Verbose; overkill for wizard/form flows |

**Why:** Clean Architecture's real value is domain isolation, which the monorepo package split already provides. Inside the app, one ViewModel (Riverpod `Notifier`/`AsyncNotifier`) per screen is enough. Backup/restore are long-running pipelines — model them as streams of progress events, not request/response.

## Package choices

- **riverpod** — state + DI; compile-safe, testable overrides.
- **win32** + **ffi** — registry, known folders, process detection in pure Dart FFI; avoids a native build for most APIs.
- **fluent_ui** — Windows-native look. A migration tool must feel like a Windows utility; Material would undercut trust.
- **freezed** + **json_serializable** — immutable entities, manifest/db parsing.
- **drift** (SQLite) — local app state: scan history, backup catalog, saved custom items.
- **archive** — zip for MVP; zstd via FFI later.
- **file_picker**, **path**, **window_manager**, **logging**, **msix** (packaging).

Verify current versions (Context7 / pub.dev) when implementation starts.

## UI surface (MVP)

Wizard flows for backup and restore, detected-apps list, custom-items management, database-update screen, settings, progress + report screens. Details of flows: [06-workflows.md](06-workflows.md).

# AppConfigShelf

> **Reinstall Windows. Not your workflow.**

AppConfigShelf is a Flutter Desktop application for Windows that backs up and restores **application configurations** — not your whole disk — so a clean Windows reinstall doesn't cost you days of re-configuring every tool you use.

*Backup your apps, restore your workflow.*

## What it does

1. Detects installed applications.
2. Knows where each one stores its configuration (via a community-maintained database, inspired by Winapp2).
3. Lets you choose what to back up — including custom folders and files not tied to any app.
4. Creates a portable, inspectable backup package (`.acshelf`).
5. After reinstalling Windows: detects apps again, restores configurations (fully or selectively), skips what isn't installed, and (eventually) reinstalls missing apps via Winget.

## Status

**Alpha.** The full pipeline works end-to-end: detection → selective backup (including custom folders/files) → `.acshelf` package → detection-gated, selective restore with undo bundles. The [community database](https://github.com/alex3rq/AppConfigShelf-DB) ships 66 entries and publishes signed releases the app verifies and downloads. Not yet recommended for production reinstalls — no binary releases published.

The complete architecture and roadmap live in [`docs/plan/`](docs/plan/00-index.md).

## Building from source

Requires Flutter (stable) with Windows desktop support and Windows Developer Mode enabled (plugin symlinks).

```
flutter pub get
cd apps/shelf_app
flutter run -d windows
```

Engine tests (pure Dart): `cd packages/<name> && dart test` (set `FLUTTER_ROOT` when invoking plain `dart`).

## Planned highlights

- **Undo bundle** — every restore is reversible.
- **Selective restore** — restore one app, a group, or everything.
- **Custom items** — back up any folder or file, restored to its original path.
- **Dry-run everywhere** — preview exact file lists before anything happens.
- **Community database** — app entries are simple YAML files anyone can contribute.
- **Winget integration** — reinstall missing apps, then restore their configs.

## License

App: TBD, permissive (MIT or Apache-2.0). The community database will live in a separate repository under **CC-BY-SA-4.0**, since its seed data derives from [Winapp2](https://github.com/MoscaDotTo/Winapp2) (with attribution and modifications noted, as that license requires). See `docs/plan/04-database.md`.

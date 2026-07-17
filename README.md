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

**Pre-alpha — architecture and planning phase.** No releases yet.

The complete architecture and roadmap live in [`docs/plan/`](docs/plan/00-index.md).

## Planned highlights

- **Undo bundle** — every restore is reversible.
- **Selective restore** — restore one app, a group, or everything.
- **Custom items** — back up any folder or file, restored to its original path.
- **Dry-run everywhere** — preview exact file lists before anything happens.
- **Community database** — app entries are simple YAML files anyone can contribute.
- **Winget integration** — reinstall missing apps, then restore their configs.

## License

TBD (will be OSI-approved).

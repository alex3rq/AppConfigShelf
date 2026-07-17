# Differentiator Ideas

Beyond the core spec — what makes AppConfigShelf better than existing Windows migration/backup tools.

1. **Undo bundle** — no migration tool has trustworthy rollback. Lead marketing with it. (In MVP.)
2. **"Export as db draft"** — when a user backs up an unknown app via custom items, the app can generate a draft YAML db entry + prefilled GitHub PR link. Turns every user into a contributor. Biggest growth lever.
3. **Pre-reinstall checklist report** — printable/HTML summary: what's backed up, what isn't, which apps winget can reinstall (`winget export` synergy). Fills the anxiety gap the night before a wipe.
4. **Dry-run everywhere** — every operation previews its exact file list first. Trust feature.
5. **Snapshot diff (v2)** — compare two backups: "what changed in my config since March." Cheap, since every manifest already hashes everything. Nobody offers this.
6. **Risk tiers in the db** (`safe/caution/expert`) — restoring a browser profile ≠ restoring terminal settings; the UI communicates the difference. Competitors treat all data as equal.
7. **Winget bidirectional** — backup captures a `winget export` list into the package; restore offers one-click reinstall of missing apps *before* config restore. Makes the slogan literal.

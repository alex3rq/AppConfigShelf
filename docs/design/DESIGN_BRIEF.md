# AppConfigShelf — UI/UX Redesign Brief

> This document is a self-contained prompt. Give it to a designer or a design-capable AI. It contains everything needed to redesign the application without access to the codebase. Deliverable requirements are at the end — read them before starting.

---

## 1. What the product is

**AppConfigShelf** is a Windows desktop application that backs up and restores *application configurations* — not whole disks — around a Windows reinstall.

- Hero slogan: **"Reinstall Windows. Not your workflow."**
- Tagline: *"Backup your apps, restore your workflow."*

The workflow: scan the system → see which installed apps are recognized → select what to back up (plus any custom folders) → produce a single portable `.acshelf` backup file → reinstall Windows → open the backup on the fresh system → restore everything or just selected parts, with automatic undo bundles.

**Audience:** Windows users preparing a reinstall. Skews technical (developers, power users) but must remain usable by a careful non-technical person. Losing user data is the catastrophic failure mode; **trust is the product**. The UI must always make clear *what will happen before it happens* (previews, counts, warnings) and *what just happened* (reports, undo paths).

## 2. Hard constraints

- **Tech:** Flutter Desktop (Windows), rendered with the `fluent_ui` package v4.x — Microsoft Fluent Design widget set. Available widget families: `NavigationView`/`NavigationPane`, `ScaffoldPage`/`PageHeader`, `CommandBar`, `ListTile`, `Expander`, `Checkbox`, `ToggleSwitch`, `ComboBox`, `TextBox`/`InfoLabel`, `Button`/`FilledButton`/`IconButton`/`HyperlinkButton`, `ContentDialog`, `InfoBar`, `ProgressBar`/`ProgressRing`, `TreeView`, `Card`, `Flyout`/`MenuFlyout`, `TabView`, `BreadcrumbBar`, Fluent icons.
- **Windows-native feel is a product value.** Refine within Fluent Design language — do not restyle into Material, macOS, or web aesthetics.
- **Light and dark themes** both required (system-following). Current accent: teal — changeable if justified.
- Desktop app, resizable; design for **1440×900**, must degrade gracefully to ~1000×650.
- Keyboard accessibility and readable contrast (WCAG AA) expected.
- No web technologies in the final product — HTML mockups are fine as a *communication format* (see deliverables), but the design must be expressible with the widget set above.

## 3. Current structure and every capability (screen by screen)

The current UI is functional but utilitarian: four flat pages of default-styled list tiles, little hierarchy, no home/dashboard, no onboarding.

### 3.1 Shell
`NavigationView` with a compact left icon pane, 4 destinations: Applications, Backup, Restore, Database. No app header branding, no status surface.

### 3.2 Applications (scan)
- Purpose: discover installed apps, show which the database recognizes.
- Action: "Scan system" button (top command bar). Progress ring while scanning (seconds).
- Result sections:
  - **Recognized (N)** — rows: app name, entry id, version, match confidence %, optional badge `local` (user-created entry) or `customized` (user-edited official entry).
  - **Not in database yet (N)** — rows: name, publisher, version; per-row actions: **Find config…** (opens dialog, below), **Hide** (moves to Hidden).
  - **Hidden (M)** — collapsed expander: user-hidden rows (with Unhide) and system components matched by database ignore rules (label only).
- Empty state: "Run a scan to detect installed applications."
- Pain: sections are long flat lists; recognized apps aren't actionable from here (no "back this up" shortcut); no counts/summary at a glance.

### 3.3 Find config… dialog (for unknown apps)
- Shows heuristically-guessed config folder candidates with match % (100% pre-checked).
- Actions: **Save to my library** (primary — turns the unknown app into a recognized, detection-gated entry), **Edit before saving…** (opens entry editor), **Copy db-entry draft** (YAML for contributing to the community database), Close.
- Empty state: explains config may be in registry/install dir; points to custom items.

### 3.4 Backup
- Purpose: choose what to back up, produce the `.acshelf` file.
- Sections:
  - **Detected applications** — checkbox per recognized app (requires a prior scan; empty state says so).
  - **Custom items** — arbitrary user folders/files backed up and restored to original paths; add via folder picker + name dialog; list shows paths; per-row delete. Persisted across sessions.
- Action: "Back up selection" → save-file dialog → progress (per-file counter + current entry name) → **report screen**: output path, files per entry, skipped files with reasons (locked/access denied), "New backup" button.
- Pain: no size estimates before backup; no indication which apps carry risk (browser profiles with logins, SSH keys — the database has `safe/caution/expert` risk tiers, currently not displayed); custom items and apps feel disconnected; report is plain text-ish.

### 3.5 Restore
- Purpose: open an `.acshelf` package and restore all or part of it.
- Flow: "Open backup…" → package summary line (source machine, date, app version) → selection list:
  - Sections **Applications** and **Custom items**; checkbox per entry with sub-labels: file count, `app not installed` (disabled/gated), `entry not in database — restores to recorded paths` (warning), `N existing will be replaced`.
  - "Select all restorable" button; conflict-mode dropdown: *Replace existing (undo bundle kept)* vs *Keep existing, restore missing only*; "Restore N entries" button.
- Progress → **report**: restored/kept counts, per-entry failures as warning bars, prominent info bar with the **undo bundle** location ("open it like any backup to roll back").
- Pain: selection list is dense; gating/warnings are inline text fragments; undo — the killer trust feature — is buried in a post-hoc info bar.

### 3.6 Database
- Purpose: manage the app database and the user's own entries.
- Content: official database info (content version, schema version, entry count) + "Check for updates" (downloads signed updates; result InfoBar: up-to-date / updated / failed) + licensing caption.
- **My library (N)** — user-created entries and customized copies of official ones (these *override* the official db). Rows: name, id, origin label, backup paths; actions: Edit, Copy YAML draft, Delete (or Reset-to-official for overrides).
- **Official entries (114+)** — every db entry, each with an Edit button (editing creates a customized override).
- Pain: wall of rows; no search/filter (114+ entries and growing); library vs official relationship (override precedence) hard to grasp; update check status is transient.

### 3.7 Entry editor dialog
- Edits any entry: display name, detect path, backup locations (each: tokenized path + folder picker, include globs, exclude globs, optional flag). Validation errors shown inline. Paths use tokens like `%APPDATA%\App` — users pick folders, tokenization is automatic.
- Pain: cramped in a dialog; globs are power-user-hostile with zero guidance.

## 4. UX flexibility — you may restructure

You are **not** required to keep the current four-page structure. Restructure navigation, merge or split flows, add a home/dashboard, turn backup into a wizard, promote scan results into the backup flow — whatever serves the user. Two rules:

1. **Every capability listed in §3 must remain reachable** (scan, recognize/unknown/hidden lists, find-config, my-library save/edit/override/reset, custom items, selective backup, selective restore with conflict modes, undo visibility, db update check, YAML export).
2. **Flag every capability you relocate or redesign significantly** in your notes, so the implementer can trace it.

Ideas worth considering (optional, not mandates): a home screen with system status ("112 apps found, 38 recognized, last backup 3 days ago") and primary Backup/Restore calls-to-action; risk-tier chips (safe/caution/expert) on selection rows; size estimates; making undo a first-class history concept; search boxes on long lists; a two-pane master-detail for the database page.

## 5. Deliverables (what the implementer needs back)

Produce files, not prose-only answers:

1. **`DESIGN.md`** — design tokens and rules:
   - Color palette for light **and** dark (backgrounds, surfaces, accent, semantic success/warning/danger), typography scale, spacing scale, corner radii, elevation/borders.
   - Navigation model (what pages/flows exist and why).
   - Component inventory: each reusable component (e.g., app row, status chip, section header, progress panel) with its states.
   - **Per-screen acceptance notes** — short bullet lists defining "done" for each screen.
2. **Mockups — one per screen/flow step**, either:
   - PNG images at 1440×900 (at least one screen also in dark theme), or
   - Self-contained HTML/CSS prototypes (no external assets; they will be *translated* to Fluent widgets, so prefer Fluent-like structure over exotic layouts).
3. Cover at minimum: home/entry point (if you add one), scan/applications, backup selection, backup progress+report, restore selection, restore report, database/library, find-config dialog, entry editor.

Place everything under `docs/design/` in this repository (`DESIGN.md` at that root, images/HTML under `docs/design/mockups/`).

## 6. Out of scope

Registry backup UI, winget reinstall flow, cloud sync, encryption settings — future features; leave room but don't design them. Don't redesign the CLI-less installer story or the website. Don't change product naming or slogans.

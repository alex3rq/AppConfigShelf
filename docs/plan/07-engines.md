# Detection & Rule Engines

Both live in pure-Dart packages (`shelf_detect`, `shelf_rules`) with all I/O behind view interfaces.

## Detection engine

Pipeline of independent **detector providers**, each emitting evidence:

```
RegistryUninstallDetector   HKLM/HKCU Uninstall keys — primary source
MsixDetector                 MSIX/Store packages (Get-AppxPackage equivalent)
PathProbeDetector            db detect rules: known exe/dir paths
StartMenuDetector            shortcut targets — catches semi-portable installs
[future] PortableAppDetector, HeuristicScanner
```

A **resolver** merges evidence against db entries (uninstall GUID, exe path, id, name+publisher fuzzy match) and produces `DetectedApp {dbEntry?, confidence, installPath, version}`. Apps with evidence but no db entry surface as an "unknown — contribute?" list.

**Why the evidence/resolver split:** new detection sources plug in without touching matching logic; confidence scoring absorbs messy real-world data (renamed installs, per-user vs machine installs); the unknown-apps list feeds community db growth — a flywheel.

## Rule engine

Db entries and custom items compile to a rule AST evaluated by a pure engine: `(rules, FileSystemView, RegistryView) → plan`.

- **Path rules:** token expansion via Known Folders (never env vars), glob include/exclude, precedence **exclude > include**.
- **Detection rules:** OR-groups of registry/path/msix probes.
- **Condition rules** (future): version ranges, OS build gates.

**Why AST + pure eval:** rules are testable against fake filesystem fixtures; db CI validates that every entry compiles; future conditions extend the AST without rewriting evaluation.

**Why exclude-wins:** the safe default — accidentally including cache wastes gigabytes; accidentally excluding a config is data loss discovered only after the reinstall. Loud warning when an include matches nothing.

## Custom items in the engines

Custom items are **user-authored rule entries** using the exact same path-rule model as db entries — same AST, same evaluation, same tokenization. Differences:

- No detection rules; they are always "detected".
- Origin flag `source: custom` flows through to the manifest.
- The db path allowlist does not apply (user chose the paths); restore-side sandbox checks still do — see [10-security.md](10-security.md).

**Why reuse rather than a parallel mechanism:** one evaluator, one serialization, one test surface; custom items get every engine improvement for free.

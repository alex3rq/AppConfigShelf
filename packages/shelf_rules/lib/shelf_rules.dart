/// Rule engine for AppConfigShelf.
///
/// Milestone M0 scope: the database entry parser/validator — the single
/// implementation of db schema v1, reused by both the app and the database
/// repo's CI validator so the two can never drift.
/// See docs/plan/04-database.md and docs/adr/ADR-001-db-schema.md.
library;

export 'src/entry_parser.dart';
export 'src/validation.dart';

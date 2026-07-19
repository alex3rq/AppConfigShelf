import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_detect/shelf_detect.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/origin_chip.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/shelf_card.dart';
import '../../shell_index.dart';
import '../../theme/shelf_theme.dart';
import '../backup/backup_view_model.dart';
import '../database/db_providers.dart';
import 'config_finder_dialog.dart';
import 'ignored_store.dart';
import 'scan_view_model.dart';

/// The official ignore patterns from the current db bundle, compiled once.
final _ignoreMatcherProvider = FutureProvider<IgnoreMatcher>((ref) async {
  final bundle = await ref.watch(dbBundleProvider.future);
  return IgnoreMatcher(bundle.ignorePatterns);
});

class ScanPage extends ConsumerWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanProvider);
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShelfPageHeader(
            title: S.of(context).navApplications,
            subtitle: S.of(context).appsSubtitle,
            trailing: FilledButton(
              onPressed: scan.isLoading
                  ? null
                  : () => ref.read(scanProvider.notifier).scan(),
              child: Text(S.of(context).scanSystem),
            ),
          ),
          Expanded(
            child: switch (scan) {
              AsyncData(value: null) => const _EmptyState(),
              AsyncData(:final value?) => _ResultList(result: value),
              AsyncError(:final error) =>
                Center(child: Text(S.of(context).scanFailed('$error'))),
              _ => const Center(child: ProgressRing()),
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Center(
      child: Text(S.of(context).runScanPrompt,
          style: ShelfType.body.copyWith(color: p.textSecondary)),
    );
  }
}

class _ResultList extends ConsumerWidget {
  const _ResultList({required this.result});

  final ResolutionResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ShelfTokens.of(context);
    final merged = ref.watch(mergedDbProvider).valueOrNull;
    final ignoreMatcher = ref.watch(_ignoreMatcherProvider).valueOrNull;
    final hiddenNames = ref.watch(ignoredNamesProvider);

    ChipOrigin? origin(String? entryId) {
      if (entryId == null || merged == null) return null;
      if (merged.freshLocalIds.contains(entryId)) return ChipOrigin.local;
      if (merged.overriddenIds.contains(entryId)) {
        return ChipOrigin.customized;
      }
      return null; // Official entries carry no chip in the list.
    }

    // Split unknowns: visible / officially ignored / hidden by user.
    final visible = <InstallEvidence>[];
    final officialIgnored = <InstallEvidence>[];
    final userHidden = <InstallEvidence>[];
    for (final evidence in result.unknown) {
      final name = evidence.displayName;
      if (name != null && hiddenNames.contains(name)) {
        userHidden.add(evidence);
      } else if (ignoreMatcher?.isIgnored(name) ?? false) {
        officialIgnored.add(evidence);
      } else {
        visible.add(evidence);
      }
    }
    final hiddenCount = officialIgnored.length + userHidden.length;
    final found = result.detected.length + result.unknown.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          ShelfSpacing.xl, 0, ShelfSpacing.xl, ShelfSpacing.xl),
      children: [
        Wrap(
          spacing: ShelfSpacing.sm,
          children: [
            ShelfChip(label: S.of(context).chipFound(found)),
            ShelfChip(
                label: S.of(context).chipRecognized(result.detected.length),
                color: p.success),
            ShelfChip(
                label: S.of(context).chipNotInDb(visible.length),
                color: p.caution),
            ShelfChip(label: S.of(context).chipHidden(hiddenCount)),
          ],
        ),
        const SizedBox(height: ShelfSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                  S.of(context).recognizedSection(result.detected.length),
                  style: ShelfType.subtitle.copyWith(color: p.textPrimary)),
            ),
            HyperlinkButton(
              onPressed: () {
                ref.read(backupSelectionProvider.notifier).state = {
                  ...ref.read(backupSelectionProvider),
                  for (final d in result.detected)
                    if (d.entryId != null) d.entryId!,
                };
                ref.read(shellIndexProvider.notifier).state = ShellTab.backup;
              },
              child: Text(S.of(context).addAllToBackup),
            ),
          ],
        ),
        const SizedBox(height: ShelfSpacing.sm),
        ShelfCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, app) in result.detected.indexed)
                _AppRow(
                  first: i == 0,
                  name: app.displayName,
                  detail:
                      '${app.entryId}  ·  ${app.version ?? '?'}',
                  chips: [
                    if (origin(app.entryId) case final o?)
                      OriginChip(origin: o),
                  ],
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          S
                              .of(context)
                              .matchPercent((app.confidence * 100).round()),
                          style: ShelfType.caption
                              .copyWith(color: p.textSecondary)),
                      const SizedBox(width: ShelfSpacing.md),
                      HyperlinkButton(
                        onPressed: app.entryId == null
                            ? null
                            : () {
                                ref
                                    .read(backupSelectionProvider.notifier)
                                    .state = {
                                  ...ref.read(backupSelectionProvider),
                                  app.entryId!,
                                };
                                ref.read(shellIndexProvider.notifier).state =
                                    ShellTab.backup;
                              },
                        child: Text(S.of(context).addToBackup),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ShelfSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text(S.of(context).notInDbSection(visible.length),
                  style: ShelfType.subtitle.copyWith(color: p.textPrimary)),
            ),
            Text(S.of(context).teachPrompt,
                style: ShelfType.caption.copyWith(color: p.textSecondary)),
          ],
        ),
        const SizedBox(height: ShelfSpacing.sm),
        ShelfCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, evidence) in visible.indexed)
                _AppRow(
                  first: i == 0,
                  name: evidence.displayName ?? S.of(context).unnamed,
                  detail: [
                    if (evidence.publisher != null) evidence.publisher!,
                    if (evidence.version != null) evidence.version!,
                  ].join(' · '),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Button(
                        onPressed: () =>
                            showConfigFinderDialog(context, ref, evidence),
                        child: Text(S.of(context).findConfig),
                      ),
                      const SizedBox(width: ShelfSpacing.sm),
                      HyperlinkButton(
                        onPressed: evidence.displayName == null
                            ? null
                            : () => ref
                                .read(ignoredNamesProvider.notifier)
                                .hide(evidence.displayName!),
                        child: Text(S.of(context).hide),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (hiddenCount > 0) ...[
          const SizedBox(height: ShelfSpacing.xl),
          ShelfCard(
            padding: EdgeInsets.zero,
            child: Expander(
              header: Row(
                children: [
                  Text(S.of(context).hiddenSection(hiddenCount),
                      style:
                          ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
                  const SizedBox(width: ShelfSpacing.md),
                  Text(
                    S.of(context).hiddenSummary(
                        userHidden.length, officialIgnored.length),
                    style:
                        ShelfType.caption.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final evidence in userHidden)
                    _AppRow(
                      name: evidence.displayName ?? S.of(context).unnamed,
                      detail: S.of(context).hiddenByYou,
                      trailing: HyperlinkButton(
                        onPressed: () => ref
                            .read(ignoredNamesProvider.notifier)
                            .unhide(evidence.displayName!),
                        child: Text(S.of(context).unhide),
                      ),
                    ),
                  for (final evidence in officialIgnored)
                    _AppRow(
                      name: evidence.displayName ?? S.of(context).unnamed,
                      detail: S.of(context).systemComponentIgnored,
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One application row: letter avatar, name + mono detail line, chips,
/// trailing actions. Rows separate with a top stroke inside a ShelfCard.
class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.name,
    required this.detail,
    this.chips = const [],
    this.trailing,
    this.first = false,
  });

  final String name;
  final String detail;
  final List<Widget> chips;
  final Widget? trailing;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ShelfSpacing.lg, vertical: ShelfSpacing.md),
      decoration: first
          ? null
          : BoxDecoration(border: Border(top: BorderSide(color: p.stroke))),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius:
                  BorderRadius.circular(ShelfSpacing.controlRadius),
            ),
            child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                style: ShelfType.caption
                    .copyWith(color: p.textSecondary)),
          ),
          const SizedBox(width: ShelfSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style:
                        ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(detail,
                      style:
                          ShelfType.mono.copyWith(color: p.textSecondary)),
                ],
              ],
            ),
          ),
          for (final chip in chips) ...[
            chip,
            const SizedBox(width: ShelfSpacing.sm),
          ],
          ?trailing,
        ],
      ),
    );
  }
}

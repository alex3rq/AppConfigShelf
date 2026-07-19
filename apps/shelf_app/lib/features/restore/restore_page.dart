import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_backup/shelf_backup.dart';
import 'package:shelf_core/shelf_core.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/footer_action_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/shelf_card.dart';
import '../../shared/widgets/wizard_steps.dart';
import '../../shell_index.dart';
import '../../theme/shelf_theme.dart';
import 'restore_view_model.dart';

class RestorePage extends ConsumerStatefulWidget {
  const RestorePage({super.key});

  @override
  ConsumerState<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends ConsumerState<RestorePage> {
  ConflictMode _conflictMode = ConflictMode.overwrite;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restoreProvider);
    final step = switch (state) {
      RestoreIdle() || RestoreLoadFailed() => 0,
      RestoreSelecting() => 1,
      RestoreRunning() || RestoreComplete() => 2,
    };
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShelfPageHeader(
            title: S.of(context).navRestore,
            subtitle: S.of(context).restoreSubtitle,
            trailing: WizardSteps(
              labels: [
                S.of(context).stepOpen,
                S.of(context).stepSelect,
                S.of(context).stepDone,
              ],
              current: step,
            ),
          ),
          Expanded(
            child: switch (state) {
              RestoreIdle() => _Idle(onOpen: _openPackage),
              RestoreLoadFailed(:final message) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(message),
                    const SizedBox(height: ShelfSpacing.sm),
                    Button(
                        onPressed: () =>
                            ref.read(restoreProvider.notifier).reset(),
                        child: Text(S.of(context).back)),
                  ]),
                ),
              RestoreSelecting() => _Selection(
                  state: state,
                  conflictMode: _conflictMode,
                  onConflictModeChanged: (m) =>
                      setState(() => _conflictMode = m),
                  onChooseAnother: _openPackage,
                ),
              RestoreRunning(:final currentEntry, :final filesDone) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const ProgressRing(),
                    const SizedBox(height: ShelfSpacing.md),
                    Text(S
                        .of(context)
                        .restoreProgress(currentEntry, filesDone)),
                  ]),
                ),
              RestoreComplete() => _Report(state: state),
            },
          ),
          if (state case RestoreSelecting(:final selected, :final plan))
            FooterActionBar(
              summary: _SelectionSummary(
                  selected: selected, plan: plan),
              action: FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => ref
                        .read(restoreProvider.notifier)
                        .run(conflictMode: _conflictMode),
                child: Text(S.of(context).restoreEntries(selected.length)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openPackage() async {
    final file = await fs.openFile(acceptedTypeGroups: const [
      fs.XTypeGroup(label: 'AppConfigShelf backup', extensions: ['acshelf']),
    ]);
    if (file == null) return;
    await ref.read(restoreProvider.notifier).openPackage(file.path);
  }
}

class _Idle extends StatelessWidget {
  const _Idle({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.of(context).restoreOpenPrompt,
              style: ShelfType.body.copyWith(color: p.textSecondary)),
          const SizedBox(height: ShelfSpacing.md),
          FilledButton(
              onPressed: onOpen, child: Text(S.of(context).openBackupAction)),
        ],
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({required this.selected, required this.plan});

  final Set<String> selected;
  final RestorePlan plan;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    final conflicts = plan.candidates
        .where((c) => selected.contains(c.entry.id))
        .fold(0, (sum, c) => sum + c.conflictCount);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).selectionSummary(
                  selected.length, plan.candidates.length) +
              (conflicts > 0
                  ? S.of(context).selectionConflicts(conflicts)
                  : ''),
          style: ShelfType.bodyStrong.copyWith(color: p.textPrimary),
        ),
        Text(S.of(context).undoNotice,
            style: ShelfType.caption.copyWith(color: p.accent)),
      ],
    );
  }
}

class _Selection extends ConsumerWidget {
  const _Selection({
    required this.state,
    required this.conflictMode,
    required this.onConflictModeChanged,
    required this.onChooseAnother,
  });

  final RestoreSelecting state;
  final ConflictMode conflictMode;
  final ValueChanged<ConflictMode> onConflictModeChanged;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ShelfTokens.of(context);
    final manifest = state.package.manifest;
    final apps = [
      for (final c in state.plan.candidates)
        if (c.entry.source == EntrySource.database) c
    ];
    final customs = [
      for (final c in state.plan.candidates)
        if (c.entry.source == EntrySource.custom) c
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          ShelfSpacing.xl, 0, ShelfSpacing.xl, ShelfSpacing.xl),
      children: [
        ShelfCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.package.path.split(RegExp(r'[\\/]')).last,
                        style:
                            ShelfType.mono.copyWith(color: p.textPrimary)),
                    const SizedBox(height: ShelfSpacing.xs),
                    Text(
                      S.of(context).packageInfo(
                          manifest.machine.hostname,
                          manifest.createdAt
                              .toLocal()
                              .toString()
                              .substring(0, 16),
                          manifest.appVersion,
                          state.plan.candidates.length),
                      style: ShelfType.caption
                          .copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              HyperlinkButton(
                onPressed: onChooseAnother,
                child: Text(S.of(context).chooseAnotherFile),
              ),
            ],
          ),
        ),
        const SizedBox(height: ShelfSpacing.lg),
        Text(S.of(context).conflictQuestion,
            style: ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
        const SizedBox(height: ShelfSpacing.sm),
        IntrinsicHeight(
            child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ConflictCard(
                selected: conflictMode == ConflictMode.overwrite,
                title: S.of(context).replaceExisting,
                body: S.of(context).replaceExistingBody,
                onPressed: () =>
                    onConflictModeChanged(ConflictMode.overwrite),
              ),
            ),
            const SizedBox(width: ShelfSpacing.lg),
            Expanded(
              child: _ConflictCard(
                selected: conflictMode == ConflictMode.skipExisting,
                title: S.of(context).keepExisting,
                body: S.of(context).keepExistingBody,
                onPressed: () =>
                    onConflictModeChanged(ConflictMode.skipExisting),
              ),
            ),
          ],
        )),
        const SizedBox(height: ShelfSpacing.lg),
        if (apps.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(S.of(context).applicationsSection,
                    style:
                        ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
              ),
              HyperlinkButton(
                onPressed: () =>
                    ref.read(restoreProvider.notifier).selectAllRestorable(),
                child: Text(S.of(context).selectAllRestorable),
              ),
            ],
          ),
          const SizedBox(height: ShelfSpacing.sm),
          _CandidateCard(candidates: apps, state: state),
          const SizedBox(height: ShelfSpacing.lg),
        ],
        if (customs.isNotEmpty) ...[
          Text(S.of(context).customItemsTitle,
              style: ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
          const SizedBox(height: ShelfSpacing.sm),
          _CandidateCard(candidates: customs, state: state),
        ],
      ],
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.selected,
    required this.title,
    required this.body,
    required this.onPressed,
  });

  final bool selected;
  final String title;
  final String body;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return ShelfCard(
      tinted: selected,
      onPressed: onPressed,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            selected
                ? FluentIcons.radio_btn_on
                : FluentIcons.radio_btn_off,
            size: 16,
            color: selected ? p.accent : p.textSecondary,
          ),
          const SizedBox(width: ShelfSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
                const SizedBox(height: ShelfSpacing.xs),
                Text(body,
                    style:
                        ShelfType.caption.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends ConsumerWidget {
  const _CandidateCard({required this.candidates, required this.state});

  final List<RestoreCandidate> candidates;
  final RestoreSelecting state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ShelfTokens.of(context);
    return ShelfCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, c) in candidates.indexed)
            Builder(builder: (context) {
              final gated = c.status == RestoreStatus.appMissing;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: ShelfSpacing.lg, vertical: ShelfSpacing.md),
                decoration: i == 0
                    ? null
                    : BoxDecoration(
                        border: Border(top: BorderSide(color: p.stroke))),
                child: Row(
                  children: [
                    Checkbox(
                      checked: state.selected.contains(c.entry.id),
                      onChanged: gated
                          ? null
                          : (v) => ref
                              .read(restoreProvider.notifier)
                              .toggle(c.entry.id, v!),
                    ),
                    const SizedBox(width: ShelfSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.entry.name,
                              style: ShelfType.bodyStrong.copyWith(
                                  color: gated
                                      ? p.textSecondary
                                      : p.textPrimary)),
                          const SizedBox(height: 2),
                          Text(S.of(context).nFiles(c.entry.files.length),
                              style: ShelfType.mono
                                  .copyWith(color: p.textSecondary)),
                        ],
                      ),
                    ),
                    if (gated)
                      ShelfChip(label: S.of(context).appNotInstalled)
                    else if (c.unknownEntry)
                      ShelfChip(
                          label: S.of(context).notInDbRestores,
                          color: p.caution)
                    else if (c.conflictCount > 0)
                      Text(
                          S.of(context).existingReplaced(c.conflictCount),
                          style: ShelfType.caption
                              .copyWith(color: p.textSecondary)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _Report extends ConsumerWidget {
  const _Report({required this.state});

  final RestoreComplete state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ShelfTokens.of(context);
    final f = state.finished;
    final clean = f.failedEntries.isEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          ShelfSpacing.xl, 0, ShelfSpacing.xl, ShelfSpacing.xl),
      children: [
        const SizedBox(height: ShelfSpacing.lg),
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (clean ? p.success : p.caution).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(clean ? FluentIcons.check_mark : FluentIcons.warning,
                size: 24, color: clean ? p.success : p.caution),
          ),
        ),
        const SizedBox(height: ShelfSpacing.md),
        Center(
          child: Text(
              clean
                  ? S.of(context).restoreComplete
                  : S.of(context).restoreProblems,
              style: ShelfType.title.copyWith(color: p.textPrimary)),
        ),
        const SizedBox(height: ShelfSpacing.xs),
        Center(
          child: Text(
              S.of(context).restoredStats(f.restoredFiles) +
                  (f.skippedFiles > 0
                      ? S.of(context).keptNewer(f.skippedFiles)
                      : ''),
              style: ShelfType.caption.copyWith(color: p.textSecondary)),
        ),
        if (f.undoPath case final undoPath?) ...[
          const SizedBox(height: ShelfSpacing.lg),
          ShelfCard(
            tinted: true,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).undoSavedTitle,
                          style: ShelfType.bodyStrong
                              .copyWith(color: p.textPrimary)),
                      const SizedBox(height: ShelfSpacing.xs),
                      Text(undoPath,
                          style:
                              ShelfType.mono.copyWith(color: p.textSecondary)),
                      const SizedBox(height: ShelfSpacing.xs),
                      Text(S.of(context).undoSavedBody,
                          style: ShelfType.caption
                              .copyWith(color: p.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: ShelfSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Button(
                      onPressed: () async {
                        ref.read(restoreProvider.notifier).reset();
                        await ref
                            .read(restoreProvider.notifier)
                            .openPackage(undoPath);
                      },
                      child: Text(S.of(context).rollBackNow),
                    ),
                    const SizedBox(height: ShelfSpacing.xs),
                    HyperlinkButton(
                      onPressed: () =>
                          Process.run('explorer.exe', ['/select,', undoPath]),
                      child: Text(S.of(context).showInFolder),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (state.entryFailures.isNotEmpty) ...[
          const SizedBox(height: ShelfSpacing.lg),
          ShelfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final failure in state.entryFailures) ...[
                  Text(S.of(context).entryHalted(failure.entryId),
                      style: ShelfType.bodyStrong.copyWith(color: p.caution)),
                  const SizedBox(height: 2),
                  Text(failure.reason,
                      style: ShelfType.mono.copyWith(color: p.caution)),
                  const SizedBox(height: ShelfSpacing.sm),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: ShelfSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () {
                ref.read(restoreProvider.notifier).reset();
                ref.read(shellIndexProvider.notifier).state = ShellTab.home;
              },
              child: Text(S.of(context).done),
            ),
            const SizedBox(width: ShelfSpacing.sm),
            Button(
              onPressed: () => ref.read(restoreProvider.notifier).reset(),
              child: Text(S.of(context).openAnotherBackup),
            ),
          ],
        ),
      ],
    );
  }
}

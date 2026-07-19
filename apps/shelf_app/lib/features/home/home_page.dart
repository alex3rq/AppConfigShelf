import 'package:file_selector/file_selector.dart' as fs;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_detect/shelf_detect.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/shelf_card.dart';
import '../../shell_index.dart';
import '../../theme/shelf_theme.dart';
import '../restore/restore_view_model.dart';
import '../scan/scan_view_model.dart';
import 'history_store.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanProvider);
    final result = scan.valueOrNull;
    final history = ref.watch(historyProvider);

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: ListView(
        children: [
          ShelfPageHeader(
            title: S.of(context).navHome,
            subtitle: S.of(context).homeSlogan,
            trailing: Button(
              onPressed: scan.isLoading
                  ? null
                  : () => ref.read(scanProvider.notifier).scan(),
              child: Text(result == null
                  ? S.of(context).scanThisPc
                  : S.of(context).scanAgain),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: ShelfSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatRow(result: result, loading: scan.isLoading),
                const SizedBox(height: ShelfSpacing.lg),
                IntrinsicHeight(
                    child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ActionCard(
                        tinted: true,
                        icon: FluentIcons.save,
                        title: S.of(context).backupCardTitle,
                        body: S.of(context).backupCardBody,
                        buttonLabel: S.of(context).startBackup,
                        filled: true,
                        onPressed: () => ref
                            .read(shellIndexProvider.notifier)
                            .state = ShellTab.backup,
                      ),
                    ),
                    const SizedBox(width: ShelfSpacing.lg),
                    Expanded(
                      child: _ActionCard(
                        icon: FluentIcons.history,
                        title: S.of(context).restoreCardTitle,
                        body: S.of(context).restoreCardBody,
                        buttonLabel: S.of(context).openBackupAction,
                        onPressed: () => _openBackupFile(ref),
                      ),
                    ),
                  ],
                )),
                const SizedBox(height: ShelfSpacing.lg),
                _SafetyTimeline(history: history),
                const SizedBox(height: ShelfSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openBackupFile(WidgetRef ref) async {
  final file = await fs.openFile(acceptedTypeGroups: const [
    fs.XTypeGroup(label: 'AppConfigShelf backup', extensions: ['acshelf']),
  ]);
  if (file == null) return;
  ref.read(shellIndexProvider.notifier).state = ShellTab.restore;
  await ref.read(restoreProvider.notifier).openPackage(file.path);
}

class _StatRow extends ConsumerWidget {
  const _StatRow({required this.result, required this.loading});

  final ResolutionResult? result;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ShelfTokens.of(context);
    final r = result;

    Widget stat(String value, String label, String linkLabel, int tab,
        {Color? valueColor}) {
      return Expanded(
        child: ShelfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: ShelfType.display
                      .copyWith(color: valueColor ?? p.textPrimary)),
              const SizedBox(height: ShelfSpacing.xs),
              Text(label,
                  style:
                      ShelfType.caption.copyWith(color: p.textSecondary)),
              const SizedBox(height: ShelfSpacing.sm),
              HyperlinkButton(
                onPressed: () =>
                    ref.read(shellIndexProvider.notifier).state = tab,
                child: Text(linkLabel, style: ShelfType.caption),
              ),
            ],
          ),
        ),
      );
    }

    if (r == null) {
      return ShelfCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                loading
                    ? S.of(context).homeScanning
                    : S.of(context).homeScanPrompt,
                style: ShelfType.body.copyWith(color: p.textSecondary),
              ),
            ),
            if (loading) const ProgressRing(),
          ],
        ),
      );
    }

    return IntrinsicHeight(
        child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        stat('${r.detected.length + r.unknown.length}',
            S.of(context).statAppsFound, S.of(context).viewApplications,
            ShellTab.applications),
        const SizedBox(width: ShelfSpacing.lg),
        stat('${r.detected.length}', S.of(context).statRecognized,
            S.of(context).readyToBackUp, ShellTab.backup),
        const SizedBox(width: ShelfSpacing.lg),
        stat('${r.unknown.length}', S.of(context).statUnknown,
            S.of(context).review, ShellTab.applications,
            valueColor: p.caution),
      ],
    ));
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
    this.tinted = false,
    this.filled = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool tinted;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = ShelfTokens.of(context);
    return ShelfCard(
      tinted: tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tinted
                      ? p.accent.withValues(alpha: 0.2)
                      : p.card,
                  borderRadius:
                      BorderRadius.circular(ShelfSpacing.controlRadius),
                ),
                child: Icon(icon,
                    size: 16, color: tinted ? p.accent : p.textSecondary),
              ),
              const SizedBox(width: ShelfSpacing.md),
              Text(title,
                  style:
                      ShelfType.subtitle.copyWith(color: p.textPrimary)),
            ],
          ),
          const SizedBox(height: ShelfSpacing.md),
          Text(body,
              style: ShelfType.caption.copyWith(color: p.textSecondary)),
          const SizedBox(height: ShelfSpacing.md),
          filled
              ? FilledButton(onPressed: onPressed, child: Text(buttonLabel))
              : Button(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}

class _SafetyTimeline extends ConsumerWidget {
  const _SafetyTimeline({required this.history});

  final List<HistoryEvent> history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ShelfTokens.of(context);
    return ShelfCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(ShelfSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).timelineTitle,
                          style: ShelfType.subtitle
                              .copyWith(color: p.textPrimary)),
                      const SizedBox(height: ShelfSpacing.xs),
                      Text(
                        S.of(context).timelineSubtitle,
                        style: ShelfType.caption
                            .copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                HyperlinkButton(
                  onPressed: () => _openBackupFile(ref),
                  child: Text(S.of(context).openAFile),
                ),
              ],
            ),
          ),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  ShelfSpacing.lg, 0, ShelfSpacing.lg, ShelfSpacing.lg),
              child: Text(S.of(context).timelineEmpty,
                  style: ShelfType.caption.copyWith(color: p.textSecondary)),
            ),
          for (final event in history.take(8)) _TimelineRow(event: event),
        ],
      ),
    );
  }
}

class _TimelineRow extends ConsumerWidget {
  const _TimelineRow({required this.event});

  final HistoryEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ShelfTokens.of(context);
    final title = switch (event.kind) {
      HistoryKind.backup => S.of(context).timelineBackupCreated,
      HistoryKind.undoBundle => S.of(context).timelineUndoKept,
    };
    final fileName = event.path.split(RegExp(r'[\\/]')).last;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ShelfSpacing.lg, vertical: ShelfSpacing.md),
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: p.stroke))),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: p.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: ShelfSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        ShelfType.bodyStrong.copyWith(color: p.textPrimary)),
                const SizedBox(height: 2),
                Text('$fileName · ${event.summary}',
                    style: ShelfType.mono.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
          Text(_relative(context, event.timestamp),
              style: ShelfType.caption.copyWith(color: p.textSecondary)),
          const SizedBox(width: ShelfSpacing.md),
          HyperlinkButton(
            onPressed: () async {
              ref.read(shellIndexProvider.notifier).state = ShellTab.restore;
              await ref
                  .read(restoreProvider.notifier)
                  .openPackage(event.path);
            },
            child: Text(event.kind == HistoryKind.backup
                ? S.of(context).open
                : S.of(context).rollBack),
          ),
        ],
      ),
    );
  }

  String _relative(BuildContext context, DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays < 1) return S.of(context).relativeToday;
    if (diff.inDays == 1) return S.of(context).relativeYesterday;
    if (diff.inDays < 8) return S.of(context).relativeDaysAgo(diff.inDays);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[t.month - 1]} ${t.day}';
  }
}

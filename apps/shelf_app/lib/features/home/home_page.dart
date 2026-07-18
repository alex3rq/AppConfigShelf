import 'package:file_selector/file_selector.dart' as fs;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_detect/shelf_detect.dart';

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
            title: 'Home',
            subtitle: 'Reinstall Windows. Not your workflow.',
            trailing: Button(
              onPressed: scan.isLoading
                  ? null
                  : () => ref.read(scanProvider.notifier).scan(),
              child: Text(result == null ? 'Scan this PC' : 'Scan again'),
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
                        title: 'Back up this PC',
                        body:
                            'Pick the apps and folders that matter, get one '
                            'portable .acshelf file you can carry through a '
                            'reinstall.',
                        buttonLabel: 'Start backup',
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
                        title: 'Restore a backup',
                        body:
                            'Open an .acshelf file from this or another '
                            'machine and bring everything back — all of it, '
                            'or just the parts you choose.',
                        buttonLabel: 'Open backup…',
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
                    ? 'Scanning this PC…'
                    : 'Scan this PC to see which of your installed apps '
                        'AppConfigShelf can back up.',
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
        stat('${r.detected.length + r.unknown.length}', 'apps found on this PC',
            'View applications', ShellTab.applications),
        const SizedBox(width: ShelfSpacing.lg),
        stat('${r.detected.length}', 'recognized by the database',
            'Ready to back up', ShellTab.backup),
        const SizedBox(width: ShelfSpacing.lg),
        stat('${r.unknown.length}', 'unknown apps worth a look', 'Review',
            ShellTab.applications,
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
                      Text('Safety timeline',
                          style: ShelfType.subtitle
                              .copyWith(color: p.textPrimary)),
                      const SizedBox(height: ShelfSpacing.xs),
                      Text(
                        'Every backup and undo bundle this PC has produced '
                        '— open any of them like a backup.',
                        style: ShelfType.caption
                            .copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                HyperlinkButton(
                  onPressed: () => _openBackupFile(ref),
                  child: const Text('Open a file…'),
                ),
              ],
            ),
          ),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  ShelfSpacing.lg, 0, ShelfSpacing.lg, ShelfSpacing.lg),
              child: Text('Nothing yet — your first backup will show here.',
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
      HistoryKind.backup => 'Backup created',
      HistoryKind.undoBundle => 'Undo bundle kept',
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
          Text(_relative(event.timestamp),
              style: ShelfType.caption.copyWith(color: p.textSecondary)),
          const SizedBox(width: ShelfSpacing.md),
          HyperlinkButton(
            onPressed: () async {
              ref.read(shellIndexProvider.notifier).state = ShellTab.restore;
              await ref
                  .read(restoreProvider.notifier)
                  .openPackage(event.path);
            },
            child: Text(
                event.kind == HistoryKind.backup ? 'Open' : 'Roll back'),
          ),
        ],
      ),
    );
  }

  String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays < 1) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 8) return '${diff.inDays} days ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[t.month - 1]} ${t.day}';
  }
}

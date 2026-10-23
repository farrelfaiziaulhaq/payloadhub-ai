import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/activity_entry.dart';
import 'history_controller.dart';
import 'history_providers.dart';

/// Formats a timestamp as `dd/MM/yyyy HH:mm` without pulling in `intl`.
String formatActivityTime(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

IconData iconForActivity(ActivityKind kind) {
  switch (kind) {
    case ActivityKind.payload:
      return Icons.terminal;
    case ActivityKind.exploit:
      return Icons.bug_report_outlined;
    case ActivityKind.scan:
      return Icons.radar;
    case ActivityKind.threat:
      return Icons.shield_outlined;
    case ActivityKind.chat:
      return Icons.chat_bubble_outline;
  }
}

Color colorForActivity(ActivityKind kind) {
  switch (kind) {
    case ActivityKind.payload:
      return AppColors.accent;
    case ActivityKind.exploit:
      return AppColors.warning;
    case ActivityKind.scan:
      return AppColors.info;
    case ActivityKind.threat:
      return AppColors.danger;
    case ActivityKind.chat:
      return AppColors.accentDim;
  }
}

/// Full-screen history browser, opened from the top bar, the sidebar and the
/// dashboard activity panel.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final controller = ref.read(historyProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Riwayat Aktivitas'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: history.loading ? null : controller.reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Hapus semua riwayat',
            onPressed: history.entries.isEmpty
                ? null
                : () => _confirmClear(context, controller.clear),
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _HistoryBody(history: history),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    Future<void> Function() clear,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Hapus semua riwayat?'),
        content: const Text(
          'Seluruh catatan payload, exploit, scan, dan chat lokal akan dihapus. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat lokal sudah dihapus')),
      );
    }
  }
}

class _HistoryBody extends ConsumerWidget {
  const _HistoryBody({required this.history});

  final HistoryState history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (history.error != null && history.entries.isEmpty) {
      return _EmptyState(
        icon: Icons.error_outline,
        title: 'Riwayat tidak dapat dibaca',
        message: history.error!,
        actionLabel: 'Coba lagi',
        onAction: ref.read(historyProvider.notifier).reload,
      );
    }
    if (history.entries.isEmpty) {
      return const _EmptyState(
        icon: Icons.history,
        title: 'Belum ada aktivitas',
        message:
            'Payload yang Anda buat di Script Generator akan tercatat di sini '
            'secara lokal dan terenkripsi.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      itemCount: history.entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = history.entries[index];
        return Dismissible(
          key: ValueKey<String>(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            ref.read(historyProvider.notifier).remove(entry.id);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Entri riwayat dihapus')),
              );
          },
          child: _HistoryTile(
            entry: entry,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.card,
              showDragHandle: true,
              builder: (context) => _HistoryDetailSheet(entry: entry),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.onTap});

  final ActivityEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorForActivity(entry.kind);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(iconForActivity(entry.kind), color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.detail.replaceAll('\n', ' '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _KindBadge(label: entry.kind.label, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formatActivityTime(entry.createdAt),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.6),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HistoryDetailSheet extends StatelessWidget {
  const _HistoryDetailSheet({required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = colorForActivity(entry.kind);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(iconForActivity(entry.kind), color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.kind.label} · ${formatActivityTime(entry.createdAt)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  entry.detail,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: entry.detail));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Disalin ke clipboard')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Salin'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF0D1117),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

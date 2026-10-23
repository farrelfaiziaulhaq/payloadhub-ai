import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../history/domain/activity_entry.dart';
import '../../../history/presentation/history_providers.dart';
import '../../../history/presentation/history_screen.dart';
import 'panel_card.dart';

/// Dashboard card that surfaces the newest locally persisted activities and
/// links to the full [HistoryScreen].
class ActivityHistoryPanel extends ConsumerWidget {
  const ActivityHistoryPanel({super.key});

  static const int _previewCount = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final preview = history.entries.take(_previewCount).toList(growable: false);

    return PanelCard(
      title: 'Aktivitas Terbaru',
      subtitle: 'Tersimpan lokal & terenkripsi di perangkat ini',
      trailing: [
        TextButton(
          onPressed: () => openHistory(context),
          child: const Text(
            'Lihat semua',
            style: TextStyle(color: AppColors.accent, fontSize: 12),
          ),
        ),
      ],
      body: history.loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            )
          : preview.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Belum ada aktivitas. Buat payload pertama Anda di '
                    'Script Generator — hasilnya akan muncul di sini.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < preview.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 12, color: AppColors.border),
                      _ActivityRow(
                        entry: preview[i],
                        onTap: () => openHistory(context),
                      ),
                    ],
                  ],
                ),
    );
  }
}

/// Opens the history route. Used by the dashboard panel and the top bar.
void openHistory(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry, required this.onTap});

  final ActivityEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorForActivity(entry.kind);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Icon(iconForActivity(entry.kind), color: color, size: 15),
            const SizedBox(width: 8),
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
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatActivityTime(entry.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

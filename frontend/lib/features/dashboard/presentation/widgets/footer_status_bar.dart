import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../dashboard_providers.dart';

/// Bottom status strip: real-time status badge (left) + network/uptime (right).
class FooterStatusBar extends ConsumerWidget {
  const FooterStatusBar({super.key});

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.bgElevated,
      child: Row(
        children: [
          const Text(
            'Real-time status',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'In Android',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
          const Spacer(),
          const Icon(Icons.wifi, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Network connection: ${telemetry.networkPercent.toStringAsFixed(0)}%'
              ' (${telemetry.networkConnections})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Uptime: ${_fmt(telemetry.uptime)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

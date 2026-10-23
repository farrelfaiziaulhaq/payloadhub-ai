import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Compact, app-like header used on phones instead of the dashboard top bar.
///
/// It keeps the product identity visible, exposes the two most used global
/// actions directly (history + overflow menu) and never tries to imitate a
/// desktop toolbar.
class MobileAppHeader extends StatelessWidget {
  const MobileAppHeader({
    super.key,
    required this.title,
    this.onHistory,
    this.onExport,
    this.onAbout,
    this.historyCount = 0,
  });

  final String title;
  final VoidCallback? onHistory;
  final VoidCallback? onExport;
  final VoidCallback? onAbout;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, AppColors.accentDim],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF0D1117),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PayloadHub-AI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.history,
            tooltip: 'Riwayat aktivitas',
            badge: historyCount > 0 ? '$historyCount' : null,
            onTap: onHistory,
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu lainnya',
            color: AppColors.cardAlt,
            icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
            onSelected: (value) {
              if (value == 'export') onExport?.call();
              if (value == 'about') onAbout?.call();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.save_outlined,
                        size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Ekspor riwayat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Tentang aplikasi'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 21),
              if (badge != null)
                Positioned(
                  top: 6,
                  right: 5,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.bgElevated, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Color(0xFF0D1117),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

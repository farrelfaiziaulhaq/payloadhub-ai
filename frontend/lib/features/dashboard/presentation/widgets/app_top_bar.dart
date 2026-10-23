import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Top bar of the main canvas: page title + working global actions
/// (local history, export history, about/authorization notice).
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    this.title = 'Dashboard',
    this.onHistory,
    this.onExport,
    this.onAbout,
  });

  final String title;
  final VoidCallback? onHistory;
  final VoidCallback? onExport;
  final VoidCallback? onAbout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.bgElevated,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.history,
            tooltip: 'Riwayat aktivitas',
            onTap: onHistory,
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.save_outlined,
            tooltip: 'Ekspor riwayat ke clipboard',
            onTap: onExport,
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.person_outline,
            tooltip: 'Tentang aplikasi',
            onTap: onAbout,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.card,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
        ),
      ),
    );
  }
}

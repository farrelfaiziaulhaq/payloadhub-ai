import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A bordered dashboard card with an optional header row (title + trailing).
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.body,
    this.padding = const EdgeInsets.all(14),
  });

  final String title;
  final String? subtitle;
  final List<Widget>? trailing;
  final Widget? body;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) ...trailing!,
              ],
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          if (body != null)
            Padding(padding: padding, child: body!),
        ],
      ),
    );
  }
}

/// A small circular icon button used in panel headers.
class PanelIconButton extends StatelessWidget {
  const PanelIconButton({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap ?? () {},
      icon: Icon(icon, color: AppColors.textSecondary, size: 16),
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

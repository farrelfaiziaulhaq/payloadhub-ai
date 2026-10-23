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
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(compact ? 18 : 10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding:
                EdgeInsets.fromLTRB(compact ? 16 : 14, compact ? 15 : 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: compact ? 16 : 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) ...trailing!,
              ],
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: EdgeInsets.fromLTRB(compact ? 16 : 14, 0, 14, 6),
              child: Text(
                subtitle!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: compact ? 12.5 : 12,
                ),
              ),
            ),
          if (body != null)
            Padding(
              padding: compact
                  ? EdgeInsets.fromLTRB(
                      padding.resolve(Directionality.of(context)).left,
                      4,
                      padding.resolve(Directionality.of(context)).right,
                      16,
                    )
                  : padding,
              child: body!,
            ),
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

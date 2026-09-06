import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Top bar of the main canvas: page title + global action buttons.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, this.title = 'Dashboard'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: AppColors.bgElevated,
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          const _RoundIconButton(icon: Icons.save_outlined),
          const SizedBox(width: 8),
          const _RoundIconButton(icon: Icons.notifications_outlined),
          const SizedBox(width: 8),
          const _RoundIconButton(icon: Icons.person_outline),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.textSecondary, size: 18),
    );
  }
}

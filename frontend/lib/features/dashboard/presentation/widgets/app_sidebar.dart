import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/navigation_controller.dart';
import 'history_panel.dart';

/// Left navigation sidebar with brand identity and an interactive vertical
/// menu that drives the main canvas via [NavigationController].
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  static const double width = 228;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(navControllerProvider);
    final nav = ref.read(navControllerProvider.notifier);

    return Container(
      width: width,
      color: AppColors.bgElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          const _BrandHeader(),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  selected: current == AppPage.dashboard,
                  onTap: () => nav.select(AppPage.dashboard),
                ),
                _SidebarItem(
                  icon: Icons.folder_copy_outlined,
                  label: 'Exploit Library',
                  selected: current == AppPage.exploits,
                  onTap: () => nav.select(AppPage.exploits),
                ),
                _SidebarItem(
                  icon: Icons.code,
                  label: 'Script Generator',
                  selected: current == AppPage.generator,
                  onTap: () => nav.select(AppPage.generator),
                ),
                _SidebarItem(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Monitoring',
                  selected: current == AppPage.monitoring,
                  onTap: () => nav.select(AppPage.monitoring),
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  selected: current == AppPage.settings,
                  onTap: () => nav.select(AppPage.settings),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _SidebarItem(
                  icon: Icons.history,
                  label: 'Riwayat Aktivitas',
                  selected: false,
                  onTap: () => openHistory(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent, width: 1.4),
            ),
            child:
                const Icon(Icons.view_in_ar, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'PayloadHub-AI',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

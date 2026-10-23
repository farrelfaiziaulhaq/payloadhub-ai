import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../history/presentation/history_providers.dart';
import 'controllers/navigation_controller.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/app_top_bar.dart';
import 'widgets/exploit_library_page.dart';
import 'widgets/floating_chatbot.dart';
import 'widgets/footer_status_bar.dart';
import 'widgets/history_panel.dart';
import 'widgets/mobile_app_header.dart';
import 'widgets/monitoring_page.dart';
import 'widgets/monitoring_panel.dart';
import 'widgets/nmap_scans_panel.dart';
import 'widgets/payload_library_panel.dart';
import 'widgets/script_generator_page.dart';
import 'widgets/settings_page.dart';
import 'widgets/studio_config_panel.dart';
import 'widgets/threat_intel_panel.dart';

/// The PayloadHub-AI shell: sidebar (wide screens) or bottom navigation
/// (phones), a main canvas that switches between pages via [IndexedStack], and
/// a floating Info Bot.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _titleOf(AppPage page) {
    switch (page) {
      case AppPage.dashboard:
        return 'Dashboard';
      case AppPage.exploits:
        return 'Exploit Library';
      case AppPage.generator:
        return 'Script Generator';
      case AppPage.monitoring:
        return 'Monitoring';
      case AppPage.settings:
        return 'Settings';
    }
  }

  Future<void> _exportHistory(BuildContext context, WidgetRef ref) async {
    final entries = ref.read(historyProvider).entries;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat masih kosong')),
      );
      return;
    }
    final payload = const JsonEncoder.withIndent('  ').convert(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );
    await Clipboard.setData(ClipboardData(text: payload));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('${entries.length} entri riwayat disalin ke clipboard')),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'PayloadHub-AI',
      applicationVersion: '1.0.0 (MVP)',
      applicationLegalese:
          'Proyek Akhir Mobile Programming. Gunakan hanya pada sistem yang '
          'memiliki otorisasi tertulis (lab, CTF, atau aset sendiri).',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(navControllerProvider);
    final compact = MediaQuery.sizeOf(context).width < 700;
    final nav = ref.read(navControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!compact) const AppSidebar(),
                      Expanded(
                        child: Column(
                          children: [
                            if (compact)
                              MobileAppHeader(
                                title: _titleOf(page),
                                historyCount:
                                    ref.watch(historyProvider).entries.length,
                                onHistory: () => openHistory(context),
                                onExport: () => _exportHistory(context, ref),
                                onAbout: () => _showAbout(context),
                              )
                            else
                              AppTopBar(
                                title: _titleOf(page),
                                onHistory: () => openHistory(context),
                                onExport: () => _exportHistory(context, ref),
                                onAbout: () => _showAbout(context),
                              ),
                            Expanded(
                              child: _LazyPageStack(index: page.index),
                            ),
                            if (!compact) const FooterStatusBar(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: compact ? 12 : 16,
                    bottom: compact ? 12 : 40,
                    child: const FloatingChatbot(),
                  ),
                ],
              ),
            ),
            if (compact)
              SafeArea(
                top: false,
                child: _MobileNavigation(
                  current: page,
                  onSelected: nav.select,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({required this.current, required this.onSelected});

  final AppPage current;
  final ValueChanged<AppPage> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: current.index,
      onDestinationSelected: (index) => onSelected(AppPage.values[index]),
      height: 68,
      backgroundColor: AppColors.bgElevated,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.accent.withValues(alpha: 0.18),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.accent),
            label: 'Beranda'),
        NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy, color: AppColors.accent),
            label: 'Exploit'),
        NavigationDestination(
            icon: Icon(Icons.code),
            selectedIcon: Icon(Icons.code, color: AppColors.accent),
            label: 'Generator'),
        NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart, color: AppColors.accent),
            label: 'Monitor'),
        NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppColors.accent),
            label: 'Setelan'),
      ],
    );
  }
}

/// Build only the selected page initially, while retaining the state of pages
/// after the user has visited them.
class _LazyPageStack extends StatefulWidget {
  const _LazyPageStack({required this.index});

  final int index;

  @override
  State<_LazyPageStack> createState() => _LazyPageStackState();
}

class _LazyPageStackState extends State<_LazyPageStack> {
  final List<Widget?> _pages =
      List<Widget?>.filled(AppPage.values.length, null);

  Widget _pageFor(int index) {
    switch (AppPage.values[index]) {
      case AppPage.dashboard:
        return const _DashboardCanvas();
      case AppPage.exploits:
        return const ExploitLibraryPage();
      case AppPage.generator:
        return const ScriptGeneratorPage();
      case AppPage.monitoring:
        return const MonitoringPage();
      case AppPage.settings:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    _pages[widget.index] ??= _pageFor(widget.index);
    return IndexedStack(
      index: widget.index,
      children: [
        for (final page in _pages) page ?? const SizedBox.shrink(),
      ],
    );
  }
}

/// The dashboard canvas. On phones the screen is a thumb-friendly mobile feed:
/// a greeting card, quick tool shortcuts and one vertical card stack. Wide
/// screens keep the three-column desktop composition.
class _DashboardCanvas extends ConsumerWidget {
  const _DashboardCanvas();

  static const double _threeColumnBreakpoint = 1000;
  static const double _gutter = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _threeColumnBreakpoint) {
          final compact = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : _gutter,
              compact ? 14 : _gutter,
              compact ? 16 : _gutter,
              compact ? 124 : 96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact) ...[
                  const _MobileHero(),
                  const SizedBox(height: 18),
                  const _MobileQuickTools(),
                  const SizedBox(height: 20),
                  const _SectionHeading(
                    title: 'Ringkasan',
                    subtitle: 'Aktivitas dan alat utama',
                  ),
                  const SizedBox(height: 10),
                ],
                const StudioConfigPanel(),
                const SizedBox(height: _gutter),
                const ActivityHistoryPanel(),
                const SizedBox(height: _gutter),
                const NmapScansPanel(),
                const SizedBox(height: _gutter),
                const PayloadLibraryPanel(),
                const SizedBox(height: _gutter),
                const ThreatIntelPanel(),
                const SizedBox(height: _gutter),
                const MonitoringPanel(),
              ],
            ),
          );
        }

        const columns = <Widget>[
          Flexible(flex: 6, child: _LeftColumn()),
          Flexible(flex: 4, child: _MiddleColumn()),
          Flexible(flex: 3, child: _RightColumn()),
        ];
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columns,
        );
      },
    );
  }
}

/// Greeting card shown at the top of the phone dashboard.
class _MobileHero extends ConsumerWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2A24), Color(0xFF161B22)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Security Studio',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Lab • CTF • aset sendiri',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Siapkan payload tervalidasi, simpan riwayat terenkripsi, '
            'dan lanjutkan pengujian dari ponsel.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _HeroChip(icon: Icons.wifi_off_rounded, label: 'Offline-ready'),
              _HeroChip(
                  icon: Icons.lock_outline_rounded, label: 'Secure storage'),
              _HeroChip(icon: Icons.verified_outlined, label: 'v1.0.0'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => ref
                      .read(navControllerProvider.notifier)
                      .select(AppPage.generator),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF0D1117),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.terminal_rounded, size: 18),
                  label: const Text(
                    'Buat Payload',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openHistory(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size(0, 46),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Riwayat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accentDim),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal app-style shortcuts to the most used tools on a phone.
class _MobileQuickTools extends ConsumerWidget {
  const _MobileQuickTools();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navControllerProvider.notifier);
    final tools = <({IconData icon, String label, AppPage page})>[
      (icon: Icons.code_rounded, label: 'One-Liner', page: AppPage.generator),
      (
        icon: Icons.folder_copy_outlined,
        label: 'Exploit',
        page: AppPage.exploits
      ),
      (
        icon: Icons.monitor_heart_outlined,
        label: 'Monitor',
        page: AppPage.monitoring
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Alat Cepat',
          subtitle: 'Satu ketukan ke fitur utama',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final tool = tools[index];
              return _QuickToolCard(
                icon: tool.icon,
                label: tool.label,
                onTap: () => nav.select(tool.page),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickToolCard extends StatelessWidget {
  const _QuickToolCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 104,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.accent, size: 18),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A vertically scrollable dashboard column with uniform padding.
class _ScrollColumn extends StatelessWidget {
  const _ScrollColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_DashboardCanvas._gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn();

  @override
  Widget build(BuildContext context) {
    return const _ScrollColumn(children: [
      NmapScansPanel(),
      SizedBox(height: 14),
      PayloadLibraryPanel(),
    ]);
  }
}

class _MiddleColumn extends StatelessWidget {
  const _MiddleColumn();

  @override
  Widget build(BuildContext context) {
    return const _ScrollColumn(children: [
      StudioConfigPanel(),
      SizedBox(height: 14),
      ActivityHistoryPanel(),
    ]);
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn();

  @override
  Widget build(BuildContext context) {
    return const _ScrollColumn(children: [
      ThreatIntelPanel(),
      SizedBox(height: 14),
      MonitoringPanel(),
    ]);
  }
}

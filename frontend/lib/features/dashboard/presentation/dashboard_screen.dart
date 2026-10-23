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
      height: 64,
      backgroundColor: AppColors.bgElevated,
      indicatorColor: AppColors.accent.withValues(alpha: 0.18),
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined), label: 'Home'),
        NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined), label: 'Exploit'),
        NavigationDestination(icon: Icon(Icons.code), label: 'Generator'),
        NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined), label: 'Monitor'),
        NavigationDestination(
            icon: Icon(Icons.settings_outlined), label: 'Settings'),
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

/// The dashboard canvas. On phones/tablets the cards are stacked in a single
/// vertical scroll (thumb-friendly); on wide screens the original three-column
/// grid is used.
class _DashboardCanvas extends StatelessWidget {
  const _DashboardCanvas();

  static const double _threeColumnBreakpoint = 1000;
  static const double _gutter = 14;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _threeColumnBreakpoint) {
          return const SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(_gutter, _gutter, _gutter, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioConfigPanel(),
                SizedBox(height: _gutter),
                NmapScansPanel(),
                SizedBox(height: _gutter),
                ActivityHistoryPanel(),
                SizedBox(height: _gutter),
                PayloadLibraryPanel(),
                SizedBox(height: _gutter),
                ThreatIntelPanel(),
                SizedBox(height: _gutter),
                MonitoringPanel(),
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

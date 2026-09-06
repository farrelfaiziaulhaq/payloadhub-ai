import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'controllers/navigation_controller.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/app_top_bar.dart';
import 'widgets/exploit_library_page.dart';
import 'widgets/floating_chatbot.dart';
import 'widgets/footer_status_bar.dart';
import 'widgets/monitoring_page.dart';
import 'widgets/monitoring_panel.dart';
import 'widgets/nmap_scans_panel.dart';
import 'widgets/payload_library_panel.dart';
import 'widgets/script_generator_page.dart';
import 'widgets/settings_page.dart';
import 'widgets/studio_config_panel.dart';
import 'widgets/threat_intel_panel.dart';

/// The PayloadHub-AI shell: left sidebar + main canvas that switches between
/// sub-pages via an [IndexedStack] (telemetry keeps streaming in the
/// background — no reload between pages) + a floating Info Bot.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(navControllerProvider);
    final compact = MediaQuery.sizeOf(context).width < 700;
    final nav = ref.read(navControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
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
                          AppTopBar(title: _titleOf(page)),
                          Expanded(
                            child: _LazyPageStack(index: page.index),
                          ),
                          const FooterStatusBar(),
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
            _MobileNavigation(
              current: page,
              onSelected: nav.select,
            ),
        ],
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
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.folder_copy_outlined), label: 'Exploit'),
        NavigationDestination(icon: Icon(Icons.code), label: 'Generator'),
        NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), label: 'Monitor'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
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
        return const _CanvasPlaceholder();
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

/// The main 3-column dashboard canvas (page 0).
class _CanvasPlaceholder extends StatelessWidget {
  const _CanvasPlaceholder();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const sidePadding = 14.0;
        const minColumnWidth = 320.0;
        const columns = <Widget>[
          Flexible(flex: 6, child: _LeftColumn()),
          Flexible(flex: 4, child: _MiddleColumn()),
          Flexible(flex: 3, child: _RightColumn()),
        ];
        if (constraints.maxWidth < minColumnWidth * 3) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(sidePadding),
            child: SizedBox(
              height: constraints.maxHeight,
              width: minColumnWidth * 3,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: columns,
              ),
            ),
          );
        }
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
      padding: const EdgeInsets.all(14),
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

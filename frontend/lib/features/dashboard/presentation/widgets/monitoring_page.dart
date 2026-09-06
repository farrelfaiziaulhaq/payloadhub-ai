import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/dashboard_models.dart';
import '../controllers/agent_log_controller.dart';
import '../controllers/navigation_controller.dart';
import '../dashboard_providers.dart';

/// Menu 3 — Monitoring: deep-dive real-time metrics (multi-line chart) and a
/// terminal-style Agent Action Log viewer with level filtering.
class MonitoringPage extends ConsumerStatefulWidget {
  const MonitoringPage({super.key});

  @override
  ConsumerState<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends ConsumerState<MonitoringPage> {
  final _logScroll = ScrollController();
  LogLevel? _filter;
  late final ProviderSubscription<List<AgentLog>> _logSubscription;

  @override
  void initState() {
    super.initState();
    _logSubscription = ref.listenManual<List<AgentLog>>(
      agentLogProvider,
      (_, __) => _scrollLog(),
    );
  }

  void _scrollLog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.jumpTo(_logScroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _logSubscription.close();
    _logScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The compact dashboard monitor remains live, but this heavier chart
    // should only rebuild while the Monitoring page is visible.
    final active = ref.watch(navControllerProvider) == AppPage.monitoring;
    final t =
        active ? ref.watch(telemetryProvider) : ref.read(telemetryProvider);
    final logs = ref.watch(agentLogProvider);

    final filtered =
        _filter == null ? logs : logs.where((l) => l.level == _filter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('System Resource Metrics',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          RepaintBoundary(child: _MetricChart(telemetry: t)),
          const SizedBox(height: 8),
          _Legend(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Agent Action Logs',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              _FilterChip(
                  label: 'Info',
                  level: LogLevel.info,
                  current: _filter,
                  onTap: _toggleFilter),
              const SizedBox(width: 6),
              _FilterChip(
                  label: 'Warning',
                  level: LogLevel.warning,
                  current: _filter,
                  onTap: _toggleFilter),
              const SizedBox(width: 6),
              _FilterChip(
                  label: 'Exploit Exec',
                  level: LogLevel.exploitExecution,
                  current: _filter,
                  onTap: _toggleFilter),
            ],
          ),
          const SizedBox(height: 10),
          _TerminalLog(entries: filtered, scrollController: _logScroll),
        ],
      ),
    );
  }

  void _toggleFilter(LogLevel level) {
    setState(() => _filter = _filter == level ? null : level);
  }
}

// ---------------------------------------------------------------------------
// Multi-line metric chart (CPU / RAM / Disk / Temp)
// ---------------------------------------------------------------------------
class _MetricChart extends StatelessWidget {
  const _MetricChart({required this.telemetry});

  final TelemetryData telemetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomPaint(
        painter: _MultiLinePainter(
          cpu: telemetry.cpuHistory,
          ram: telemetry.ramHistory,
          disk: telemetry.diskIoHistory,
          temp: telemetry.tempHistory,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _MultiLinePainter extends CustomPainter {
  _MultiLinePainter(
      {required this.cpu,
      required this.ram,
      required this.disk,
      required this.temp});

  final List<double> cpu;
  final List<double> ram;
  final List<double> disk;
  final List<double> temp;

  @override
  void paint(Canvas canvas, Size size) {
    final all = [cpu, ram, disk, temp];
    final maxLen = all.fold<int>(1, (m, l) => math.max(m, l.length));

    // horizontal grid lines + Y labels
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final series = <List<double>, Color>{
      cpu: AppColors.accent,
      ram: AppColors.info,
      disk: AppColors.warning,
      temp: AppColors.danger,
    };

    series.forEach((values, color) {
      if (values.isEmpty) return;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final x = size.width * (i / (maxLen - 1).clamp(1, maxLen));
        final y = size.height - (values[i].clamp(0, 100) / 100) * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    });
  }

  @override
  bool shouldRepaint(covariant _MultiLinePainter old) =>
      old.cpu != cpu || old.ram != ram || old.disk != disk || old.temp != temp;
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('CPU', AppColors.accent),
      ('RAM', AppColors.info),
      ('Disk I/O', AppColors.warning),
      ('Temp (°C)', AppColors.danger),
    ];
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 3,
                    color: item.$2,
                  ),
                  const SizedBox(width: 5),
                  Text(item.$1,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Terminal-style log viewer
// ---------------------------------------------------------------------------
class _TerminalLog extends StatelessWidget {
  const _TerminalLog({required this.entries, required this.scrollController});

  final List<AgentLog> entries;
  final ScrollController scrollController;

  Color _colorOf(LogLevel level) {
    switch (level) {
      case LogLevel.exploitExecution:
        return const Color(0xFFFFD700);
      case LogLevel.warning:
        return const Color(0xFFFFA500);
      case LogLevel.info:
        return const Color(0xFF00FF00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.25)),
      ),
      child: entries.isEmpty
          ? const Center(
              child: Text('No matching log entries.',
                  style: TextStyle(
                      color: Color(0xFF00FF00), fontFamily: 'monospace')),
            )
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                      children: [
                        TextSpan(
                          text: '[${e.timestamp}] ',
                          style: const TextStyle(color: Color(0xFF00FF00)),
                        ),
                        TextSpan(
                          text:
                              '[${e.level == LogLevel.exploitExecution ? 'EXPLOIT' : e.level.name.toUpperCase()}] ',
                          style: TextStyle(color: _colorOf(e.level)),
                        ),
                        TextSpan(
                          text: '[TOOL CALL] ${e.tool} ',
                          style: const TextStyle(color: Color(0xFF55E6FF)),
                        ),
                        TextSpan(
                          text: '${e.status} ${e.latencyMs}ms  ',
                          style: TextStyle(
                            color: e.status == 'Error'
                                ? const Color(0xFFFF5555)
                                : const Color(0xFF00FF00),
                          ),
                        ),
                        TextSpan(
                          text: e.message,
                          style: const TextStyle(color: Color(0xFFC7F0C7)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label,
      required this.level,
      required this.current,
      required this.onTap});

  final String label;
  final LogLevel level;
  final LogLevel? current;
  final ValueChanged<LogLevel> onTap;

  @override
  Widget build(BuildContext context) {
    final active = current == level;
    return InkWell(
      onTap: () => onTap(level),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              active ? AppColors.accent.withValues(alpha: 0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: active ? AppColors.accent : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? AppColors.accent : AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            )),
      ),
    );
  }
}

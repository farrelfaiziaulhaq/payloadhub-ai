import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../dashboard_providers.dart';
import 'bar_chart.dart';
import 'donut_gauge.dart';
import 'panel_card.dart';

/// Card 4: Agent Monitoring Systems — live gauges, disk I/O chart, VM state.
class MonitoringPanel extends ConsumerWidget {
  const MonitoringPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(telemetryProvider);

    return PanelCard(
      title: 'Agent Monitoring Systems',
      subtitle: 'Live backend telemetry',
      trailing: const [
        PanelIconButton(icon: Icons.more_vert),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _GaugeColumn(
                  gauge: DonutGauge(
                    value: t.ramUsage,
                    label: '${t.ramUsage.toStringAsFixed(0)}%',
                    color: AppColors.accent,
                  ),
                  title: 'RAM Usage: ${t.ramUsage.toStringAsFixed(0)}%',
                  sub: 'LLM Cache: ${t.llmCache.toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GaugeColumn(
                  gauge: DonutGauge(
                    value: t.cpuLoad,
                    label: '${t.cpuLoad.toStringAsFixed(0)}%',
                    color: AppColors.accent,
                  ),
                  title: 'CPU Load: ${t.cpuLoad.toStringAsFixed(0)}%',
                  sub: 'LLM Kernels: ${t.llmKernels.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Disk I/O: Local Storage',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RepaintBoundary(
            child: BarChart(values: t.diskIoHistory, height: 88),
          ),
          const SizedBox(height: 18),
          const Text(
            'VM State (Ollama):',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _VmStatus(healthy: t.vmHealthy, label: t.vmLabel),
        ],
      ),
    );
  }
}

class _GaugeColumn extends StatelessWidget {
  const _GaugeColumn(
      {required this.gauge, required this.title, required this.sub});

  final Widget gauge;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(child: FittedBox(fit: BoxFit.scaleDown, child: gauge)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            sub,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
          ),
        ),
      ],
    );
  }
}

class _VmStatus extends StatelessWidget {
  const _VmStatus({required this.healthy, required this.label});

  final bool healthy;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = healthy ? AppColors.accent : AppColors.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 9,
                height: 9,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  healthy ? '$label: Healthy / Online' : '$label: Offline',
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: healthy ? 0.86 : 0.1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.5),
                      color.withValues(alpha: 1)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

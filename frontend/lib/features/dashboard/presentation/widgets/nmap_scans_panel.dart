import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/threat_intel_service.dart';
import '../../domain/models/dashboard_models.dart';
import '../dashboard_providers.dart';
import 'panel_card.dart';

/// Card 1: Active Attack Surface & Quick Exploits.
/// Shows the latest Nmap scans table, vulnerable services, and ExploitDB query.
class NmapScansPanel extends StatelessWidget {
  const NmapScansPanel({super.key});

  static const _scans = <NmapScan>[
    NmapScan(
      ip: '10.10.14.8',
      os: 'Common',
      services: 'nmap://21btidep.nanop/',
      healthy: false,
    ),
    NmapScan(
      ip: '10.10.14.8227',
      os: 'Healthy',
      services: 'http://payloadhub2003/',
      healthy: true,
    ),
    NmapScan(
      ip: '10.10.14.14',
      os: 'Unknown',
      services: 'https://cve-tracker.be/',
      healthy: false,
    ),
  ];

  static const _vulnerable = <VulnerableService>[
    VulnerableService(
      title:
          'Unpatched Samba 3.0.20 exposes usermap script RCE (CVE-2007-2447)',
      score: 9.1,
    ),
    VulnerableService(
      title: 'Apache httpd 2.4.49 path traversal to RCE (CVE-2021-41773)',
      score: 8.6,
    ),
    VulnerableService(
      title: 'Exim 4.89 SMTP remote command execution (CVE-2019-10149)',
      score: 9.8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'Active Attack Surface & Quick Exploits',
      trailing: const [
        PanelIconButton(icon: Icons.more_vert),
        PanelIconButton(icon: Icons.open_in_full),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Text(
                'Latest Nmap Scans',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dynamic, real-time updating.',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.refresh, size: 12, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          const _ScanTable(scans: _scans),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text(
                'Vulnerable Services',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Until real-time updating',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
              Icon(Icons.refresh, size: 12, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          const _VulnerableList(services: _vulnerable),
          const SizedBox(height: 14),
          _SearchField(),
        ],
      ),
    );
  }
}

class _ScanTable extends StatelessWidget {
  const _ScanTable({required this.scans});

  final List<NmapScan> scans;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TableHeader(),
        ...scans.map(
          (s) => _TableRow(scan: s),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
              width: 96,
              child: Text('IP Address',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11))),
          SizedBox(
              width: 70,
              child: Text('OS',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11))),
          Expanded(
              child: Text('Services',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.scan});

  final NmapScan scan;

  @override
  Widget build(BuildContext context) {
    final statusColor = scan.healthy ? AppColors.accent : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              scan.ip,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 70,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    scan.os,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              scan.services,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _VulnerableList extends StatelessWidget {
  const _VulnerableList({required this.services});

  final List<VulnerableService> services;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: services.asMap().entries.map((entry) {
        final i = entry.key + 1;
        final s = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$i. ',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              Expanded(
                child: Text(
                  s.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              _ScoreBadge(score: s.score),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 9.0
        ? AppColors.danger
        : (score >= 7.0 ? AppColors.warning : AppColors.accent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        score.toStringAsFixed(1),
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final results =
          await ref.read(threatIntelServiceProvider).searchExploitDb(query);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) =>
            _ExploitResultsDialog(query: query, results: results),
      );
    } on AppException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _search(),
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Search ExploitDB (CVE / service / version)',
                hintStyle:
                    TextStyle(color: AppColors.textSecondary, fontSize: 11),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            onPressed: _busy ? null : _search,
            icon: _busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.arrow_forward,
                    color: AppColors.accent, size: 16),
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _ExploitResultsDialog extends StatelessWidget {
  const _ExploitResultsDialog({required this.query, required this.results});

  final String query;
  final List<ExploitDbItem> results;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('ExploitDB: $query'),
      content: SizedBox(
        width: 620,
        child: results.isEmpty
            ? const Text('Tidak ada exploit yang cocok.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = results[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item.id} — ${item.title}'),
                    subtitle: Text(
                        '${item.platform} · ${item.type} · ${item.date}\n${item.file}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'Copy ExploitDB URL',
                      icon: const Icon(Icons.copy, size: 17),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: item.url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ExploitDB URL copied')),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Close'))
      ],
    );
  }
}

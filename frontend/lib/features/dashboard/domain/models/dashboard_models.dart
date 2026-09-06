/// Immutable snapshot of live system telemetry streamed to the dashboard.
class TelemetryData {
  const TelemetryData({
    required this.ramUsage,
    required this.llmCache,
    required this.cpuLoad,
    required this.llmKernels,
    required this.networkPercent,
    required this.networkConnections,
    required this.uptime,
    required this.diskIoHistory,
    required this.cpuHistory,
    required this.ramHistory,
    required this.tempHistory,
    required this.hostTemp,
    required this.vmHealthy,
    required this.vmLabel,
  });

  final double ramUsage; // 0-100
  final double llmCache; // 0-100
  final double cpuLoad; // 0-100
  final double llmKernels; // 0-100
  final double networkPercent; // 0-100
  final int networkConnections;
  final Duration uptime;
  final List<double> diskIoHistory;
  final List<double> cpuHistory;
  final List<double> ramHistory;
  final List<double> tempHistory;
  final double hostTemp; // celsius
  final bool vmHealthy;
  final String vmLabel;

  TelemetryData copyWith({
    double? ramUsage,
    double? llmCache,
    double? cpuLoad,
    double? llmKernels,
    double? networkPercent,
    int? networkConnections,
    Duration? uptime,
    List<double>? diskIoHistory,
    List<double>? cpuHistory,
    List<double>? ramHistory,
    List<double>? tempHistory,
    double? hostTemp,
    bool? vmHealthy,
    String? vmLabel,
  }) {
    return TelemetryData(
      ramUsage: ramUsage ?? this.ramUsage,
      llmCache: llmCache ?? this.llmCache,
      cpuLoad: cpuLoad ?? this.cpuLoad,
      llmKernels: llmKernels ?? this.llmKernels,
      networkPercent: networkPercent ?? this.networkPercent,
      networkConnections: networkConnections ?? this.networkConnections,
      uptime: uptime ?? this.uptime,
      diskIoHistory: diskIoHistory ?? this.diskIoHistory,
      cpuHistory: cpuHistory ?? this.cpuHistory,
      ramHistory: ramHistory ?? this.ramHistory,
      tempHistory: tempHistory ?? this.tempHistory,
      hostTemp: hostTemp ?? this.hostTemp,
      vmHealthy: vmHealthy ?? this.vmHealthy,
      vmLabel: vmLabel ?? this.vmLabel,
    );
  }
}

/// A single monitored Nmap scan result row.
class NmapScan {
  const NmapScan({
    required this.ip,
    required this.os,
    required this.services,
    required this.healthy,
  });

  final String ip;
  final String os;
  final String services;
  final bool healthy;
}

/// A vulnerable service entry with a threat score.
class VulnerableService {
  const VulnerableService({required this.title, required this.score});

  final String title;
  final double score; // 0-10
}

/// A ready-to-use payload category chip.
class PayloadCategory {
  const PayloadCategory(this.label);

  final String label;
}

/// Studio form selections used to compose a payload request.
class StudioSelections {
  const StudioSelections({
    this.os = 'Linux',
    this.language = 'Python',
    this.perl = 'Perl',
    this.bypass = 'Default',
    this.encoder = 'Auto',
    this.aiPrompt = '',
  });

  final String os;
  final String language;
  final String perl;
  final String bypass;
  final String encoder;
  final String aiPrompt;
}

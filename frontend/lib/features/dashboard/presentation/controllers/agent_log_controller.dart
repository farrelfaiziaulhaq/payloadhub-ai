import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navigation_controller.dart';

enum LogLevel { info, warning, exploitExecution }

class AgentLog {
  const AgentLog({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.tool,
    required this.status,
    required this.latencyMs,
  });

  final String timestamp;
  final LogLevel level;
  final String message;
  final String tool;
  final String status;
  final int latencyMs;
}

/// Streams agent action logs (terminal style). A seeded sample is shown on
/// start, then new entries are appended on an interval so the log feels live.
class AgentLogController extends StateNotifier<List<AgentLog>> {
  AgentLogController()
      : _rand = Random(11),
        super(_seed());

  final Random _rand;
  Timer? _timer;
  bool _disposed = false;
  static const int _maxLogs = 120;

  static String _ts([Random? r]) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }

  static List<AgentLog> _seed() {
    final r = Random(3);
    return [
      AgentLog(
        timestamp: _ts(r),
        level: LogLevel.info,
        message: 'Agent initialized',
        tool: 'router',
        status: '200 OK',
        latencyMs: 42,
      ),
      AgentLog(
        timestamp: _ts(r),
        level: LogLevel.info,
        message: 'Listening for user context',
        tool: 'core',
        status: '200 OK',
        latencyMs: 12,
      ),
      AgentLog(
        timestamp: _ts(r),
        level: LogLevel.exploitExecution,
        message: 'Selected tool generate_reverse_shell_tool',
        tool: 'generate_reverse_shell_tool',
        status: '200 OK',
        latencyMs: 384,
      ),
      AgentLog(
        timestamp: _ts(r),
        level: LogLevel.info,
        message: 'Payload assembled + base64 encoded',
        tool: 'encode',
        status: '200 OK',
        latencyMs: 21,
      ),
      AgentLog(
        timestamp: _ts(r),
        level: LogLevel.warning,
        message: 'Low confidence CVE match, verify manually',
        tool: 'parse_nmap_cve_tool',
        status: '200 OK',
        latencyMs: 217,
      ),
      AgentLog(
        timestamp: _ts(r),
        level: LogLevel.info,
        message: 'JWT header decoded, alg=none detected',
        tool: 'jwt_analyzer_tool',
        status: '200 OK',
        latencyMs: 88,
      ),
    ];
  }

  /// Pause synthetic log updates when the Monitoring page is hidden.
  void setActive(bool active) {
    if (_disposed) return;
    if (active && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _append());
    } else if (!active) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _append() {
    if (_disposed) return;
    final options = [
      AgentLog(
        timestamp: _ts(_rand),
        level: LogLevel.info,
        message: 'Heartbeat: telemetry snapshot flushed',
        tool: 'telemetry',
        status: '200 OK',
        latencyMs: 8 + _rand.nextInt(30),
      ),
      AgentLog(
        timestamp: _ts(_rand),
        level: LogLevel.exploitExecution,
        message: 'Tool call dispatched',
        tool: [
          'generate_reverse_shell_tool',
          'jwt_analyzer_tool',
          'parse_nmap_cve_tool'
        ][_rand.nextInt(3)],
        status: '200 OK',
        latencyMs: 120 + _rand.nextInt(300),
      ),
      AgentLog(
        timestamp: _ts(_rand),
        level: LogLevel.warning,
        message: 'Retrying after transient provider timeout',
        tool: 'llm_router',
        status: 'Error',
        latencyMs: 900 + _rand.nextInt(400),
      ),
    ];
    final next = [...state, options[_rand.nextInt(options.length)]];
    if (next.length > _maxLogs) next.removeRange(0, next.length - _maxLogs);
    state = next;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

final agentLogProvider =
    StateNotifierProvider<AgentLogController, List<AgentLog>>((ref) {
  final controller = AgentLogController();
  ref.listen<AppPage>(navControllerProvider, (_, page) {
    controller.setActive(page == AppPage.monitoring);
  }, fireImmediately: true);
  return controller;
});

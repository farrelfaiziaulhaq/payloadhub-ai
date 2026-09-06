import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/dashboard_models.dart';

/// Streams live telemetry (RAM/CPU/network/uptime/disk-I/O/host-temp) every
/// second so the dashboard + monitoring charts animate in real time. Uses a
/// seeded random walk so values drift smoothly instead of jumping wildly.
class TelemetryController extends StateNotifier<TelemetryData> {
  TelemetryController()
      : _rand = Random(42),
        super(_initial()) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final Random _rand;
  late final Timer _timer;
  bool _disposed = false;

  static const int _historyLen = 40;

  static TelemetryData _initial() {
    return TelemetryData(
      ramUsage: 71,
      llmCache: 42,
      cpuLoad: 57,
      llmKernels: 34,
      networkPercent: 18,
      networkConnections: 188,
      uptime: const Duration(hours: 1, minutes: 22, seconds: 57),
      diskIoHistory: _seedHistory(20, 85),
      cpuHistory: _seedHistory(30, 75),
      ramHistory: _seedHistory(50, 90),
      tempHistory: _seedHistory(40, 75),
      hostTemp: 58,
      vmHealthy: true,
      vmLabel: 'Ollama',
    );
  }

  static List<double> _seedHistory(double min, double max) {
    final r = Random(7);
    return List<double>.generate(
      _historyLen,
      (_) => min + r.nextDouble() * (max - min),
    );
  }

  double _drift(double value, double amplitude, double min, double max) {
    final next = value + (_rand.nextDouble() - 0.5) * amplitude;
    return next.clamp(min, max);
  }

  void _push(List<double> history, double value) {
    if (history.length >= _historyLen) history.removeAt(0);
    history.add(value);
  }

  void _tick() {
    if (_disposed) return;
    final t = state;

    final ramUsage = _drift(t.ramUsage, 4, 45, 95);
    final cpuLoad = _drift(t.cpuLoad, 6, 20, 95);
    final hostTemp = _drift(t.hostTemp, 1.2, 35, 88);

    final diskIo = [...t.diskIoHistory];
    final cpuHistory = [...t.cpuHistory];
    final ramHistory = [...t.ramHistory];
    final tempHistory = [...t.tempHistory];

    _push(diskIo, 15 + _rand.nextDouble() * 85);
    _push(cpuHistory, cpuLoad);
    _push(ramHistory, ramUsage);
    _push(tempHistory, hostTemp);

    state = t.copyWith(
      ramUsage: ramUsage,
      llmCache: _drift(t.llmCache, 3, 20, 70),
      cpuLoad: cpuLoad,
      llmKernels: _drift(t.llmKernels, 3, 10, 60),
      networkPercent: _drift(t.networkPercent, 4, 5, 95),
      networkConnections:
          (t.networkConnections + (_rand.nextInt(11) - 5)).clamp(60, 420),
      uptime: t.uptime + const Duration(seconds: 1),
      diskIoHistory: diskIo,
      cpuHistory: cpuHistory,
      ramHistory: ramHistory,
      tempHistory: tempHistory,
      hostTemp: hostTemp,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _timer.cancel();
    super.dispose();
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A vertical bar chart used for Disk I/O monitoring, painted as a gradient.
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.values, this.height = 90});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _BarChartPainter(values)),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const gap = 3.0;
    final barWidth =
        math.max(2.0, (size.width - gap * (values.length - 1)) / values.length);
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.accent, AppColors.info],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (var i = 0; i < values.length; i++) {
      final normalized = (values[i].clamp(0, 100)) / 100;
      final barHeight = normalized * size.height;
      final left = i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, gradientPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

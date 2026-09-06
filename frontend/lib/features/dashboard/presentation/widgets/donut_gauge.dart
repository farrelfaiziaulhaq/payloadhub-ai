import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A circular progress gauge (donut) drawn with a CustomPainter.
class DonutGauge extends StatelessWidget {
  const DonutGauge({
    super.key,
    required this.value,
    required this.label,
    this.subLabel = '',
    this.color = AppColors.accent,
    this.size = 96,
    this.thickness = 9,
  });

  final double value; // 0-100
  final String label;
  final String subLabel;
  final Color color;
  final double size;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _GaugePainter(value: value, color: color, thickness: thickness),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subLabel.isNotEmpty)
                  Text(
                    subLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color, required this.thickness});

  final double value;
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - thickness) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = AppColors.track;

    canvas.drawCircle(center, radius, trackPaint);

    final sweep = (value.clamp(0, 100) / 100) * 2 * math.pi;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

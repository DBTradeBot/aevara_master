// lib/charts/donut_gauge.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A simple, non-animating donut gauge.
/// - [percent] is 0.0 to 1.0
/// - [size] is the square dimension of the canvas
/// - [thickness] controls ring width
/// - Optional [center] widget to render in the middle
class DonutGauge extends StatelessWidget {
  const DonutGauge({
    super.key,
    required this.percent,
    this.size = 160,
    this.thickness = 12,
    this.backgroundColor,
    this.progressColor,
    this.center,
    this.startAngle = -math.pi / 2, // start at top
    this.capRound = true,
  });

  final double percent;
  final double size;
  final double thickness;
  final Color? backgroundColor;
  final Color? progressColor;
  final Widget? center;
  final double startAngle;
  final bool capRound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.surfaceContainerHighest.withOpacity(0.4);
    final fg = progressColor ?? theme.colorScheme.primary;

    // Clamp defensively
    final pct = percent.isNaN ? 0.0 : percent.clamp(0.0, 1.0);

    return Semantics(
      label: 'Vitality gauge',
      value: '${(pct * 100).round()} percent',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DonutPainter(
            percent: pct,
            thickness: thickness,
            background: bg,
            progress: fg,
            startAngle: startAngle,
            capRound: capRound,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.percent,
    required this.thickness,
    required this.background,
    required this.progress,
    required this.startAngle,
    required this.capRound,
  });

  final double percent;
  final double thickness;
  final Color background;
  final Color progress;
  final double startAngle;
  final bool capRound;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = capRound ? StrokeCap.round : StrokeCap.butt;

    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - thickness / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // Background ring (full circle)
    stroke.color = background;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, stroke);

    // Progress arc
    if (percent > 0) {
      stroke.color = progress;
      final sweep = (math.pi * 2) * percent;
      canvas.drawArc(arcRect, startAngle, sweep, false, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return percent != oldDelegate.percent ||
        thickness != oldDelegate.thickness ||
        background != oldDelegate.background ||
        progress != oldDelegate.progress ||
        startAngle != oldDelegate.startAngle ||
        capRound != oldDelegate.capRound;
  }
}

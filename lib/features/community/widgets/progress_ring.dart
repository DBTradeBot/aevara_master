import 'dart:math' as math;
import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;
  const ProgressRing({super.key, required this.progress, this.size = 64, this.color = const Color(0xFF5B6CFF)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, color: color),
        child: Center(
          child: Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.black12
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = LinearGradient(colors: [color, color.withOpacity(.6)]).createShader(rect)
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi/2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.color != color;
}

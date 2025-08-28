// lib/charts/donut_gauge.dart
//
// DonutGauge – semicircle gauge with optional center-origin signed fill.
//
// Back-compatible API + new options:
// - value01: legacy 0..1 fill from left→right (kept).
// - valueSigned01: NEW [-1..+1] fill from center (0) to left (−) or right (+).
// - neutralFraction: center of the arc as a fraction (default 0.5).
// - segmentedTrack: optional faint 3-zone background (kept).
// - confidenceOverlay: diagonal hatch overlay (e.g., low confidence).
// - calibratingDash: dashed active arc (during calibration).
// - showTipDot: small dot at the fill tip.
//
// All new props default to "off", so existing call sites render identically.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutGauge extends StatelessWidget {
  const DonutGauge({
    super.key,
    this.fraction, // legacy: 0..1 from left to right
    this.value01,  // alias for legacy
    this.valueSigned01, // NEW: -1..+1 from center (0) left(-) / right(+)
    this.neutralFraction = 0.5, // default center of the arc
    this.strokeWidth = 20,
    required this.gradient,
    this.trackColor = const Color(0xFFE0E3E7),
    this.showTicks = false,
    this.ticks = const <double>[],
    this.tickColor = const Color(0xFFCDD3DB),
    this.chronoMarkerFraction = 1.0,
    this.chronoMarkerLabel,
    this.chronoMarkerColor = const Color(0xFF575C6C),
    this.shadow = false,

    // Extra options
    this.segmentedTrack = false,
    this.segmentColors,
    this.confidenceOverlay = false,
    this.calibratingDash = false,
    this.showTipDot = false,
  });

  // Legacy API
  final double? fraction;
  final double? value01;

  // NEW: signed center-origin value [-1..+1]
  final double? valueSigned01;
  final double neutralFraction;

  final double strokeWidth;
  final List<Color> gradient;
  final Color trackColor;

  final bool showTicks;
  final List<double> ticks;
  final Color tickColor;

  final double chronoMarkerFraction;
  final String? chronoMarkerLabel;
  final Color chronoMarkerColor;

  final bool shadow;

  // Extras
  final bool segmentedTrack;
  final List<Color>? segmentColors;
  final bool confidenceOverlay;
  final bool calibratingDash;
  final bool showTipDot;

  // Arc config: 180° semicircle, start at -π (left), sweep +π to 0 (right)
  static const double _startAngle = -math.pi;
  static const double _sweep = math.pi;

  @override
  Widget build(BuildContext context) {
    final List<Color> segCols =
    (segmentColors != null && segmentColors!.length >= 3)
        ? segmentColors!
        : const [
      Color(0xFF24A699), // good
      Color(0xFFF6B56B), // warn
      Color(0xFFBF4A4A), // bad
    ];

    // Resolve which mode to use:
    final bool useSigned = valueSigned01 != null;
    double vStd = ((value01 ?? fraction) ?? 0).clamp(0.0, 1.0);
    double vSigned = (valueSigned01 ?? 0).clamp(-1.0, 1.0);
    final double neutral = neutralFraction.clamp(0.0, 1.0);

    return CustomPaint(
      painter: _DonutGaugePainter(
        modeSigned: useSigned,
        value01: vStd,
        valueSigned01: vSigned,
        neutralFraction: neutral,
        strokeWidth: strokeWidth,
        gradient: gradient,
        trackColor: trackColor,
        showTicks: showTicks,
        ticks: ticks,
        tickColor: tickColor,
        chronoMarkerFraction: chronoMarkerFraction.clamp(0.0, 1.0),
        chronoMarkerLabel: chronoMarkerLabel,
        chronoMarkerColor: chronoMarkerColor,
        shadow: shadow,
        segmentedTrack: segmentedTrack,
        segmentColors: segCols,
        confidenceOverlay: confidenceOverlay,
        calibratingDash: calibratingDash,
        showTipDot: showTipDot,
        startAngle: _startAngle,
        sweep: _sweep,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DonutGaugePainter extends CustomPainter {
  _DonutGaugePainter({
    required this.modeSigned,
    required this.value01,
    required this.valueSigned01,
    required this.neutralFraction,
    required this.strokeWidth,
    required this.gradient,
    required this.trackColor,
    required this.showTicks,
    required this.ticks,
    required this.tickColor,
    required this.chronoMarkerFraction,
    required this.chronoMarkerLabel,
    required this.chronoMarkerColor,
    required this.shadow,
    required this.segmentedTrack,
    required this.segmentColors,
    required this.confidenceOverlay,
    required this.calibratingDash,
    required this.showTipDot,
    required this.startAngle,
    required this.sweep,
  });

  final bool modeSigned;
  final double value01;
  final double valueSigned01;
  final double neutralFraction;

  final double strokeWidth;
  final List<Color> gradient;
  final Color trackColor;

  final bool showTicks;
  final List<double> ticks;
  final Color tickColor;

  final double chronoMarkerFraction;
  final String? chronoMarkerLabel;
  final Color chronoMarkerColor;

  final bool shadow;

  final bool segmentedTrack;
  final List<Color> segmentColors;
  final bool confidenceOverlay;
  final bool calibratingDash;
  final bool showTipDot;

  final double startAngle;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final radius = math.min(size.width, size.height) / 2.0 - strokeWidth / 2.0;
    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // ---- Track (faint full outline or segmented) ----
    if (segmentedTrack) {
      final zones = <(double, double, Color)>[
        (0.0, 1 / 3, segmentColors[0]),
        (1 / 3, 2 / 3, segmentColors[1]),
        (2 / 3, 1.0, segmentColors[2]),
      ];
      for (final z in zones) {
        final a0 = startAngle + sweep * z.$1;
        final a1 = sweep * (z.$2 - z.$1);
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = z.$3.withOpacity(0.18);
        canvas.drawArc(arcRect, a0, a1, false, p);
      }
    } else {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = trackColor;
      canvas.drawArc(arcRect, startAngle, sweep, false, p);
    }

    // ---- Optional ticks ----
    if (showTicks && ticks.isNotEmpty) {
      final tickPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.12
        ..strokeCap = StrokeCap.round
        ..color = tickColor;
      for (final t in ticks) {
        final tt = t.clamp(0.0, 1.0);
        final a = startAngle + sweep * tt;
        final rOuter = radius + strokeWidth * 0.1;
        final rInner = rOuter - strokeWidth * 0.5;
        final p1 = Offset(cx + rInner * math.cos(a), cy + rInner * math.sin(a));
        final p2 = Offset(cx + rOuter * math.cos(a), cy + rOuter * math.sin(a));
        canvas.drawLine(p1, p2, tickPaint);
      }
    }

    // ---- Active arc (gradient) ----
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweep,
        colors: gradient,
      ).createShader(arcRect);

    // Pre-shadow for subtle depth
    if (shadow) {
      final shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = gradient.last.withOpacity(0.22);
      final shLen = modeSigned ? sweep * (valueSigned01.abs() * 0.5) : sweep * value01;
      final shStartFrac = modeSigned
          ? (valueSigned01 >= 0
          ? neutralFraction
          : (neutralFraction - valueSigned01.abs() * 0.5))
          : 0.0;
      canvas.drawArc(
        arcRect,
        startAngle + sweep * shStartFrac,
        shLen,
        false,
        shadowPaint,
      );
    }

    // Dashed vs solid
    void _drawActive(double fromFrac, double lenFrac) {
      if (lenFrac <= 0) return;
      if (calibratingDash) {
        const dash = 8.0, gap = 6.0;
        final totalSweep = sweep * lenFrac;
        double drawn = 0;
        while (drawn < totalSweep) {
          final seg = math.min(dash / radius, totalSweep - drawn);
          canvas.drawArc(
            arcRect,
            startAngle + sweep * fromFrac + drawn,
            seg,
            false,
            activePaint,
          );
          drawn += seg + (gap / radius);
        }
      } else {
        canvas.drawArc(
          arcRect,
          startAngle + sweep * fromFrac,
          sweep * lenFrac,
          false,
          activePaint,
        );
      }
    }

    if (modeSigned) {
      final lenFrac = valueSigned01.abs() * 0.5; // half the arc is "positive" side
      final fromFrac = valueSigned01 >= 0
          ? neutralFraction
          : (neutralFraction - lenFrac);
      _drawActive(fromFrac, lenFrac);

      // Tip dot
      if (showTipDot && valueSigned01 != 0) {
        final aTip = startAngle +
            sweep * (valueSigned01 >= 0 ? (neutralFraction + lenFrac) : neutralFraction);
        final tip = Offset(cx + radius * math.cos(aTip), cy + radius * math.sin(aTip));
        final dot = Paint()..color = gradient.last;
        canvas.drawCircle(tip, strokeWidth * 0.22, dot);
      }
    } else {
      // Legacy left→right fill
      _drawActive(0.0, value01);
      if (showTipDot && value01 > 0) {
        final aTip = startAngle + sweep * value01;
        final tip = Offset(cx + radius * math.cos(aTip), cy + radius * math.sin(aTip));
        final dot = Paint()..color = gradient.last;
        canvas.drawCircle(tip, strokeWidth * 0.22, dot);
      }
    }

    // ---- Optional chronological marker tick/label ----
    if (chronoMarkerFraction >= 0 && chronoMarkerFraction <= 1) {
      final a = startAngle + sweep * chronoMarkerFraction;
      final rOuter = radius + strokeWidth * 0.1;
      final rInner = rOuter - strokeWidth * 0.55;
      final p1 = Offset(cx + rInner * math.cos(a), cy + rInner * math.sin(a));
      final p2 = Offset(cx + rOuter * math.cos(a), cy + rOuter * math.sin(a));
      final mPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.14
        ..strokeCap = StrokeCap.round
        ..color = chronoMarkerColor.withOpacity(0.9);
      canvas.drawLine(p1, p2, mPaint);

      if (chronoMarkerLabel != null && chronoMarkerLabel!.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: chronoMarkerLabel!,
            style: TextStyle(fontSize: strokeWidth * 0.6, color: chronoMarkerColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelOffset = Offset(
          cx + (radius + strokeWidth * 0.8) * math.cos(a) - textPainter.width / 2,
          cy + (radius + strokeWidth * 0.8) * math.sin(a) - textPainter.height / 2,
        );
        textPainter.paint(canvas, labelOffset);
      }
    }

    // ---- Confidence overlay (hatch) ----
    if (confidenceOverlay) {
      final innerRect = Rect.fromCircle(
          center: Offset(cx, cy), radius: radius - strokeWidth / 2.0);
      final outerRect = Rect.fromCircle(
          center: Offset(cx, cy), radius: radius + strokeWidth / 2.0);
      final clipPath = Path()
        ..addOval(outerRect)
        ..addOval(innerRect)
        ..fillType = PathFillType.evenOdd;

      canvas.save();
      canvas.clipPath(clipPath);
      final hatchPaint = Paint()
        ..color = Colors.black.withOpacity(0.07)
        ..strokeWidth = 2.0;
      const step = 8.0;
      for (double x = -size.height; x < size.width + size.height; x += step) {
        canvas.drawLine(
            Offset(x, 0), Offset(x + size.height, size.height), hatchPaint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DonutGaugePainter old) {
    return modeSigned != old.modeSigned ||
        value01 != old.value01 ||
        valueSigned01 != old.valueSigned01 ||
        neutralFraction != old.neutralFraction ||
        strokeWidth != old.strokeWidth ||
        gradient != old.gradient ||
        trackColor != old.trackColor ||
        showTicks != old.showTicks ||
        tickColor != old.tickColor ||
        chronoMarkerFraction != old.chronoMarkerFraction ||
        chronoMarkerLabel != old.chronoMarkerLabel ||
        chronoMarkerColor != old.chronoMarkerColor ||
        shadow != old.shadow ||
        segmentedTrack != old.segmentedTrack ||
        segmentColors != old.segmentColors ||
        confidenceOverlay != old.confidenceOverlay ||
        calibratingDash != old.calibratingDash ||
        showTipDot != old.showTipDot;
  }
}

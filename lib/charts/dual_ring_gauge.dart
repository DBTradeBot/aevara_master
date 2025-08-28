// lib/charts/dual_ring_gauge.dart
//
// Option B: Dual-Ring Gauge
// - Inner ring: chronological age (neutral gray)
// - Outer ring: predicted/vitality age (colored) with radial offset
//   • If vitality < chrono  → ring dips inward (GREEN section)
//   • If vitality > chrono  → ring bulges outward (ORANGE/RED section)
// - Emphasizes the *distance* (delta years) as thickness/offset + color
//
// Notes:
// - No dependencies on view-model internals. Pure widget.
// - Color tokens align with /docs/4_design_system.md (Success, Warning, Error).
// - Public API kept small; defaults are sensible.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class DualRingGauge extends StatelessWidget {
  const DualRingGauge({
    super.key,
    required this.chronoAge,          // actual age (years)
    required this.vitalityAge,        // predicted/vitality age (years)
    this.minDeltaYears = -4.0,        // left bound (younger is negative delta)
    this.maxDeltaYears =  4.0,        // right bound (older is positive delta)
    this.size = const Size(double.infinity, 200),
    this.baseStroke = 16.0,
    this.outerStroke = 18.0,
    this.innerColor = const Color(0xFFE0E3E7),
    this.youngerStart = const Color(0xFF24A699),  // deep green
    this.olderStart = const Color(0xFFBF4A4A),    // deep red
    this.warnMid   = const Color(0xFFF6B56B),     // orange
    this.bg = Colors.transparent,
    this.labelStyle,
    this.deltaLabelStyle,
    this.showTicks = true,
    this.tickColor = const Color(0xFFCDD3DB),
    this.tickCount = 5,  // includes ends; default: | | | | |
  });

  final double chronoAge;
  final double vitalityAge;

  // Mapping range for delta → visual intensity
  final double minDeltaYears;
  final double maxDeltaYears;

  // Layout and styling
  final Size size;
  final double baseStroke;
  final double outerStroke;
  final Color innerColor; // chronological ring
  final Color youngerStart;
  final Color olderStart;
  final Color warnMid;
  final Color bg;

  final TextStyle? labelStyle;
  final TextStyle? deltaLabelStyle;

  final bool showTicks;
  final Color tickColor;
  final int tickCount;

  @override
  Widget build(BuildContext context) {
    final delta = vitalityAge - chronoAge; // +older, -younger

    // Normalize |delta| into [0..1] for intensity/offset
    double norm;
    if (delta >= 0) {
      norm = (delta / maxDeltaYears).clamp(0.0, 1.0);
    } else {
      norm = (delta.abs() / minDeltaYears.abs()).clamp(0.0, 1.0);
    }

    // Choose a color ramp for OUTER ring by sign of delta
    final Color outerColor = () {
      if (delta < 0) {
        // younger → green family; intensify slightly with magnitude
        return Color.lerp(youngerStart.withOpacity(0.85), youngerStart, norm) ?? youngerStart;
      } else if (delta == 0) {
        // neutral → soft gray/azure blend
        return const Color(0xFF3F87A6).withOpacity(0.35);
      } else {
        // older → orange→red as it grows
        // small deltas: more orange; larger: blend toward red
        return Color.lerp(warnMid, olderStart, math.min(1.0, norm * 1.1)) ?? olderStart;
      }
    }();

    // Outer ring offset: inward if younger, outward if older
    // Keep it subtle so small daily changes still look vibrant.
    final double baseOffset = baseStroke * 0.45;
    final double maxExtra = baseStroke * 0.55;
    final double signedOffset = (delta.sign) * (baseOffset + maxExtra * norm);

    // Where num.sign is a getter on double; if you copied older code using sign(x),
    // this line replaces it safely with .sign (−1.0, 0.0, 1.0).
    // (No extra helper needed.)

    return AspectRatio(
      aspectRatio: size.width.isFinite && size.height.isFinite
          ? (size.width / size.height)
          : (200 / 200),
      child: CustomPaint(
        painter: _DualRingPainter(
          chronoAge: chronoAge,
          vitalityAge: vitalityAge,
          delta: delta,
          norm: norm,
          innerColor: innerColor,
          outerColor: outerColor,
          baseStroke: baseStroke,
          outerStroke: outerStroke,
          tickColor: tickColor,
          showTicks: showTicks,
          tickCount: tickCount,
          signedOffset: signedOffset,
        ),
        child: _CenterLabels(
          chronoAge: chronoAge,
          vitalityAge: vitalityAge,
          delta: delta,
          labelStyle: labelStyle ??
              TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1B1B1B),
              ),
          deltaLabelStyle: deltaLabelStyle ??
              const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF575C6C),
              ),
        ),
      ),
    );
  }
}

class _DualRingPainter extends CustomPainter {
  _DualRingPainter({
    required this.chronoAge,
    required this.vitalityAge,
    required this.delta,
    required this.norm,
    required this.innerColor,
    required this.outerColor,
    required this.baseStroke,
    required this.outerStroke,
    required this.tickColor,
    required this.showTicks,
    required this.tickCount,
    required this.signedOffset,
  });

  final double chronoAge;
  final double vitalityAge;
  final double delta; // +older, -younger
  final double norm;  // |delta| normalized to [0..1]
  final Color innerColor;
  final Color outerColor;
  final double baseStroke;
  final double outerStroke;
  final Color tickColor;
  final bool showTicks;
  final int tickCount;
  final double signedOffset;

  static const double _startAngle = -math.pi; // left
  static const double _sweep = math.pi;       // semicircle

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    final radius = math.min(size.width, size.height) * 0.44;

    // ----- Draw inner (chronological) semicircle ring -----
    final innerRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseStroke
      ..strokeCap = StrokeCap.round
      ..color = innerColor;
    canvas.drawArc(innerRect, _startAngle, _sweep, false, innerPaint);

    // ----- Ticks (optional) along the semicircle -----
    if (showTicks && tickCount >= 2) {
      final tickPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke * 0.12
        ..strokeCap = StrokeCap.round
        ..color = tickColor;
      for (int i = 0; i < tickCount; i++) {
        final t = i / (tickCount - 1); // 0..1 inclusive
        final a = _startAngle + _sweep * t;
        final rOuter = radius + baseStroke * 0.10;
        final rInner = rOuter - baseStroke * 0.50;
        final p1 = Offset(cx + rInner * math.cos(a), cy + rInner * math.sin(a));
        final p2 = Offset(cx + rOuter * math.cos(a), cy + rOuter * math.sin(a));
        canvas.drawLine(p1, p2, tickPaint);
      }
    }

    // ----- Outer predicted ring — uses an *offset* radius -----
    // inward (younger) when delta<0; outward (older) when delta>0
    final outerRadius = radius + signedOffset;
    final outerRect = Rect.fromCircle(center: Offset(cx, cy), radius: outerRadius);

    // For visual “section” emphasis, we draw an active arc proportional to |norm|,
    // from left→right if older (bulge), or right→left if younger (dip), so the
    // user always sees a colored segment whose *thickness* already hints the delta.
    final activeFrac = math.max(0.1, norm * 0.85); // keep a minimum so tiny gains still look alive

    final bool older = delta > 0;
    final double a0 = older ? _startAngle : (_startAngle + _sweep * (1.0 - activeFrac));
    final double aSweep = _sweep * activeFrac;

    final outerPaintTrack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStroke
      ..strokeCap = StrokeCap.round
      ..color = outerColor.withOpacity(0.18);
    canvas.drawArc(outerRect, _startAngle, _sweep, false, outerPaintTrack);

    final outerPaintActive = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStroke
      ..strokeCap = StrokeCap.round
      ..color = outerColor;
    canvas.drawArc(outerRect, a0, aSweep, false, outerPaintActive);

    // Optional tip dot for emphasis when |delta|>~0
    if (norm > 0.01) {
      final tipAngle = older ? (a0 + aSweep) : a0;
      final tip = Offset(
        cx + outerRadius * math.cos(tipAngle),
        cy + outerRadius * math.sin(tipAngle),
      );
      final dot = Paint()..color = outerColor;
      canvas.drawCircle(tip, outerStroke * 0.22, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _DualRingPainter old) {
    return chronoAge != old.chronoAge ||
        vitalityAge != old.vitalityAge ||
        delta != old.delta ||
        norm != old.norm ||
        innerColor != old.innerColor ||
        outerColor != old.outerColor ||
        baseStroke != old.baseStroke ||
        outerStroke != old.outerStroke ||
        tickColor != old.tickColor ||
        showTicks != old.showTicks ||
        tickCount != old.tickCount ||
        signedOffset != old.signedOffset;
  }
}

class _CenterLabels extends StatelessWidget {
  const _CenterLabels({
    required this.chronoAge,
    required this.vitalityAge,
    required this.delta,
    required this.labelStyle,
    required this.deltaLabelStyle,
  });

  final double chronoAge;
  final double vitalityAge;
  final double delta;
  final TextStyle labelStyle;
  final TextStyle deltaLabelStyle;

  @override
  Widget build(BuildContext context) {
    final younger = delta < 0;
    final deltaText = younger
        ? '+${(-delta).toStringAsFixed(1)} healthy years'
        : '${delta.toStringAsFixed(1)} years older';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(chronoAge.toStringAsFixed(0), style: labelStyle),
          const SizedBox(height: 4),
          Text('Your Age', style: deltaLabelStyle),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (younger ? const Color(0xFF24A699) : const Color(0xFFF6B56B)).withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: younger ? const Color(0xFF24A699) : const Color(0xFFF6B56B),
                width: 1,
              ),
            ),
            child: Text(
              deltaText,
              style: deltaLabelStyle.copyWith(
                color: younger ? const Color(0xFF24A699) : const Color(0xFFBF4A4A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('Vitality: ${vitalityAge.toStringAsFixed(1)}', style: deltaLabelStyle),
        ],
      ),
    );
  }
}

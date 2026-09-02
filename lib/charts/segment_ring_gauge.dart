// lib/charts/segment_ring_gauge.dart
//
// Segmented circular gauge with REAL gaps and crisp rectangular bars.
// Direction is controlled via `counterClockwise`.
// Head segment emphasis and optional headColorOverride are supported.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class SegmentRingGauge extends StatelessWidget {
  const SegmentRingGauge({
    super.key,
    required this.progress01,           // 0..1 magnitude of fill on the usable arc
    this.size = 180,
    this.ringThickness = 20,
    this.segments = 36,                 // ≈ segments on the usable arc
    this.gapFraction = 0.24,
    this.gapPadRadians = 0.006,         // extra pad per side; prevents touching
    this.unfilledTailFraction = 0.12,   // portion that never fills (but can show ghost pills)
    this.minActiveSegments = 2,
    this.colors,
    this.trackColor = const Color(0xFFE8EBF0),
    this.trackColorDark,
    this.shadow = true,

    // Direction
    this.counterClockwise = false,

    // Edges (subtle underlay under ACTIVE segments only)
    this.showEdges = true,
    this.edgeDarken = const Color(0x22000000),

    // Borders (active + inactive)
    this.boldBorders = true,
    this.borderWidth = 3.0,
    this.borderColorActive = const Color(0x33000000),
    this.borderColorInactive = const Color(0x1A000000),

    // Tail visualization
    this.showTailSegments = true,

    // Head (last filled segment) emphasis
    this.emphasizeHead = true,
    this.headThicknessBoost = 2.0,      // extra px added to ringThickness for head fill/edges
    this.headBorderBoost = 1.0,         // extra px added to border stroke width on head
    this.headShadowBoost = 0.05,        // extra shadow opacity added on head
    this.headBorderColorActive,         // optional: override active border color for head
    this.headEdgeDarken,                // optional: override edge color for head
    this.headColorOverride,             // exact color for head fill

    this.center,
  });

  final double progress01;
  final double size;
  final double ringThickness;
  final int segments;                   // usable-arc segment count (legacy)
  final double gapFraction;
  final double gapPadRadians;
  final double unfilledTailFraction;    // 0..1
  final int minActiveSegments;

  final List<Color>? colors;
  final Color trackColor;
  final Color? trackColorDark;
  final bool shadow;

  // Direction
  final bool counterClockwise;

  // Edge (active only)
  final bool showEdges;
  final Color edgeDarken;

  // Borders (active + inactive)
  final bool boldBorders;
  final double borderWidth;
  final Color borderColorActive;
  final Color borderColorInactive;

  // Tail visualization
  final bool showTailSegments;

  // Head emphasis
  final bool emphasizeHead;
  final double headThicknessBoost;
  final double headBorderBoost;
  final double headShadowBoost;
  final Color? headBorderColorActive;
  final Color? headEdgeDarken;

  /// exact color to use for the head (last active) segment's fill.
  final Color? headColorOverride;

  final Widget? center;

  // Default band: Deep Orange → Soft Amber → Light Green → Clean Green.
  static const List<Color> _defaultBand = <Color>[
    Color(0xFFD9822B),
    Color(0xFFF6B56B),
    Color(0xFFA3D9A5),
    Color(0xFF2FA36B),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = (colors == null || colors!.isEmpty) ? _defaultBand : colors!;
    final p = progress01.isFinite ? progress01.clamp(0.0, 1.0) : 0.0;

    final brightness = Theme.of(context).brightness;
    final effectiveTrack =
    (brightness == Brightness.dark && trackColorDark != null)
        ? trackColorDark!
        : trackColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _SegmentRingPainter(
              progress01: p,
              ringThickness: ringThickness,
              segmentsUsable: segments.clamp(6, 144),
              gapFraction: gapFraction.clamp(0.0, 0.45),
              gapPadRadians: gapPadRadians.clamp(0.0, 0.05),
              unfilledTailFraction: unfilledTailFraction.clamp(0.0, 0.45),
              minActiveSegments: minActiveSegments.clamp(0, 8),
              palette: palette,
              trackColor: effectiveTrack,
              shadow: shadow,
              // Direction
              counterClockwise: counterClockwise,
              showEdges: showEdges,
              edgeDarken: edgeDarken,
              boldBorders: boldBorders,
              borderWidth: borderWidth,
              borderColorActive: borderColorActive,
              borderColorInactive: borderColorInactive,
              showTailSegments: showTailSegments,
              emphasizeHead: emphasizeHead,
              headThicknessBoost: headThicknessBoost,
              headBorderBoost: headBorderBoost,
              headShadowBoost: headShadowBoost,
              headBorderColorActive: headBorderColorActive,
              headEdgeDarken: headEdgeDarken,
              headColorOverride: headColorOverride,
            ),
          ),
          if (center != null) Center(child: center!),
        ],
      ),
    );
  }
}

class _SegmentRingPainter extends CustomPainter {
  _SegmentRingPainter({
    required this.progress01,
    required this.ringThickness,
    required this.segmentsUsable,
    required this.gapFraction,
    required this.gapPadRadians,
    required this.unfilledTailFraction,
    required this.minActiveSegments,
    required this.palette,
    required this.trackColor,
    required this.shadow,
    // Direction
    required this.counterClockwise,
    required this.showEdges,
    required this.edgeDarken,
    required this.boldBorders,
    required this.borderWidth,
    required this.borderColorActive,
    required this.borderColorInactive,
    required this.showTailSegments,
    required this.emphasizeHead,
    required this.headThicknessBoost,
    required this.headBorderBoost,
    required this.headShadowBoost,
    required this.headBorderColorActive,
    required this.headEdgeDarken,
    required this.headColorOverride,
  });

  final double progress01;
  final double ringThickness;
  final int segmentsUsable;         // number of segments on the usable arc
  final double gapFraction;
  final double gapPadRadians;
  final double unfilledTailFraction;
  final int minActiveSegments;
  final List<Color> palette;
  final Color trackColor;
  final bool shadow;

  // Direction
  final bool counterClockwise;

  final bool showEdges;
  final Color edgeDarken;

  final bool boldBorders;
  final double borderWidth;
  final Color borderColorActive;
  final Color borderColorInactive;

  final bool showTailSegments;

  // head
  final bool emphasizeHead;
  final double headThicknessBoost;
  final double headBorderBoost;
  final double headShadowBoost;
  final Color? headBorderColorActive;
  final Color? headEdgeDarken;

  final Color? headColorOverride;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final radius = math.min(cx, cy) - ringThickness / 2;

    final usableFrac = 1.0 - unfilledTailFraction;
    final totalSegmentsFull =
    math.max(segmentsUsable, (segmentsUsable / usableFrac).round());
    final usableSegments = (totalSegmentsFull * usableFrac).round();

    const baseStart = -math.pi / 2; // top/North
    final rawSegAngle = (2 * math.pi) / totalSegmentsFull;
    final gapAngle = rawSegAngle * gapFraction;
    final baseSweep = math.max(0.0, rawSegAngle - gapAngle);
    final sweepAngle = math.max(0.0, baseSweep - 2 * gapPadRadians);

    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    Color colorForIndex(int i) {
      if (i >= usableSegments) return trackColor;
      if (palette.length == 1) return palette.first;
      final t = i / math.max(1, usableSegments - 1);
      final scaled = t * (palette.length - 1);
      final lo = scaled.floor();
      final hi = math.min(palette.length - 1, lo + 1);
      final k = scaled - lo;
      return Color.lerp(palette[lo], palette[hi], k) ?? palette.last;
    }

    // Paint defs
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringThickness
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true
      ..color = trackColor;

    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringThickness
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringThickness
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true
      ..color = edgeDarken;

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringThickness
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = Colors.black.withOpacity(0.10);

    final borderPaintActive = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringThickness + borderWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true
      ..color = borderColorActive;

    final borderPaintInactive = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringThickness + borderWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true
      ..color = borderColorInactive;

    final double headRingThickness = ringThickness + headThicknessBoost;
    final headFillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = headRingThickness
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    final headEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = headRingThickness
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true
      ..color = (headEdgeDarken ?? edgeDarken);

    final headShadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = headRingThickness
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = Colors.black.withOpacity(0.10 + headShadowBoost);

    final headBorderPaintActive = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = headRingThickness + borderWidth + headBorderBoost
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true
      ..color = (headBorderColorActive ?? borderColorActive);

    // 1) Track around FULL circle (background ring)
    for (int i = 0; i < totalSegmentsFull; i++) {
      final a0 = baseStart + (i * rawSegAngle) + (gapAngle / 2);
      final sweep = showTailSegments ? baseSweep : (i < usableSegments ? baseSweep : 0.0);
      if (sweep > 0) {
        canvas.drawArc(arcRect, a0, sweep, false, trackPaint);
      }
    }

    // 2) Active segments within usable arc
    final rawActive = (progress01 * usableSegments).clamp(0.0, usableSegments.toDouble());
    final whole = rawActive.floor();
    final feather = rawActive - whole;
    final activeWhole = math.max(whole, minActiveSegments).clamp(0, usableSegments);

    // Head index
    int headIndex;
    if (feather > 1e-6 && activeWhole < usableSegments) {
      headIndex = activeWhole;
    } else {
      headIndex = math.max(0, activeWhole - 1);
    }

    // Start angle helper honoring direction.
    double segStartFor(int i) {
      if (!counterClockwise) {
        // Clockwise: grow from North → right side
        return baseStart + (i * rawSegAngle) + (gapAngle / 2) + gapPadRadians;
      } else {
        // Counter-clockwise: grow from North → left side
        return baseStart - ((i + 1) * rawSegAngle) + (gapAngle / 2) + gapPadRadians;
      }
    }

    // 3) Borders (full ring), with head emphasis on active side
    if (boldBorders) {
      for (int i = 0; i < totalSegmentsFull; i++) {
        final a0 = segStartFor(i);
        final sweep = math.max(0.0, baseSweep - 2 * gapPadRadians);
        final isActiveish = i < activeWhole || (i == activeWhole && feather > 1e-6);
        final bool isHead = emphasizeHead && (i == headIndex) && i < usableSegments;

        if (i < usableSegments || showTailSegments) {
          if (isActiveish) {
            final paint = isHead ? headBorderPaintActive : borderPaintActive;
            canvas.drawArc(arcRect, a0, sweep, false, paint);
          } else {
            canvas.drawArc(arcRect, a0, sweep, false, borderPaintInactive);
          }
        }
      }
    }

    // 4) Active fills (edges → shadow → fill) inside usable arc only
    for (int i = 0; i < usableSegments; i++) {
      if (i > activeWhole) break;

      final segStart = segStartFor(i);
      final paletteColor = colorForIndex(i);

      final isWhole = i < activeWhole;
      final isFeather = i == activeWhole && feather > 1e-6 && activeWhole < usableSegments;
      final bool isHead = emphasizeHead &&
          ((isFeather && i == headIndex) || (isWhole && i == headIndex));

      final Paint ePaint = isHead ? headEdgePaint : edgePaint;
      final Paint sPaint = isHead ? headShadowPaint : shadowPaint;

      final Color baseFillColor =
      isHead && headColorOverride != null ? headColorOverride! : paletteColor;

      if (isWhole) {
        if (showEdges) canvas.drawArc(arcRect, segStart, sweepAngle, false, ePaint);
        if (shadow) {
          final sp = sPaint..color = sPaint.color;
          canvas.drawArc(arcRect, segStart, sweepAngle, false, sp);
        }
        final fPaint = (isHead ? headFillPaint : fillPaint)..color = baseFillColor;
        canvas.drawArc(arcRect, segStart, sweepAngle, false, fPaint);
      } else if (isFeather) {
        final alpha = (0.25 + 0.75 * feather).clamp(0.0, 1.0);
        final sweepFeather = sweepAngle * feather;

        if (showEdges) {
          final ep = ePaint..color = ePaint.color.withOpacity(alpha);
          canvas.drawArc(arcRect, segStart, sweepFeather, false, ep);
        }
        if (shadow) {
          final sp = sPaint..color =
          sPaint.color.withOpacity((sPaint.color.opacity) * alpha);
          canvas.drawArc(arcRect, segStart, sweepFeather, false, sp);
        }
        final Color featherColor = baseFillColor.withOpacity(alpha);
        final fPaint = (isHead ? headFillPaint : fillPaint)..color = featherColor;
        canvas.drawArc(arcRect, segStart, sweepFeather, false, fPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentRingPainter old) {
    return progress01 != old.progress01 ||
        ringThickness != old.ringThickness ||
        segmentsUsable != old.segmentsUsable ||
        gapFraction != old.gapFraction ||
        gapPadRadians != old.gapPadRadians ||
        unfilledTailFraction != old.unfilledTailFraction ||
        minActiveSegments != old.minActiveSegments ||
        palette != old.palette ||
        trackColor != old.trackColor ||
        shadow != old.shadow ||
        counterClockwise != old.counterClockwise ||
        showEdges != old.showEdges ||
        edgeDarken != old.edgeDarken ||
        boldBorders != old.boldBorders ||
        borderWidth != old.borderWidth ||
        borderColorActive != old.borderColorActive ||
        borderColorInactive != old.borderColorInactive ||
        showTailSegments != old.showTailSegments ||
        emphasizeHead != old.emphasizeHead ||
        headThicknessBoost != old.headThicknessBoost ||
        headBorderBoost != old.headBorderBoost ||
        headShadowBoost != old.headShadowBoost ||
        headBorderColorActive != old.headBorderColorActive ||
        headEdgeDarken != old.headEdgeDarken ||
        headColorOverride != old.headColorOverride;
  }
}

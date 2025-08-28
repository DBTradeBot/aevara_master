// lib/charts/delta_bar.dart
//
// DeltaBar — dual-line mini chart for Vitality Age vs Chronological Age
// - Pure CustomPainter (no extra deps)
// - Inputs: List<VitalityPoint> (date, vitalityAge, chronoAge)
// - Responsive, ADA-friendly contrast, respects theme
//
// Usage:
//   DeltaBar(
//     points: myHistoryList,        // unsorted ok; we'll sort by date
//     height: 180,
//     fixedMinY: globalMin,         // OPTIONAL: lock Y domain across ranges
//     fixedMaxY: globalMax,
//     showYAxisLabels: true,
//     yTickCount: 4,
//     // Interactive: tap/drag any point to see a bubble with date + value.
//   );

import 'dart:math' as math;
import 'dart:ui' show MaskFilter;
import 'package:flutter/material.dart';

class VitalityPoint {
  final DateTime date;
  final double vitalityAge;
  final double chronoAge;

  const VitalityPoint({
    required this.date,
    required this.vitalityAge,
    required this.chronoAge,
  });
}

enum DeltaBarValueLabelMode { none, last, all, interval }

class DeltaBar extends StatefulWidget {
  const DeltaBar({
    super.key,
    required this.points,
    this.height = 180,
    this.showAxes = true,
    this.showDots = true,
    this.padding = const EdgeInsets.fromLTRB(36, 12, 12, 22),
    this.fixedMinY,
    this.fixedMaxY,
    this.showYAxisLabels = true,
    this.yTickCount = 4,
    this.showXAxisLabels = true,
    this.valueLabelMode = DeltaBarValueLabelMode.none,
    this.valueLabelEvery = 3,
  });

  final List<VitalityPoint> points;
  final double height;
  final bool showAxes;
  final bool showDots;
  final EdgeInsets padding;

  /// If both provided, the Y-axis will be locked to this domain
  /// (useful to keep 14/30/60/90-day views visually comparable).
  final double? fixedMinY;
  final double? fixedMaxY;

  /// Axis & labels
  final bool showYAxisLabels;
  final int yTickCount;
  final bool showXAxisLabels;

  /// (Static) value labels near dots – default off. We now prefer interactive.
  final DeltaBarValueLabelMode valueLabelMode;
  final int valueLabelEvery; // used when mode==interval

  @override
  State<DeltaBar> createState() => _DeltaBarState();
}

class _DeltaBarState extends State<DeltaBar> {
  int? _selectedIndex;

  static const double _hitSlop = 18.0; // px radius for point picking

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Defensive: need at least 2 points to draw a line
    final data = [...widget.points]..sort((a, b) => a.date.compareTo(b.date));
    if (data.length < 2) {
      return _EmptyChart(label: 'Not enough data yet', height: widget.height);
    }

    // Raw min/max from data
    double minY = data.map((p) => math.min(p.vitalityAge, p.chronoAge)).reduce(math.min);
    double maxY = data.map((p) => math.max(p.vitalityAge, p.chronoAge)).reduce(math.max);
    if (!minY.isFinite || !maxY.isFinite) {
      return _EmptyChart(label: 'Data unavailable', height: widget.height);
    }

    // Apply fixed domain if provided, otherwise padded autoscale
    if (widget.fixedMinY != null && widget.fixedMaxY != null && widget.fixedMinY! < widget.fixedMaxY!) {
      minY = widget.fixedMinY!;
      maxY = widget.fixedMaxY!;
    } else {
      final span = (maxY - minY).abs();
      if (span < 0.25) {
        minY -= 0.5;
        maxY += 0.5;
      } else {
        final pad = span * 0.06;
        minY -= pad;
        maxY += pad;
      }
    }

    // X-range
    final start = data.first.date;
    final end = data.last.date;

    // Compute nice Y ticks
    final ticks = widget.showYAxisLabels
        ? _niceTicks(minY, maxY, math.max(2, widget.yTickCount))
        : const <double>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Helper to project a date to x for hit-testing (same as painter’s math)
        double xFor(DateTime d) {
          final chartWidth = width - widget.padding.horizontal;
          final t = d.difference(start).inMilliseconds /
              math.max(1, end.difference(start).inMilliseconds);
          return widget.padding.left + chartWidth * t.clamp(0.0, 1.0);
        }

        int? _nearestPoint(double x) {
          int bestIdx = -1;
          double bestDist = 1e9;
          for (var i = 0; i < data.length; i++) {
            final dx = (xFor(data[i].date) - x).abs();
            if (dx < bestDist) {
              bestDist = dx;
              bestIdx = i;
            }
          }
          if (bestIdx >= 0 && bestDist <= _hitSlop) return bestIdx;
          return null;
        }

        void _updateSelection(Offset localPos) {
          final idx = _nearestPoint(localPos.dx);
          if (idx != _selectedIndex) {
            setState(() => _selectedIndex = idx);
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _updateSelection(d.localPosition),
          onPanDown: (d) => _updateSelection(d.localPosition),
          onPanUpdate: (d) => _updateSelection(d.localPosition),
          onTapCancel: () => setState(() => _selectedIndex = null),
          onPanEnd: (_) => setState(() => _selectedIndex = null),
          child: SizedBox(
            height: widget.height,
            // CHANGED: draw chart + legend in the same fixed-height box so layout upstream doesn't shift
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _DeltaPainter(
                    theme: theme,
                    points: data,
                    minY: minY,
                    maxY: maxY,
                    start: start,
                    end: end,
                    showAxes: widget.showAxes,
                    showDots: widget.showDots,
                    // CHANGED: give a bit more room at bottom so X-axis labels clear the legend row
                    padding: widget.padding.copyWith(
                      bottom: widget.padding.bottom + 24,
                    ),
                    yTicks: ticks,
                    showXAxisLabels: widget.showXAxisLabels,
                    valueLabelMode: widget.valueLabelMode,
                    valueLabelEvery: math.max(1, widget.valueLabelEvery),
                    selectedIndex: _selectedIndex,
                  ),
                ),
                // CHANGED: legend pinned under X axis, inside the same box (no height change)
                Positioned(
                  left: 12,
                  bottom: 0,
                  child: _Legend(theme: theme),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// "Nice numbers" for axis labels (classic algo).
  static List<double> _niceTicks(double min, double max, int maxTicks) {
    if (!min.isFinite || !max.isFinite || min == max) return [min];
    final range = _niceNum(max - min, false);
    final d = _niceNum(range / (maxTicks - 1), true);
    final graphMin = (min / d).floorToDouble() * d;
    final graphMax = (max / d).ceilToDouble() * d;

    final ticks = <double>[];
    for (double v = graphMin; v <= graphMax + 1e-9; v += d) {
      final rounded = (v / d).roundToDouble() * d;
      ticks.add(double.parse(rounded.toStringAsFixed(2)));
    }
    return ticks;
  }

  static double _niceNum(double range, bool round) {
    final exponent = (math.log(range) / math.ln10).floorToDouble();
    final fraction = range / math.pow(10, exponent);
    double niceFraction;
    if (round) {
      if (fraction < 1.5) {
        niceFraction = 1;
      } else if (fraction < 3) {
        niceFraction = 2;
      } else if (fraction < 7) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    } else {
      if (fraction <= 1) {
        niceFraction = 1;
      } else if (fraction <= 2) {
        niceFraction = 2;
      } else if (fraction <= 5) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    }
    return niceFraction * math.pow(10, exponent);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final vitalityColor = theme.colorScheme.primary;
    final chronoColor = theme.colorScheme.outline; // subdued neutral

    Widget swatch(Color c) => Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );

    // kept as-is; Positioned(bottom:0,left:12) controls placement
    return Align(
      alignment: Alignment.topLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          swatch(vitalityColor),
          Text('Vitality Age', style: labelStyle),
          const SizedBox(width: 14),
          swatch(chronoColor),
          Text('Your age', style: labelStyle),
        ],
      ),
    );
  }
}

class _DeltaPainter extends CustomPainter {
  _DeltaPainter({
    required this.theme,
    required this.points,
    required this.minY,
    required this.maxY,
    required this.start,
    required this.end,
    required this.showAxes,
    required this.showDots,
    required this.padding,
    required this.yTicks,
    required this.showXAxisLabels,
    required this.valueLabelMode,
    required this.valueLabelEvery,
    required this.selectedIndex,
  });

  final ThemeData theme;
  final List<VitalityPoint> points;
  final double minY;
  final double maxY;
  final DateTime start;
  final DateTime end;
  final bool showAxes;
  final bool showDots;
  final EdgeInsets padding;

  final List<double> yTicks;
  final bool showXAxisLabels;
  final DeltaBarValueLabelMode valueLabelMode;
  final int valueLabelEvery;

  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final chart = Rect.fromLTWH(
      rect.left + padding.left,
      rect.top + padding.top,
      rect.width - padding.horizontal,
      rect.height - padding.vertical,
    );

    // Background grid + Y labels
    if (showAxes) {
      final gridColor = (theme.brightness == Brightness.dark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.05))
          .withOpacity(0.10);

      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;

      final labelStyle = TextStyle(
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
        fontSize: 11,
        height: 1.0,
      );

      // Y ticks & labels (nice numbers)
      for (final v in yTicks) {
        final dy = _yFor(v, chart);
        canvas.drawLine(Offset(chart.left, dy), Offset(chart.right, dy), gridPaint);

        final tp = _textPainter(_yLabel(v), labelStyle);
        // draw inside the plot, left-aligned
        tp.paint(canvas, Offset(chart.left - 8 - tp.width, dy - tp.height / 2));
      }
    }

    // Projectors
    double xFor(DateTime d) {
      final t = d.difference(start).inMilliseconds /
          math.max(1, end.difference(start).inMilliseconds);
      return chart.left + chart.width * t.clamp(0.0, 1.0);
    }

    // Paths
    final vitalityPath = Path();
    final chronoPath = Path();

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final vx = xFor(p.date);
      final vy = _yFor(p.vitalityAge, chart);
      final cx = vx;
      final cy = _yFor(p.chronoAge, chart);
      if (i == 0) {
        vitalityPath.moveTo(vx, vy);
        chronoPath.moveTo(cx, cy);
      } else {
        vitalityPath.lineTo(vx, vy);
        chronoPath.lineTo(cx, cy);
      }
    }

    // Chrono stroke
    final chronoPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..color = theme.colorScheme.outline;

    // Vitality glow (makes the line "pop")
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..color = theme.colorScheme.primary.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Vitality stroke
    final vitalityPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..color = theme.colorScheme.primary;

    // Draw lines (chrono first)
    canvas.drawPath(chronoPath, chronoPaint);
    canvas.drawPath(vitalityPath, glowPaint);
    canvas.drawPath(vitalityPath, vitalityPaint);

    // Dots
    if (showDots) {
      final dotVital = Paint()..color = theme.colorScheme.primary;
      final dotChrono = Paint()..color = theme.colorScheme.outline;
      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        final center = Offset(xFor(p.date), _yFor(p.vitalityAge, chart));
        final centerC = Offset(xFor(p.date), _yFor(p.chronoAge, chart));
        final rVital = (i == points.length - 1) ? 2.8 : 2.2; // emphasize last point
        canvas.drawCircle(center, rVital, dotVital);
        canvas.drawCircle(centerC, 1.8, dotChrono);
      }
    }

    // (Optional) static value labels — usually disabled now
    if (valueLabelMode != DeltaBarValueLabelMode.none) {
      final style = TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );
      for (int i = 0; i < points.length; i++) {
        final isLast = i == points.length - 1;
        final shouldDraw = switch (valueLabelMode) {
          DeltaBarValueLabelMode.last => isLast,
          DeltaBarValueLabelMode.all => true,
          DeltaBarValueLabelMode.interval => (i % valueLabelEvery == 0) || isLast,
          DeltaBarValueLabelMode.none => false,
        };
        if (!shouldDraw) continue;
        final p = points[i];
        final pos = Offset(xFor(p.date), _yFor(p.vitalityAge, chart));
        _bubble(canvas, pos, '${p.vitalityAge.toStringAsFixed(1)}', theme, chart,
            emphasized: false, elevation: 6);
      }
    }

    // Interactive selection bubble (tap/drag-to-inspect)
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < points.length) {
      final p = points[selectedIndex!];
      final pos = Offset(xFor(p.date), _yFor(p.vitalityAge, chart));

      // Draw hairline FIRST so the bubble sits on top of everything.
      final hair = Paint()
        ..color = theme.colorScheme.primary.withOpacity(0.25)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(pos.dx, chart.top), Offset(pos.dx, chart.bottom), hair);

      final label = '${_shortDate(p.date)} • ${p.vitalityAge.toStringAsFixed(1)}';
      _bubble(canvas, pos, label, theme, chart, emphasized: true, elevation: 10);
    }

    // X-axis labels: start / mid / end
    if (showXAxisLabels) {
      final textStyle = TextStyle(
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.85),
        fontSize: 11,
        height: 1.0,
      );
      final mid = DateTime.fromMillisecondsSinceEpoch(
          (start.millisecondsSinceEpoch + end.millisecondsSinceEpoch) ~/ 2);

      final startTP = _textPainter(_shortDate(start), textStyle);
      final midTP = _textPainter(_shortDate(mid), textStyle);
      final endTP = _textPainter(_shortDate(end), textStyle);

      final y = chart.bottom + 4;
      startTP.paint(canvas, Offset(chart.left, y));
      midTP.paint(canvas, Offset(chart.center.dx - midTP.width / 2, y));
      endTP.paint(canvas, Offset(chart.right - endTP.width, y));
    }
  }

  double _yFor(double y, Rect chart) {
    final t = (y - minY) / (maxY - minY);
    return chart.bottom - chart.height * t.clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant _DeltaPainter old) {
    return old.points != points ||
        old.minY != minY ||
        old.maxY != maxY ||
        old.start != start ||
        old.end != end ||
        old.showAxes != showAxes ||
        old.showDots != showDots ||
        old.padding != padding ||
        old.yTicks != yTicks ||
        old.showXAxisLabels != showXAxisLabels ||
        old.valueLabelMode != valueLabelMode ||
        old.valueLabelEvery != valueLabelEvery ||
        old.selectedIndex != selectedIndex;
  }

  TextPainter _textPainter(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return tp;
  }

  static String _shortDate(DateTime d) {
    // e.g., Aug 27
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  static String _yLabel(double v) => v.toStringAsFixed(0); // years as int

  void _bubble(
      Canvas canvas,
      Offset pos,
      String text,
      ThemeData theme,
      Rect chart, {
        bool emphasized = false,
        double elevation = 6, // visual “pop”
      }) {
    final style = TextStyle(
      color: theme.colorScheme.onSurface,
      fontSize: 11,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
    );

    final tp = _textPainter(text, style);
    const padH = 6.0;
    const padV = 3.0;
    final w = tp.width + padH * 2;
    final h = tp.height + padV * 2;

    // Try to place above; if too near top, place below.
    var left = (pos.dx - w / 2).clamp(chart.left, chart.right - w);
    var top = pos.dy - h - 6;
    if (top < chart.top) top = pos.dy + 6;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      const Radius.circular(8),
    );
    final path = Path()..addRRect(rrect);

    // Real card fill (opaque) so chart lines don't show through.
    final bg = theme.brightness == Brightness.dark
        ? theme.colorScheme.surface.withOpacity(0.98)
        : Colors.white;

    // Soft drop shadow for elevation.
    final shadowColor = Colors.black.withOpacity(
      theme.brightness == Brightness.dark ? 0.50 : 0.28,
    );
    canvas.drawShadow(path, shadowColor, elevation, false);

    // Fill + subtle border.
    final fillPaint = Paint()..color = bg;
    canvas.drawRRect(rrect, fillPaint);

    final border = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.08);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = border;
    canvas.drawRRect(rrect, borderPaint);

    // Text on top
    tp.paint(canvas, Offset(left + padH, top + padV));
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.label, required this.height});
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF243039)
            : const Color(0xFFF4F7FA),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.9),
        ),
      ),
    );
  }
}

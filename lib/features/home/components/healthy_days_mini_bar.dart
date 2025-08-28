// lib/features/home/components/healthy_days_mini_bar.dart
// Dynamic 30-slot mini bar that visualizes Healthy Days history.
// - Uses healthyDaysRiskSeriesProvider (real per-day risk_index series) when available:
//     • Height = (1 - risk) so healthier days are taller
//     • Colors: green (<0.45), amber (0.45..0.55), red (>0.55), gray (missing)
//     • Optional 7-day trend line over "healthiness"
// - Falls back to healthyDaysCountProvider with an animated strip.
// - Respects `dim` flag.
// - NEW: `todayFresh` gate. If false, the last slot (today) is rendered as "missing" (blank),
//        and we do not count it in totals/caption.
//
// Upgrades:
//  1) 50% baseline line (faint) for quick context.
//  2) Legend under caption: ● Healthy ● Borderline ● Not healthy.
//  3) Long-press a bar → bottom sheet with day details (date, % healthy, state).
//  4) Time ticks under chart: first / middle / last day.
//
// Title/icon are intentionally NOT rendered here; label from parent (HeroHeader).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../state/healthy_days_providers.dart';

class HealthyDaysMiniBar extends ConsumerWidget {
  const HealthyDaysMiniBar({
    super.key,
    this.dim = false,
    this.showTrend = true,
    this.todayFresh = false, // ← NEW
  });

  final bool dim;
  final bool showTrend;
  final bool todayFresh; // ← NEW

  static const _cHealthy = Color(0xFF24A699); // Fresh Teal
  static const _cWarn = Color(0xFFF6B56B); // Soft Amber
  static const _cBad = Color(0xFFBF4A4A); // Muted Red

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final countAV = ref.watch(healthyDaysCountProvider);
    final seriesAV = ref.watch(healthyDaysRiskSeriesProvider);

    int safeCount(int? v) => (v ?? 0).clamp(0, 30);

    // Precompute last-30 dates (oldest→newest) in LOCAL time so chart/labels align
    final now = DateTime.now();
    final last30Dates = List.generate(
      30,
          (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 29 - i)),
    );

    // Avoid null-aware operator warning: compute local series & showTrend flag
    final series = seriesAV.asData?.value;
    final showTrendNow = showTrend && (series != null && series.isNotEmpty);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MiniBarFullWidth(
          valuesRisk01: series, // List<double?> (0..1 risk), null if not ready
          countHealthy: countAV.maybeWhen(data: safeCount, orElse: () => 0),
          showTrend: showTrendNow,
          dim: dim,
          dates: last30Dates,
          todayFresh: todayFresh, // ← NEW
        ),
        const SizedBox(height: 8),

        // Caption "X / 30" — hide if today is not fresh
        Center(
          child: (todayFresh == false)
              ? Text('—', style: theme.textTheme.bodySmall)
              : countAV.maybeWhen(
            data: (int? v) {
              final hd = safeCount(v);
              return Text(hd > 0 ? '$hd / 30' : '—', style: theme.textTheme.bodySmall);
            },
            orElse: () => Text('—', style: theme.textTheme.bodySmall),
          ),
        ),

        // Tiny legend (kept subtle)
        const SizedBox(height: 6),
        _LegendRow(),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: dim ? 0.82 : 1.0,
      child: content,
    );
  }
}

/* ───────────────────────── LayoutBuilder wrapper (full-width) ───────────────────────── */

class _MiniBarFullWidth extends StatelessWidget {
  const _MiniBarFullWidth({
    required this.valuesRisk01,
    required this.countHealthy,
    required this.showTrend,
    required this.dim,
    required this.dates,
    required this.todayFresh, // ← NEW
  });

  final List<double?>? valuesRisk01;
  final int countHealthy;
  final bool showTrend;
  final bool dim;
  final List<DateTime> dates; // length 30, oldest→newest
  final bool todayFresh; // ← NEW

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const int nBars = 30;
        const double barGap = 4;
        const double height = 48;
        const double radius = 2;

        // Inner padding for the container background (subtle)
        const double padH = 8;
        const double padV = 6;

        final available =
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 320) - (padH * 2);
        final barWidth =
        ((available - (nBars - 1) * barGap) / nBars).clamp(3.0, 16.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MiniBarContainer(
              valuesRisk01: valuesRisk01,
              countHealthy: countHealthy,
              showTrend: showTrend,
              dim: dim,
              height: height,
              barWidth: barWidth,
              barGap: barGap,
              radius: radius,
              padH: padH,
              padV: padV,
              dates: dates,
              todayFresh: todayFresh, // ← NEW
            ),
            const SizedBox(height: 6),
            _TimeTicks(dates: dates, padH: padH),
          ],
        );
      },
    );
  }
}

/* ───────────────────────── Chart Container & internals ───────────────────────── */

class _MiniBarContainer extends StatelessWidget {
  const _MiniBarContainer({
    required this.valuesRisk01,
    required this.countHealthy,
    required this.showTrend,
    required this.dim,
    required this.height,
    required this.barWidth,
    required this.barGap,
    required this.radius,
    required this.padH,
    required this.padV,
    required this.dates,
    required this.todayFresh, // ← NEW
  });

  final List<double?>? valuesRisk01;
  final int countHealthy;
  final bool showTrend;
  final bool dim;

  final double height;
  final double barWidth;
  final double barGap;
  final double radius;
  final double padH;
  final double padV;

  final List<DateTime> dates; // oldest→newest, len 30
  final bool todayFresh; // ← NEW

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.surfaceVariant.withOpacity(0.5);

    final series = valuesRisk01;
    final seriesProvided = series != null && series.isNotEmpty;

    // Compute totals for semantics, with today excluded when not fresh
    int totalDays = seriesProvided ? series.where((e) => e != null).length : 30;
    int healthyCountLocal = seriesProvided
        ? series.where((r) => r != null && r! < 0.5).length
        : countHealthy.clamp(0, 30);

    if (!todayFresh) {
      if (seriesProvided && series!.isNotEmpty) {
        final last = series.last;
        if (last != null) {
          totalDays = math.max(0, totalDays - 1);
          if (last < 0.5) healthyCountLocal = math.max(0, healthyCountLocal - 1);
        }
      } else {
        // fallback path mirrors the bars-row shift
        totalDays = 29;
        if (healthyCountLocal > 0) healthyCountLocal -= 1;
      }
    }

    return Semantics(
      label: 'Healthy Days chart',
      value: '$healthyCountLocal of $totalDays in last 30',
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              // 50% baseline (faint)
              _BaselineLine(
                height: height,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
                dash: 6,
                gap: 6,
              ),

              // Trend line over "healthiness" = 1 - risk
              if (seriesProvided && showTrend)
                _TrendLine(
                  valuesHealth01: _movingAverage(
                    series
                        .map((r) => r == null ? null : (1.0 - r).clamp(0.0, 1.0))
                        .toList(),
                    7,
                  ).map((e) => e ?? 0).toList(),
                  height: height,
                  barWidth: barWidth,
                  barSpacing: barGap,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.66),
                  strokeWidth: 1.2,
                ),

              _BarsRow(
                valuesRisk01: valuesRisk01,
                countHealthy: countHealthy,
                height: height,
                barWidth: barWidth,
                barSpacing: barGap,
                radius: radius,
                dim: dim,
                dates: dates,
                todayFresh: todayFresh, // ← NEW
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simple moving average on 0..1 with nulls skipped; same length, null when no window yet.
  static List<double?> _movingAverage(List<double?> vals, int win) {
    if (vals.isEmpty) return const [];
    win = win.clamp(1, vals.length);
    final out = <double?>[];
    final buf = <double>[];
    for (int i = 0; i < vals.length; i++) {
      final v = vals[i];
      if (v != null) buf.add(v);
      if (buf.length > win) buf.removeAt(0);
      if (buf.isEmpty) {
        out.add(null);
      } else {
        out.add(buf.reduce((a, b) => a + b) / buf.length);
      }
    }
    return out;
  }
}

class _BarsRow extends StatefulWidget {
  const _BarsRow({
    required this.valuesRisk01, // risk series (0..1)
    required this.countHealthy,
    required this.height,
    required this.barWidth,
    required this.barSpacing,
    required this.radius,
    required this.dim,
    required this.dates,
    required this.todayFresh, // ← NEW
  });

  final List<double?>? valuesRisk01;
  final int countHealthy;
  final double height;
  final double barWidth;
  final double barSpacing;
  final double radius;
  final bool dim;
  final List<DateTime> dates; // len 30, oldest→newest
  final bool todayFresh; // ← NEW

  @override
  State<_BarsRow> createState() => _BarsRowState();
}

class _BarsRowState extends State<_BarsRow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _dur = Duration(milliseconds: 650);
  static const _staggerMs = 22;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _dur)..forward();
  }

  @override
  void didUpdateWidget(covariant _BarsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valuesRisk01 != widget.valuesRisk01 ||
        oldWidget.countHealthy != widget.countHealthy ||
        oldWidget.barWidth != widget.barWidth ||
        oldWidget.todayFresh != widget.todayFresh) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorFor(BuildContext ctx, double? risk) {
    if (risk == null) return Theme.of(ctx).disabledColor.withOpacity(0.25);
    if (risk < 0.45) return HealthyDaysMiniBar._cHealthy;
    if (risk <= 0.55) return HealthyDaysMiniBar._cWarn;
    return HealthyDaysMiniBar._cBad;
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.valuesRisk01;
    final seriesProvided = values != null && values.isNotEmpty;

    const nBars = 30;

    final bars = List<Widget>.generate(nBars, (iFromLeft) {
      final i = iFromLeft;
      final bool isTodaySlot = (i == nBars - 1);

      double? risk;
      double height01;

      if (seriesProvided) {
        // Show last up-to-30 values, oldest→newest left→right
        final start = (values!.length - nBars).clamp(0, values.length);
        final idx = start + i;
        risk = (idx < values.length) ? values[idx] : null;
        height01 = (risk == null) ? 0.08 : (1.0 - risk).clamp(0.0, 1.0);

        // Mask today's slot when not fresh
        if (!widget.todayFresh && isTodaySlot) {
          risk = null;
          height01 = 0.0;
        }
      } else {
        // Fallback: right-align "healthy" blocks based on the count
        int healthyCount = widget.countHealthy.clamp(0, nBars);

        // If today isn’t fresh, we keep the same total bars but do not fill the last slot.
        if (!widget.todayFresh && healthyCount > 0) {
          healthyCount = healthyCount - 1; // shift one left visually
        }

        final rightStart = nBars - healthyCount;
        final isHealthy = i >= rightStart;

        if (!widget.todayFresh && isTodaySlot) {
          risk = null;
          height01 = 0.0;
        } else {
          risk = isHealthy ? 0.25 : 0.75; // proxy to drive color/tooltips
          height01 = isHealthy ? 0.92 : 0.25;
        }
      }

      final color = _colorFor(context, risk);

      final startT = (i * _staggerMs) / _dur.inMilliseconds;
      final endT = math.min(1.0, startT + 0.6);
      final curved = CurvedAnimation(
        parent: _controller,
        curve: Interval(startT, endT, curve: Curves.easeOutCubic),
      );

      final targetH = (height01 * widget.height).clamp(1.0, widget.height);

      final date = widget.dates[i]; // aligns with oldest→newest

      return AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          final h = targetH * curved.value;
          final df = DateFormat.MMMd(); // e.g., "Aug 26"

          String tooltip;
          if (risk == null) {
            tooltip = '${df.format(date)} — Missing';
          } else {
            final ph = ((1 - risk) * 100);
            final status = (risk < 0.5) ? 'Healthy' : 'Not healthy';
            tooltip = '${df.format(date)} — $status (${ph.toStringAsFixed(0)}% healthy)';
          }

          return Padding(
            padding: EdgeInsets.only(right: i == nBars - 1 ? 0 : widget.barSpacing),
            child: Tooltip(
              message: tooltip,
              child: GestureDetector(
                onLongPress: () => _showDayDetails(context, date, risk),
                child: Container(
                  width: widget.barWidth,
                  height: h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(widget.radius),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      children: bars,
    );
  }

  void _showDayDetails(BuildContext context, DateTime date, double? risk) {
    final dfLong = DateFormat.yMMMEd(); // e.g., "Mon, Aug 26, 2025"
    final title = dfLong.format(date);

    late final String status;
    late final String pct;

    if (risk == null) {
      status = 'Missing';
      pct = '—';
    } else {
      final r = risk; // non-null inside this branch
      status = (r < 0.5) ? 'Healthy' : 'Not healthy';
      pct = '${((1 - r) * 100).toStringAsFixed(0)}%';
    }

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Status: ', style: textTheme.bodyMedium),
                  Text(status, style: textTheme.bodyMedium),
                  const SizedBox(width: 16),
                  Text('Healthy %: ', style: textTheme.bodyMedium),
                  Text(pct, style: textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Tip: connect a device or add today’s sleep, recovery, and steps to improve this.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                  const Spacer(),
                  // Placeholder for deeper drill (hook to Insights/Data Hub)
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      // TODO: navigate to /insights or open a metric details sheet
                    },
                    child: const Text('View insights'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ───────────────────────────── Baseline / Trend Painters ───────────────────────── */

class _BaselineLine extends StatelessWidget {
  const _BaselineLine({
    required this.height,
    required this.color,
    this.dash = 0,
    this.gap = 0,
  });

  final double height;
  final Color color;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _BaselinePainter(height: height, color: color, dash: dash, gap: gap),
    );
  }
}

class _BaselinePainter extends CustomPainter {
  _BaselinePainter({
    required this.height,
    required this.color,
    this.dash = 0,
    this.gap = 0,
  });

  final double height;
  final Color color;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final double y = height * 0.5; // 50% healthiness
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    if (dash > 0 && gap > 0) {
      double x = 0;
      while (x < size.width) {
        final double x2 = math.min(x + dash, size.width);
        canvas.drawLine(Offset(x, y), Offset(x2, y), paint);
        x += dash + gap;
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BaselinePainter oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.color != color ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap;
  }
}

class _TrendLine extends StatelessWidget {
  const _TrendLine({
    required this.valuesHealth01, // 0..1; nulls already replaced with 0 by caller
    required this.height,
    required this.barWidth,
    required this.barSpacing,
    required this.color,
    required this.strokeWidth,
  });

  final List<double> valuesHealth01;
  final double height;
  final double barWidth;
  final double barSpacing;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final int gaps = math.max(0, valuesHealth01.length - 1);
    final double widthPx = (valuesHealth01.length * barWidth) + (gaps * barSpacing);
    return CustomPaint(
      size: Size(widthPx, height),
      painter: _TrendPainter(
        valuesHealth01: valuesHealth01,
        height: height,
        barWidth: barWidth,
        barSpacing: barSpacing,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.valuesHealth01,
    required this.height,
    required this.barWidth,
    required this.barSpacing,
    required this.color,
    required this.strokeWidth,
  });

  final List<double> valuesHealth01; // 0..1 healthiness
  final double height;
  final double barWidth;
  final double barSpacing;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (valuesHealth01.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < valuesHealth01.length; i++) {
      final double x = i * (barWidth + barSpacing) + barWidth / 2;
      final double y = height * (1 - valuesHealth01[i].clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.valuesHealth01 != valuesHealth01 ||
        oldDelegate.height != height ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.barSpacing != barSpacing ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/* ───────────────────────────── Legend & Time Ticks ───────────────────────── */

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.1);
    Widget dot(Color c) =>
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(HealthyDaysMiniBar._cHealthy),
        const SizedBox(width: 6),
        Text('Healthy', style: style),
        const SizedBox(width: 12),
        dot(HealthyDaysMiniBar._cWarn),
        const SizedBox(width: 6),
        Text('Borderline', style: style),
        const SizedBox(width: 12),
        dot(HealthyDaysMiniBar._cBad),
        const SizedBox(width: 6),
        Text('Not healthy', style: style),
      ],
    );
  }
}

class _TimeTicks extends StatelessWidget {
  const _TimeTicks({required this.dates, required this.padH});

  final List<DateTime> dates; // len 30, oldest→newest
  final double padH;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.MMMd(); // "Aug 1"
    final first = dates.first;
    final middle = dates[dates.length ~/ 2];
    final last = dates.last;

    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padH),
      child: Row(
        children: [
          Text(df.format(first), style: style),
          Expanded(child: Center(child: Text(df.format(middle), style: style))),
          Text(df.format(last), style: style),
        ],
      ),
    );
  }
}

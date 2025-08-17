// lib/widgets/dashboard/synced_metrics_row.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aevara_master/theme/aevara_theme.dart';

class SyncedMetricsRow extends StatelessWidget {
  // Sleep
  final double? sleepHours;
  final double sleepGoalHours;

  // Recovery (0..100 readiness already computed)
  final int? readinessScore;

  // Activity
  final int? steps;
  final int stepsGoal;

  // Cardio Fitness
  final double? vo2max;               // if available
  final double? fitnessAge;           // alternative
  final double? baselineFitnessAge;   // optional for delta display

  const SyncedMetricsRow({
    super.key,
    this.sleepHours,
    required this.sleepGoalHours,
    this.readinessScore,
    this.steps,
    required this.stepsGoal,
    this.vo2max,
    this.fitnessAge,
    this.baselineFitnessAge,
  });

  // ---- helpers --------------------------------------------------------------
  static String _fmtHours(double v) =>
      '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}h';

  static String _fmtSteps(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    return v.toString();
  }

  static Color _byGoal(BuildContext ctx, double ratio) {
    final aev = ctx.aevara;
    if (ratio >= 1.0) return aev.success;
    if (ratio >= 0.7) return aev.accent1;
    if (ratio >= 0.5) return aev.warning;
    return aev.error;
  }

  static Color _byReadiness(BuildContext ctx, int? r) {
    final aev = ctx.aevara;
    if (r == null) return aev.secondaryText;
    if (r >= 80) return aev.success;
    if (r >= 60) return aev.accent1;
    if (r >= 40) return aev.warning;
    return aev.error;
  }

  @override
  Widget build(BuildContext context) {
    final radius = context.aevara.radius;

    // Precompute display specifics
    final sleepRatio = (sleepHours != null && sleepGoalHours > 0)
        ? (sleepHours! / sleepGoalHours.clamp(0.1, 24.0))
        : 0.0;

    final stepsRatio = (steps != null && stepsGoal > 0)
        ? steps!.toDouble() / stepsGoal
        : 0.0;

    // Cardio main + delta
    final cardioValue = (vo2max != null)
        ? vo2max!.toStringAsFixed(1)
        : (fitnessAge != null ? '${fitnessAge!.toStringAsFixed(0)}y' : '--');

    final cardioSublabel = (vo2max != null)
        ? 'VO₂max'
        : (baselineFitnessAge != null && fitnessAge != null
        ? 'vs ${baselineFitnessAge!.toStringAsFixed(0)}'
        : '');

    return Row(
      children: [
        // Sleep
        Expanded(
          child: _SyncedMetricCard(
            radius: radius,
            icon: Icons.bedtime_rounded,
            iconColor: _byGoal(context, sleepRatio),
            label: 'Sleep',
            value: sleepHours != null ? _fmtHours(sleepHours!) : '--',
            sublabel: 'vs ${sleepGoalHours.toStringAsFixed(1)}h',
          ),
        ),
        const SizedBox(width: 8),

        // Recovery
        Expanded(
          child: _SyncedMetricCard(
            radius: radius,
            icon: Icons.monitor_heart,
            iconColor: _byReadiness(context, readinessScore),
            label: 'Recovery',
            value: readinessScore != null ? '${readinessScore!.clamp(0, 100)}' : '--',
            sublabel: '/100',
          ),
        ),
        const SizedBox(width: 8),

        // Activity
        Expanded(
          child: _SyncedMetricCard(
            radius: radius,
            icon: Icons.directions_walk_rounded,
            iconColor: _byGoal(context, stepsRatio),
            label: 'Activity',
            value: steps != null ? _fmtSteps(steps!) : '--',
            sublabel: '${(stepsRatio * 100).clamp(0, 999).toStringAsFixed(0)}% goal',
          ),
        ),
        const SizedBox(width: 8),

        // Cardio Fitness
        Expanded(
          child: _SyncedMetricCard(
            radius: radius,
            icon: Icons.show_chart_rounded,
            iconColor: context.aevara.info,
            label: 'Cardio',
            value: cardioValue,
            sublabel: cardioSublabel,
          ),
        ),
      ],
    );
  }
}

class _SyncedMetricCard extends StatelessWidget {
  final double radius;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;      // main number (e.g., "6.9h", "82", "8.5k", "42.0")
  final String sublabel;   // small helper (e.g., "vs 7.5h", "/100", "85% goal", "VO₂max")

  const _SyncedMetricCard({
    required this.radius,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sublabel,
  });

  double _clamp(double v, double minV, double maxV) =>
      math.max(minV, math.min(maxV, v));

  @override
  Widget build(BuildContext context) {
    final aev = context.aevara;

    // Consistent card height with comfortable internal spacing
    final h = 78.0;

    // Fixed-width slot for the value+sublabel so all four cards render uniformly.
    const double kValueSlotWidth = 72.0;

    final padV     = _clamp(h * 0.08, 4, 10);
    final iconOuter= _clamp(h * 0.34, 18, 32);
    final iconGlyph= _clamp(iconOuter * 0.66, 12, 20);
    final labelFs  = _clamp(h * 0.18, 12, 14.5);

    const iconFlex   = 320;
    const spacerFlex = 50;
    const valueFlex  = 360;
    const labelFlex  = 220;

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(aev.radius),
        border: Border.all(color: Colors.black12.withOpacity(0.08), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: padV),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Icon
          Expanded(
            flex: iconFlex,
            child: Center(
              child: Container(
                width: iconOuter,
                height: iconOuter,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: iconGlyph, color: iconColor),
              ),
            ),
          ),

          const Expanded(flex: spacerFlex, child: SizedBox.shrink()),

          // Value + sublabel in a fixed-width slot with one FittedBox
          Expanded(
            flex: valueFlex,
            child: Center(
              child: SizedBox(
                width: kValueSlotWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18, // base; will scale down uniformly if needed
                          color: Colors.black87,
                          height: 1.0,
                        ),
                      ),
                      if (sublabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            sublabel,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: aev.secondaryText,
                              height: 1.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Expanded(flex: spacerFlex, child: SizedBox.shrink()),

          // Label
          Expanded(
            flex: labelFlex,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: labelFs,
                  fontWeight: FontWeight.w500,
                  color: aev.primaryText,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

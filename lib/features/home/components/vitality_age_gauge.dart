// lib/features/home/components/vitality_age_gauge.dart
//
// Vitality Age Gauge — minimal, centered
// Self-defends: shows '—' unless BOTH hasVitality && showTodayScore.
// Tapping the gauge opens VitalityInfoSheet (even when gated).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../charts/segment_ring_gauge.dart';
import '../../../state/daily_providers.dart';
import '../sheets/vitality_info_sheet.dart';

class VitalityAgeGauge extends ConsumerWidget {
  const VitalityAgeGauge({
    super.key,
    this.vitalityAge,
    this.chronologicalAge,
    this.size = 190,
    this.showBlurb = false, // kept for API stability; ignored
  });

  final double? vitalityAge;
  final double? chronologicalAge;
  final double size;
  final bool showBlurb;

  // Mapping constants (−4..+4 years span)
  static const double _kSpanYears = 8.0;
  static const double _kMaxGain = 4.0;

  static const double _kMinVisualOffset = 0.06;
  static const double _kEpsDelta = 0.05;

  static const int _segments = 56;
  static const double _gapFraction = 0.36;
  static const double _gapPad = 0.008;
  static const double _tailFrac = 0.12;
  static const int _minActiveSegs = 2;

  static const List<Color> _palette = [
    Color(0xFFBF4A4A), // Error
    Color(0xFFF6B56B), // Warning
    Color(0xFF24A699), // Success
  ];

  static Color _colorAtProgress(List<Color> palette, double t) {
    if (palette.isEmpty) return const Color(0xFF24A699);
    final p = t.clamp(0.0, 1.0);
    if (palette.length == 1) return palette.first;
    final scaled = p * (palette.length - 1);
    final lo = scaled.floor();
    final hi = (lo + 1).clamp(0, palette.length - 1);
    final frac = scaled - lo;
    return Color.lerp(palette[lo], palette[hi], frac) ?? palette.last;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(vitalityGaugeVMProvider);

    return vmAsync.when(
      loading: () {
        const progress01 = 0.5;
        final headColor = _colorAtProgress(_palette, progress01);
        return Center(
          child: _GaugeCore(
            size: size,
            progress01: progress01,
            vAge: double.nan,
            cAge: double.nan,
            palette: _palette,
            headColor: headColor,
          ),
        );
      },
      error: (e, st) => Center(
        child: Text('—', style: Theme.of(context).textTheme.bodyMedium),
      ),
      data: (vm) {
        final bool canShow = vm.hasVitality && vm.showTodayScore;

        if (!canShow) {
          const progress01 = 0.5;
          final headColor = _colorAtProgress(_palette, progress01);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              HapticFeedback.lightImpact();

              // Pull up to 90d; the sheet’s internal toggle will slice to 14/30/60/90.
              final hist = await ref.read(vitalityHistoryProvider(90).future);

              VitalityInfoSheet.show(
                context,
                vitalityAge: null,
                chronologicalAge: null,
                healthyYears: null,
                scores: vm.scores,
                weightsUsed: vm.weightsUsed,
                staleDays: vm.staleDays,
                confidence: vm.confidence,
                constants: vm.constants,
                history: hist.isNotEmpty ? hist : null,
              );
            },
            child: Center(
              child: _GaugeCore(
                size: size,
                progress01: progress01,
                vAge: double.nan,
                cAge: double.nan,
                palette: _palette,
                headColor: headColor,
              ),
            ),
          );
        }

        final hasPropAges = vitalityAge != null && chronologicalAge != null;
        final double vAge = hasPropAges ? vitalityAge! : vm.vitalityAge;
        final double cAge = hasPropAges ? chronologicalAge! : vm.chronoAge;

        final double healthyYears = cAge - vAge;
        final double progressRaw =
        ((healthyYears + _kMaxGain) / _kSpanYears).clamp(0.0, 1.0);

        double progress01 = progressRaw;
        final double devFromCenter = (progressRaw - 0.5).abs();
        if (healthyYears.abs() > _kEpsDelta && devFromCenter < _kMinVisualOffset) {
          progress01 = 0.5 + (healthyYears.isNegative ? -1 : 1) * _kMinVisualOffset;
          progress01 = progress01.clamp(0.0, 1.0);
        }

        final headColor = _colorAtProgress(_palette, progress01);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            HapticFeedback.lightImpact();

            // Pull up to 90d; the sheet’s internal toggle will slice to 14/30/60/90.
            final hist = await ref.read(vitalityHistoryProvider(90).future);

            VitalityInfoSheet.show(
              context,
              vitalityAge: vAge.isFinite ? vAge : null,
              chronologicalAge: cAge.isFinite ? cAge : null,
              healthyYears: healthyYears.isFinite ? healthyYears : null,
              scores: vm.scores,
              weightsUsed: vm.weightsUsed,
              staleDays: vm.staleDays,
              confidence: vm.confidence,
              constants: vm.constants,
              history: hist.isNotEmpty ? hist : null,
            );
          },
          child: Center(
            child: _GaugeCore(
              size: size,
              progress01: progress01,
              vAge: vAge,
              cAge: cAge,
              palette: _palette,
              headColor: headColor,
            ),
          ),
        );
      },
    );
  }
}

class _GaugeCore extends StatelessWidget {
  const _GaugeCore({
    required this.size,
    required this.progress01,
    required this.vAge,
    required this.cAge,
    required this.palette,
    required this.headColor,
  });

  final double size;
  final double progress01;
  final double vAge;
  final double cAge;
  final List<Color> palette;
  final Color headColor;

  @override
  Widget build(BuildContext context) {
    final double k = size / 190.0;
    final double ringThickness = (18.0 * k).clamp(14.0, 24.0);

    const lightTrack = Color(0xFFF7F7F7);
    const darkTrack = Color(0xFF2B3A40);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color discColor = headColor;

    final bool showNumbers = vAge.isFinite && cAge.isFinite;
    final double healthyYears = showNumbers ? (cAge - vAge) : 0.0;

    final String centerValue = showNumbers ? vAge.toStringAsFixed(1) : '—';

    final String deltaSign = showNumbers
        ? (healthyYears > VitalityAgeGauge._kEpsDelta
        ? '−'
        : (healthyYears < -VitalityAgeGauge._kEpsDelta ? '+' : '±'))
        : '±';

    final String deltaMag =
    showNumbers ? healthyYears.abs().toStringAsFixed(1) : '0.0';
    final String deltaText = '$deltaSign$deltaMag yrs';

    final Color deltaColor =
    Theme.of(context).colorScheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);

    final gauge = SegmentRingGauge(
      progress01: progress01,
      size: size,
      ringThickness: ringThickness,
      segments: VitalityAgeGauge._segments,
      gapFraction: VitalityAgeGauge._gapFraction,
      gapPadRadians: VitalityAgeGauge._gapPad,
      unfilledTailFraction: VitalityAgeGauge._tailFrac,
      minActiveSegments: VitalityAgeGauge._minActiveSegs,
      trackColor: lightTrack,
      trackColorDark: darkTrack,
      showEdges: true,
      edgeDarken: const Color(0x22000000),
      boldBorders: true,
      borderWidth: 3.0 * k,
      borderColorActive: const Color(0x33000000),
      borderColorInactive: const Color(0x1A000000),
      showTailSegments: true,
      emphasizeHead: true,
      headThicknessBoost: 3.0 * k,
      headBorderBoost: 1.5 * k,
      headShadowBoost: 0.08,
      colors: palette,
      shadow: true,
      headColorOverride: headColor,
      center: _CenterStack(
        valueText: centerValue,
        discDiameter: size * 0.56,
        discColor: discColor,
        numberFontSize: 29.0 * k,
        labelFontSize: 14.5 * k,
        deltaText: deltaText,
        deltaColor: deltaColor,
        deltaFontSize: 12.0 * k,
      ),
    );

    return _GaugeBackplate(
      size: size,
      halo: (20.0 * k).clamp(12.0, 28.0),
      child: gauge,
    );
  }
}

class _GaugeBackplate extends StatelessWidget {
  const _GaugeBackplate({
    required this.size,
    required this.child,
    required this.halo,
  });

  final double size;
  final double halo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color plate = theme.scaffoldBackgroundColor;

    final List<BoxShadow> shadow = [
      // Tight dark shadow for strong elevation
      BoxShadow(
        color:
        Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.35 : 0.20),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      // Wide glow that extends further out
      BoxShadow(
        color: theme.colorScheme.primary.withOpacity(0.20),
        blurRadius: 60,
        spreadRadius: 16,
        offset: const Offset(0, 0),
      ),
    ];

    final double plateSize = size + halo;

    return SizedBox(
      width: plateSize,
      height: plateSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: plateSize,
            height: plateSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: plate,
              boxShadow: shadow,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _CenterStack extends StatelessWidget {
  const _CenterStack({
    required this.valueText,
    required this.discDiameter,
    required this.discColor,
    required this.numberFontSize,
    required this.labelFontSize,
    required this.deltaText,
    required this.deltaColor,
    required this.deltaFontSize,
  });

  final String valueText;
  final double discDiameter;
  final Color discColor;
  final double numberFontSize;
  final double labelFontSize;
  final String deltaText;
  final Color deltaColor;
  final double deltaFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color valueColor = isDark ? Colors.white : const Color(0xFF1B1B1B);
    final Color discStroke =
    isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: discDiameter,
          height: discDiameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: discColor,
            border: Border.all(color: discStroke, width: 1),
            boxShadow: [
              BoxShadow(
                color:
                isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valueText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: numberFontSize,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              deltaText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: deltaFontSize * 1.2,
                fontWeight: FontWeight.w800,
                color: deltaColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

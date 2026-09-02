// lib/features/home/components/vitality_age_gauge.dart
//
// Vitality Age Gauge — Palette + Glow + Scale update (Sep 2025)
// - Palettes: 8 stops = 1 red, 2 orange, 2 yellow, 3 greens (evenly spaced).
// - Center disc still matches the last lit segment color.
// - Active (last) segment is the SAME SIZE as the others (no head emphasis).
// - Outer halo/backplate glow:
//     • DARK THEME: toned down (subtler, softer blue).
//     • LIGHT THEME: slightly deeper blue and stronger so it's visible.
// - Gauge full-scale mapping increased from ~4y → ~6y: span is now 6.0 years.
// - Keep ~40% minimum visible fill and ~88% cap via _kMinNonZero (0.40) and _tailFrac (0.12).
//
// NOTE: All math/VM wiring unchanged except display span (6y). No provider API changes.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../charts/segment_ring_gauge.dart';
import '../../../state/daily_providers.dart';
import '../sheets/vitality_info_sheet.dart';

class VitalityAgeGauge extends ConsumerStatefulWidget {
  const VitalityAgeGauge({
    super.key,
    this.vitalityAge,
    this.chronologicalAge,
    this.size = 190,
    this.showBlurb = false, // legacy; ignored
  });

  final double? vitalityAge;
  final double? chronologicalAge;
  final double size;
  final bool showBlurb;

  @override
  ConsumerState<VitalityAgeGauge> createState() => _VitalityAgeGaugeState();
}

class _VitalityAgeGaugeState extends ConsumerState<VitalityAgeGauge> {
  bool _hadTodayData = false;

  // --- Gain curve constants (DISPLAY SPAN NOW 6y) ---
  // We map |healthyYears| to progress over a 0..6y span (no overflow growth).
  static const double _kMaxGainBase = 6.0;
  static const double _kMaxGainCeil = 6.0; // lock to 6 so span = 6y
  static const double _kOverflowTau  = 0.8; // unused when base == ceil, kept for compat

  // --- Fill behavior (keep ~40% floor, ~88% cap via tail) ---
  static const double _kMinNonZero = 0.40; // ~40% visible floor
  static const double _kEpsDelta = 0.001;

  // --- Ring layout (unchanged) ---
  static const int _segments = 56;
  static const double _gapFraction = 0.36;
  static const double _gapPad = 0.008;
  static const double _tailFrac = 0.12; // leaves ~88% as max headroom
  static const int _minActiveSegs = 2;

  // === NEW 8-STOP PALETTES ===
  // 1 red, 2 orange, 2 yellow, 3 green (warm → green). NEG is the reverse.
  // Hexes chosen to align with prior tones while balancing contrast.
  static const List<Color> _paletteWarmToGreen8_POS = [
    Color(0xFFE46B6B), // red (semantic error red)
    Color(0xFFE49A3F), // orange
    Color(0xFFF6B56B), // amber / orange-yellow
    Color(0xFFF6D77F), // yellow (bright)
    Color(0xFFF2E488), // yellow (warmer/deeper)
    Color(0xFFA5D97F), // light green
    Color(0xFF4CAF50), // green
    Color(0xFF1B5E20), // deep green
  ];

  static const List<Color> _paletteGreenToWarm8_NEG = [
    Color(0xFF1B5E20), // deep green
    Color(0xFF4CAF50), // green
    Color(0xFFA5D97F), // light green
    Color(0xFFF2E488), // yellow (warmer/deeper)
    Color(0xFFF6D77F), // yellow (bright)
    Color(0xFFF6B56B), // amber / orange-yellow
    Color(0xFFE49A3F), // orange
    Color(0xFFE46B6B), // red
  ];

  static Color _colorAtProgress(List<Color> palette, double t) {
    if (palette.isEmpty) return const Color(0xFF1B5E20);
    final p = t.clamp(0.0, 1.0);
    if (palette.length == 1) return palette.first;
    final scaled = p * (palette.length - 1);
    final lo = scaled.floor();
    final hi = (lo + 1).clamp(0, palette.length - 1);
    final frac = scaled - lo;
    return Color.lerp(palette[lo], palette[hi], frac) ?? palette.last;
  }

  static double _effectiveSpan(double deltaAbs) {
    if (deltaAbs <= _kMaxGainBase) return _kMaxGainBase;
    final overflow = deltaAbs - _kMaxGainBase;
    final room = _kMaxGainCeil - _kMaxGainBase;
    final grow01 = 1.0 - math.exp(-overflow / _kOverflowTau);
    return _kMaxGainBase + room * grow01.clamp(0.0, 1.0);
  }

  static Color _neutralDiscColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF445055)
        : const Color(0xFFEDEFF2);
  }

  static Color _headPaletteColor({
    required List<Color> palette,
    required double progress01,
    required int segmentsUsableParam,
    required double unfilledTailFraction,
    required int minActiveSegments,
  }) {
    final usableFrac = 1.0 - unfilledTailFraction;
    final totalSegmentsFull =
    math.max(segmentsUsableParam, (segmentsUsableParam / usableFrac).round());
    final usableSegments = (totalSegmentsFull * usableFrac).round().clamp(1, 10000);

    double lerpT(int i) {
      if (usableSegments <= 1) return 1.0;
      return i / (usableSegments - 1);
    }

    final rawActive = (progress01.clamp(0.0, 1.0)) * usableSegments;
    final whole = rawActive.floor();
    final feather = rawActive - whole;
    final activeWhole = math.max(whole, minActiveSegments).clamp(0, usableSegments);

    int headIndex;
    if (feather > 1e-6 && activeWhole < usableSegments) {
      headIndex = activeWhole;
    } else {
      headIndex = math.max(0, activeWhole - 1);
    }

    final t = lerpT(headIndex).clamp(0.0, 1.0);
    if (palette.length == 1) return palette.first;
    final scaled = t * (palette.length - 1);
    final lo = scaled.floor();
    final hi = math.min(palette.length - 1, lo + 1);
    final k = scaled - lo;
    return Color.lerp(palette[lo], palette[hi], k) ?? palette.last;
  }

  @override
  Widget build(BuildContext context) {
    final vmAsync = ref.watch(vitalityGaugeVMProvider);
    return vmAsync.when(
      loading: () {
        return Center(
          child: _GaugeCore(
            size: widget.size,
            progress01: 0.0,
            vAge: double.nan,
            cAge: double.nan,
            palette: _paletteWarmToGreen8_POS,
            ringHeadColor: _neutralDiscColor(context),
            discColor: _neutralDiscColor(context),
            counterClockwise: false,
            nearCrossoverPulse: false,
            eliteGlow01: 0.0,
            isStale: false,
          ),
        );
      },
      error: (e, st) => Center(
        child: Text('—', style: Theme.of(context).textTheme.bodyMedium),
      ),
      data: (vm) {
        final bool canShow = vm.hasVitality;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && canShow && !_hadTodayData) {
            setState(() => _hadTodayData = true);
          }
        });

        Future<void> openSheet(double? vAge, double? cAge, double? healthyYears) async {
          HapticFeedback.lightImpact();
          final hist = await ref.read(vitalityHistoryProvider(90).future);
          VitalityInfoSheet.show(
            context,
            vitalityAge: (vAge?.isFinite ?? false) ? vAge : null,
            chronologicalAge: (cAge?.isFinite ?? false) ? cAge : null,
            healthyYears: (healthyYears?.isFinite ?? false) ? healthyYears : null,
            scores: vm.scores,
            weightsUsed: vm.weightsUsed,
            staleDays: vm.staleDays,
            confidence: vm.confidence,
            constants: vm.constants,
            history: hist.isNotEmpty ? hist : null,
          );
        }

        if (!canShow) {
          final neutral = _neutralDiscColor(context);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => openSheet(null, null, null),
            child: Center(
              child: _GaugeCore(
                size: widget.size,
                progress01: 0.0,
                vAge: double.nan,
                cAge: double.nan,
                palette: _paletteWarmToGreen8_POS,
                ringHeadColor: neutral,
                discColor: neutral,
                counterClockwise: false,
                nearCrossoverPulse: false,
                eliteGlow01: 0.0,
                isStale: false,
              ),
            ),
          );
        }

        final hasPropAges =
            widget.vitalityAge != null && widget.chronologicalAge != null;
        final double vAge = hasPropAges ? widget.vitalityAge! : vm.vitalityAge;
        final double cAge = hasPropAges ? widget.chronologicalAge! : vm.chronoAge;

        final double healthyYears = cAge - vAge;
        final double dAbs = healthyYears.abs();

        final double spanY = _effectiveSpan(dAbs);
        final double eliteGlow01 = (dAbs <= _kMaxGainBase)
            ? 0.0
            : ((dAbs - _kMaxGainBase) / (_kMaxGainCeil - _kMaxGainBase))
            .clamp(0.0, 1.0);

        const double kMaxFill = 1.0 - _tailFrac;
        final double tMag = (dAbs / spanY).clamp(0.0, 1.0);
        final bool isExactZero = dAbs <= _kEpsDelta;
        final double expo = (healthyYears < 0) ? 0.60 : 0.70;
        final double targetProgress01 = isExactZero
            ? _kMinNonZero
            : _kMinNonZero + (kMaxFill - _kMinNonZero) * math.pow(tMag, expo);

        final bool ccw = healthyYears < -_kEpsDelta;
        final List<Color> palette =
        ccw ? _paletteGreenToWarm8_NEG : _paletteWarmToGreen8_POS;

        final bool playIntro = _hadTodayData == false;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => openSheet(vAge, cAge, healthyYears),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: playIntro ? 0.0 : 1.0, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, anim01, _) {
              final double animatedProgress = targetProgress01 * anim01;

              final Color trueHeadColor = (animatedProgress <= 0.0)
                  ? _neutralDiscColor(context)
                  : _headPaletteColor(
                palette: palette,
                progress01: animatedProgress,
                segmentsUsableParam: _segments,
                unfilledTailFraction: _tailFrac,
                minActiveSegments: _minActiveSegs,
              );

              final bool nearCrossoverPulse = dAbs >= 0.08 && dAbs <= 0.20;

              return Center(
                child: _GaugeCore(
                  size: widget.size,
                  progress01: animatedProgress,
                  vAge: vAge,
                  cAge: cAge,
                  palette: palette,
                  ringHeadColor: trueHeadColor,
                  discColor: trueHeadColor, // center disc = head segment color
                  counterClockwise: ccw,
                  nearCrossoverPulse: nearCrossoverPulse,
                  eliteGlow01: eliteGlow01,
                  isStale: vm.isStale,
                ),
              );
            },
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
    required this.ringHeadColor,
    required this.discColor,
    required this.counterClockwise,
    required this.nearCrossoverPulse,
    required this.eliteGlow01,
    required this.isStale,
  });

  final double size;
  final double progress01;
  final double vAge;
  final double cAge;
  final List<Color> palette;
  final Color ringHeadColor;
  final Color discColor;
  final bool counterClockwise;
  final bool nearCrossoverPulse;
  final double eliteGlow01;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final double k = size / 190.0;
    final double ringThickness = (18.0 * k).clamp(14.0, 24.0);

    const lightTrack = Color(0xFFF7F7F7);
    const darkTrack = Color(0xFF2B3A40);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool showNumbers = vAge.isFinite && cAge.isFinite;
    final double healthyYears = showNumbers ? (cAge - vAge) : 0.0;

    final String centerValue = showNumbers ? vAge.toStringAsFixed(1) : '—';

    // Slightly brighter on dark backgrounds for readability.
    final Color deltaColor = isDark
        ? Colors.white.withOpacity(0.86)
        : Colors.black.withOpacity(0.65);

    final String deltaSign =
    showNumbers ? (healthyYears > 0 ? '−' : (healthyYears < 0 ? '+' : '±')) : '±';
    final String deltaMag =
    showNumbers ? healthyYears.abs().toStringAsFixed(1) : '0.0';
    final String deltaText =
        '$deltaSign$deltaMag yrs${isStale ? " · stale" : ""}';

    // === Uniform head: active segment = same size as others ===
    const bool kEmphasizeHead = false;
    const double kHeadThicknessBoost = 0.0;
    const double kHeadBorderBoost    = 0.0;
    const double kHeadShadowBoost    = 0.0;

    final gauge = SegmentRingGauge(
      progress01: progress01,
      size: size,
      ringThickness: ringThickness,
      segments: _VitalityAgeGaugeState._segments,
      gapFraction: _VitalityAgeGaugeState._gapFraction,
      gapPadRadians: _VitalityAgeGaugeState._gapPad,
      unfilledTailFraction: _VitalityAgeGaugeState._tailFrac,
      minActiveSegments: _VitalityAgeGaugeState._minActiveSegs,
      trackColor: lightTrack,
      trackColorDark: darkTrack,
      showEdges: true,
      edgeDarken: const Color(0x22000000),
      boldBorders: true,
      borderWidth: 3.0 * k,
      borderColorActive: const Color(0x33000000),
      borderColorInactive: const Color(0x1A000000),
      showTailSegments: true,
      emphasizeHead: kEmphasizeHead,      // <-- uniform active segment
      headThicknessBoost: kHeadThicknessBoost,
      headBorderBoost: kHeadBorderBoost,
      headShadowBoost: kHeadShadowBoost,
      colors: palette,
      shadow: true,
      counterClockwise: counterClockwise,
      center: _CenterStack(
        valueText: centerValue,
        discDiameter: size * 0.56,
        discColor: discColor,
        numberFontSize: 29.0 * k,
        labelFontSize: 14.5 * k,
        deltaText: deltaText,
        deltaColor: deltaColor,
        deltaFontSize: 12.0 * k,
        pulse: nearCrossoverPulse,
        glowTint: ringHeadColor,
        eliteGlow01: eliteGlow01,
      ),
    );

    return _GaugeBackplate(
      size: size,
      halo: (20.0 * k).clamp(12.0, 28.0),
      eliteGlow01: eliteGlow01, // kept in signature; halo color is now theme-based
      glowColor: ringHeadColor, // kept in signature; not used to tint halo
      child: gauge,
    );
  }
}

// Backplate: PERMANENT, COLOR-AGNOSTIC halo, tuned per theme.
// - DARK: toned down sky-blue so it isn't overpowering.
// - LIGHT: deeper/stronger blue so it shows on white backgrounds.
class _GaugeBackplate extends StatelessWidget {
  const _GaugeBackplate({
    required this.size,
    required this.child,
    required this.halo,
    required this.eliteGlow01,
    required this.glowColor,
  });

  final double size;
  final double halo;
  final double eliteGlow01; // kept (no longer drives color)
  final Color glowColor;    // kept (no longer used to tint)
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color plate = theme.scaffoldBackgroundColor;

    // Theme-specific halo stack
    final List<BoxShadow> shadow = isDark
        ? <BoxShadow>[
      // Ambient
      BoxShadow(
        color: Colors.black.withOpacity(0.26),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      // Subtle sky-blue glow (toned down)
      const BoxShadow(
        color: Color(0x66D5E9FF), // softer blue, less alpha
        blurRadius: 70,
        spreadRadius: 18,
        offset: Offset(0, 0),
      ),
      // Gentle white lift
      BoxShadow(
        color: Colors.white.withOpacity(0.07),
        blurRadius: 8,
        spreadRadius: 1,
        offset: const Offset(0, -1),
      ),
    ]
        : <BoxShadow>[
      // Ambient (lighter)
      BoxShadow(
        color: Colors.black.withOpacity(0.18),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
      // Deeper/stronger blue so it shows on light backgrounds
      const BoxShadow(
        color: Color(0x99C8E6FF), // deeper blue, higher alpha
        blurRadius: 90,
        spreadRadius: 28,
        offset: Offset(0, 0),
      ),
      // White lift
      BoxShadow(
        color: Colors.white.withOpacity(0.12),
        blurRadius: 10,
        spreadRadius: 2,
        offset: const Offset(0, -1),
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
    required this.pulse,
    required this.glowTint,
    required this.eliteGlow01,
  });

  final String valueText;
  final double discDiameter;
  final Color discColor;
  final double numberFontSize;
  final double labelFontSize;
  final String deltaText;
  final Color deltaColor;
  final double deltaFontSize;
  final bool pulse;
  final Color glowTint;     // head tint for inner disc glow only
  final double eliteGlow01; // 0..1

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color valueColor = isDark ? Colors.white : const Color(0xFF1B1B1B);
    final Color discStroke =
    isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);

    // Stronger, localized “badge” glow for the center disc (uses head tint).
    final Widget disc = Container(
      width: discDiameter,
      height: discDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: discColor,
        border: Border.all(color: discStroke, width: 1),
        boxShadow: [
          BoxShadow(
            color: glowTint.withOpacity(0.20 + 0.08 * eliteGlow01),
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.45) : Colors.black.withOpacity(0.28),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          // Subtle top sparkle for a crisp “badge” feel
          BoxShadow(
            color: Colors.white.withOpacity(0.18),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: pulse ? 1.04 : 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              disc,
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
          ),
        );
      },
    );
  }
}

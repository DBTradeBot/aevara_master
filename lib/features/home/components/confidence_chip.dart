// lib/features/home/components/confidence_chip.dart
//
// ConfidenceChip — Uniform scaling
// Default scale is 0.65 (≈30% larger than the previous 0.5 default).
// Shows a circular progress ring when `confidence` is provided (0..100).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sheets/confidence_info_sheet.dart';

class ConfidenceChip extends StatelessWidget {
  const ConfidenceChip({
    super.key,
    this.confidence,
    this.dimmed = false,
    this.diameter = 66.0,     // base size (pre-scale)
    this.ringThickness = 6.0, // base thickness (pre-scale)
    this.animationMs = 260,
    this.gapBelow = 6.0,      // base gap (pre-scale)
    this.scale = 0.65,        // 30% larger than the old 0.5 default
  });

  final int? confidence;
  final bool dimmed;

  /// Base (pre-scale) geometry tokens
  final double diameter;
  final double ringThickness;
  final int animationMs;
  final double gapBelow;

  /// Multiplier applied to ALL geometry, paddings and text sizes.
  final double scale;

  Color _ringColor(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  Color _textOnRing(BuildContext context) =>
      Theme.of(context).colorScheme.onSecondary;

  Color _centerFill(BuildContext context) =>
      Theme.of(context).colorScheme.secondary.withOpacity(dimmed ? 0.65 : 0.75);

  Color _trackColor(BuildContext context) =>
      Theme.of(context).colorScheme.secondary.withOpacity(0.25);

  @override
  Widget build(BuildContext context) {
    final int c = (confidence ?? 0).clamp(0, 100);
    final bool showProgress = !dimmed && confidence != null;
    final String label =
    (dimmed || confidence == null) ? 'Confidence' : 'Confidence $c%';

    final ringColor   = _ringColor(context);
    final onRingColor = _textOnRing(context);
    final centerFill  = _centerFill(context);
    final trackColor  = _trackColor(context);

    // Apply uniform scaling
    final double d        = (diameter * scale).clamp(24.0, 1000.0);
    final double thick    = (ringThickness * scale).clamp(2.0, 100.0);
    final double padAll   = (6.0 * scale).clamp(2.0, 24.0);
    final double gap      = (gapBelow * scale).clamp(2.0, 24.0);
    final double fontSize = (diameter * 0.16 * scale).clamp(8.0, 48.0);
    final double iconSize = (d * 0.26).clamp(8.0, 64.0);

    return Semantics(
      label: (confidence == null)
          ? 'Confidence unknown. Tap for details.'
          : 'Confidence $c percent. Tap for details.',
      button: true,
      child: Material(
        color: Colors.transparent,
        elevation: 16.0,
        shape: const CircleBorder(),
        shadowColor: Colors.black.withOpacity(0.35),
        child: InkWell(
          borderRadius: BorderRadius.circular(d / 2),
          onTap: () async {
            await HapticFeedback.selectionClick();
            // ignore: use_build_context_synchronously
            await showModalBottomSheet<void>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              showDragHandle: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (ctx) => const ConfidenceInfoSheet(),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(padAll),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: d,
                  height: d,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(d, d),
                        painter: _CenterFillPainter(
                          color: centerFill,
                          inset: thick * 1.35,
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0.0,
                          end: showProgress ? (c / 100.0) : 0.0,
                        ),
                        duration: Duration(milliseconds: animationMs),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return CustomPaint(
                            size: Size(d, d),
                            painter: _RingPainter(
                              fraction: value.clamp(0.0, 1.0),
                              trackColor: trackColor,
                              fillColor: ringColor,
                              thickness: thick,
                            ),
                          );
                        },
                      ),
                      Icon(
                        Icons.verified_user_rounded,
                        size: iconSize,
                        color: onRingColor.withOpacity(dimmed ? 0.8 : 0.95),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: gap),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ringColor,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    height: 1.12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterFillPainter extends CustomPainter {
  _CenterFillPainter({required this.color, this.inset = 0});
  final Color color;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - inset;
    final c = Offset(size.width / 2, size.height / 2);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(covariant _CenterFillPainter old) =>
      old.color != color || old.inset != inset;
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.trackColor,
    required this.fillColor,
    required this.thickness,
  });

  final double fraction;
  final Color trackColor;
  final Color fillColor;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - (thickness / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final progressPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Full track
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc (starts at top)
    if (fraction > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      const startAngle = -90 * _deg2rad;
      final sweep = (360.0 * fraction) * _deg2rad;
      canvas.drawArc(rect, startAngle, sweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction ||
          old.trackColor != trackColor ||
          old.fillColor != fillColor ||
          old.thickness != thickness;
}

const double _deg2rad = 3.1415926535897932 / 180.0;

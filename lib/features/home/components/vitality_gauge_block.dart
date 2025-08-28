// lib/features/home/components/vitality_gauge_block.dart
//
// VitalityGaugeBlock — composition wrapper around the pure VitalityAgeGauge.
// Adornments (e.g., Chevron) can sit bottom-left/right OR center-right.
//
// FIXED: Removed redundant Material backplate that caused the oversized ghost ring.
// Gauge now draws its own backplate. This block just positions the gauge and adornments.

import 'package:flutter/material.dart';

import 'vitality_age_gauge.dart';

class VitalityGaugeBlock extends StatelessWidget {
  const VitalityGaugeBlock({
    super.key,
    required this.size,
    this.gap = 14.0,
    this.haloMax = 28.0,
    this.leftBottom,
    this.rightBottom,
    this.extraPushLeft = 0.0,
    this.extraPushRight = 0.0,
    this.verticalLift = 0.25,
    this.leftTapDelegate,
    this.rightTapDelegate,
    this.adornmentHitDiameter = 56.0,
    this.rightAtCenter = false,
  });

  final double size;
  final double gap;
  final double haloMax;

  final Widget? leftBottom;
  final Widget? rightBottom;

  final double extraPushLeft;
  final double extraPushRight;
  final double verticalLift;

  final VoidCallback? leftTapDelegate;
  final VoidCallback? rightTapDelegate;
  final double adornmentHitDiameter;

  final bool rightAtCenter;

  @override
  Widget build(BuildContext context) {
    final double leftPush = gap + extraPushLeft;
    final double rightPush = gap + extraPushRight;

    const double cushion = 8.0;

    final double extraPadLeft = leftPush + cushion;
    final double extraPadRight = rightPush + cushion;

    final double stackBox = size + haloMax + extraPadLeft + extraPadRight;
    final double bottomLift = gap * verticalLift;

    return SizedBox(
      width: stackBox,
      height: (size + haloMax) + (gap * 1.8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Gauge itself (renders its own backplate inside)
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: VitalityAgeGauge(size: size, showBlurb: false),
          ),

          // LEFT adornment
          if (leftBottom != null)
            Positioned(
              left: cushion,
              bottom: bottomLift,
              child: _TapHalo(
                enabled: leftTapDelegate != null,
                onTap: leftTapDelegate,
                diameter: adornmentHitDiameter,
                child: leftBottom!,
              ),
            ),

          // RIGHT adornment
          if (rightBottom != null)
            (rightAtCenter
                ? Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: cushion),
                child: _TapHalo(
                  enabled: rightTapDelegate != null,
                  onTap: rightTapDelegate,
                  diameter: adornmentHitDiameter,
                  child: rightBottom!,
                ),
              ),
            )
                : Positioned(
              right: cushion,
              bottom: bottomLift,
              child: _TapHalo(
                enabled: rightTapDelegate != null,
                onTap: rightTapDelegate,
                diameter: adornmentHitDiameter,
                child: rightBottom!,
              ),
            )),
        ],
      ),
    );
  }
}

class _TapHalo extends StatelessWidget {
  const _TapHalo({
    required this.child,
    required this.diameter,
    this.onTap,
    this.enabled = false,
  });

  final Widget child;
  final double diameter;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              splashColor:
              Theme.of(context).colorScheme.secondary.withOpacity(0.12),
              highlightColor: Colors.transparent,
              child: const SizedBox.expand(),
            ),
          ),
          IgnorePointer(ignoring: true, child: child),
        ],
      ),
    );
  }
}

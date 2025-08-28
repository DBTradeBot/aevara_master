// lib/widgets/avatar/coach_avatar.dart
//
// A thin, reusable wrapper around our coach Lottie animation.
// Usage:
//   const CoachAvatar(size: 168)
// Place this inside your HeroHeader or any card.
//
// Design notes:
// - RepaintBoundary to keep it cheap when surrounding widgets rebuild.
// - Defaults match our design system (docs/4_design_system.md).
// - Exposes a small set of knobs: size, repeat, animate, speed, semanticsLabel.
// - Delegates come from LottieTheme; you can also pass your own overrideDelegates
//   if a specific screen needs a different tint.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../theme/lottie.dart';

class CoachAvatar extends StatelessWidget {
  const CoachAvatar({
    super.key,
    this.size = 180,
    this.repeat,
    this.animate,
    this.speed = 1.0,
    this.semanticsLabel = 'Coach avatar',
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
    this.frameRate,
    this.overrideDelegates,
  });

  /// Square dimension of the avatar (w = h = size).
  final double size;

  /// Whether the animation loops. If null, uses LottieTheme defaults.
  final bool? repeat;

  /// Whether the animation plays. If null, uses LottieTheme defaults.
  final bool? animate;

  /// Playback speed multiplier.
  final double speed;

  /// Accessibility label.
  final String semanticsLabel;

  /// Layout controls
  final Alignment alignment;
  final BoxFit fit;
  final FrameRate? frameRate;

  /// Provide custom delegates to recolor/override values for this instance.
  final LottieDelegates? overrideDelegates;

  @override
  Widget build(BuildContext context) {
    // If you ever want to pause animation in low power mode or reduce motion,
    // you can branch on MediaQuery or a settings flag here.
    return Semantics(
      label: semanticsLabel,
      // Mark as image so it’s discoverable but not overly verbose for screen readers
      // (it’s decorative most of the time).
      image: true,
      child: RepaintBoundary(
        child: LottieTheme.coachAvatar(
          context: context,
          size: size,
          repeat: repeat,
          animate: animate,
          speed: speed,
          frameRate: frameRate,
          alignment: alignment,
          fit: fit,
          overrideDelegates: overrideDelegates,
          // delegates: LottieTheme.delegatesFor(context) happens inside
        ),
      ),
    );
  }
}

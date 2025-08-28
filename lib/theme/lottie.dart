// lib/theme/lottie.dart
//
// Central place for Lottie asset paths & delegates.
// Updated to use .json for coach avatar to match confirmed asset.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

abstract class LottieAssets {
  static const String coachAvatar = 'assets/lottie/coach_avatar.json';
}

class LottieTheme {
  static LottieDelegates? delegatesFor(BuildContext context) {
    // Placeholder for future layer-specific theming.
    return null;
  }

  static const bool defaultRepeat = true;
  static const bool defaultAnimate = true;
  static const double defaultSpeed = 1.0;
  static const FilterQuality defaultFilterQuality = FilterQuality.medium;

  static LottieBuilder coachAvatar({
    required BuildContext context,
    double size = 180,
    bool? repeat,
    bool? animate,
    double speed = defaultSpeed,
    FrameRate? frameRate,
    Alignment alignment = Alignment.center,
    BoxFit fit = BoxFit.contain,
    String semanticsLabel = 'Coach avatar',
    LottieDelegates? overrideDelegates,
  }) {
    return Lottie.asset(
      LottieAssets.coachAvatar,
      width: size,
      height: size,
      repeat: repeat ?? defaultRepeat,
      animate: animate ?? defaultAnimate,
      alignment: alignment,
      fit: fit,
      frameRate: frameRate,
      filterQuality: defaultFilterQuality,
      delegates: overrideDelegates ?? LottieTheme.delegatesFor(context),
    );
  }
}

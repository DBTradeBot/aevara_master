// lib/core/widgets/avatar/coach_avatar.dart
//
// CoachAvatar — corner-friendly Lottie avatar (no external color sync)
// - Theme-aware circular mask
// - Background removed by default (transparent unless bgColor provided)
// - Can hide specific Lottie layers (e.g., "Aura 2" glow)
// - Tiny nudge controls for visual centering
// - Optional elevation shadow

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CoachAvatar extends StatelessWidget {
  const CoachAvatar({
    super.key,
    this.size = 140,
    this.assetPath = 'assets/lottie/coach_avatar.json',
    this.loop = true,
    this.padding = 4,
    this.showHalo = false,
    this.hideLayerNames = const ['Aura 2'],
    this.bgColor,
    this.centerDx = 0.0,
    this.centerDy = 0.0,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel = 'Coach avatar',
    this.showElevation = false,
    this.elevation = 6.0,
  });

  final double size;
  final String assetPath;
  final bool loop;
  final double padding;
  final bool showHalo;

  /// Lottie layer names to hide (set opacity to 0).
  final List<String> hideLayerNames;

  /// Optional solid background inside the circular clip.
  /// If null, no background is drawn (transparent).
  final Color? bgColor;

  /// Small visual nudges (logical px) to re-center compositions.
  final double centerDx;
  final double centerDy;

  final BoxFit fit;
  final Alignment alignment;
  final String semanticLabel;

  /// Elevation shadow
  final bool showElevation;
  final double elevation;

  LottieDelegates? _buildDelegates() {
    if (hideLayerNames.isEmpty) return null;
    final values = <ValueDelegate<dynamic>>[];
    for (final layer in hideLayerNames) {
      values.add(ValueDelegate.opacity([layer], value: 0));
    }
    return LottieDelegates(values: values);
  }

  Widget _buildCore(BuildContext context, {required Color? effectiveBg}) {
    final theme = Theme.of(context);

    final lottie = Transform.translate(
      offset: Offset(centerDx, centerDy),
      child: LottieBuilder.asset(
        assetPath,
        repeat: loop,
        animate: true,
        frameRate: FrameRate.max,
        fit: fit,
        alignment: alignment,
        delegates: _buildDelegates(),
        errorBuilder: (context, error, stack) => Icon(
          Icons.person,
          size: size * 0.5,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.55),
        ),
      ),
    );

    // Optional faint interior halo (off by default)
    final halo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.92,
          colors: [
            Colors.transparent,
            theme.colorScheme.primary.withOpacity(0.08),
            Colors.transparent,
          ],
          stops: const [0.60, 0.85, 1.0],
        ),
      ),
    );

    // Background circle (only if explicitly provided)
    final bgCircle = effectiveBg == null
        ? const SizedBox.shrink()
        : Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        shape: BoxShape.circle,
      ),
    );

    // Circular clip for avatar
    final avatarCircle = ClipOval(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: SizedBox(
          width: size - padding * 2,
          height: size - padding * 2,
          child: Center(child: lottie),
        ),
      ),
    );

    // Core stack
    final core = Stack(
      alignment: Alignment.center,
      children: [
        if (effectiveBg != null) bgCircle,
        if (showHalo) halo,
        avatarCircle,
      ],
    );

    // Theme-aware shadow color
    final Color shadowCol = theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.45)
        : Colors.black.withOpacity(0.25);

    // Wrap with Material for elevation if requested
    final withElevation = showElevation
        ? Material(
      elevation: elevation,
      shadowColor: shadowCol,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: core,
    )
        : core;

    return Semantics(
      label: semanticLabel,
      child: SizedBox(width: size, height: size, child: withElevation),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If caller provided a bgColor, use it directly.
    if (bgColor != null) {
      return _buildCore(context, effectiveBg: bgColor);
    }

    // Otherwise: no background (transparent).
    return _buildCore(context, effectiveBg: null);
  }
}

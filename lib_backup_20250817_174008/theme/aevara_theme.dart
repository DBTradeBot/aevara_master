// lib/theme/aevara_theme.dart
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

@immutable
class AevaraTheme extends ThemeExtension<AevaraTheme> {
  final double radius;
  final double elevation;

  final Color primary;
  final Color primaryText;
  final Color secondaryText;

  final Color icon;
  final Color iconMuted;

  final Color error;
  final Color warning; // NEW
  final Color success; // NEW
  final Color info;

  final Color surface;
  final Color surfaceAlt;

  final Color accent1;

  /// Shadow COLOR (code calls `.withOpacity()` on this), not a list of BoxShadows.
  final Color shadow;

  const AevaraTheme({
    required this.radius,
    required this.elevation,
    required this.primary,
    required this.primaryText,
    required this.secondaryText,
    required this.icon,
    required this.iconMuted,
    required this.error,
    required this.warning,
    required this.success,
    required this.info,
    required this.surface,
    required this.surfaceAlt,
    required this.accent1,
    required this.shadow,
  });

  factory AevaraTheme.fromScheme(ColorScheme s) {
    return AevaraTheme(
      radius: 14,
      elevation: 1,
      primary: s.primary,
      primaryText: s.onSurface,
      secondaryText: s.onSurfaceVariant,
      icon: s.onSurfaceVariant,
      iconMuted: s.outline,
      error: s.error,
      warning: const Color(0xFFF9A825), // amber 800-ish
      success: const Color(0xFF2E7D32), // green 800-ish
      info: s.secondary,
      surface: s.surface,
      // Modern M3 surface level (available in current stable)
      surfaceAlt: s.surfaceContainerHighest,
      accent1: s.tertiary,
      // Use withOpacity for broad SDK compatibility
      shadow: s.scrim.withOpacity(0.18),
    );
  }

  @override
  AevaraTheme copyWith({
    double? radius,
    double? elevation,
    Color? primary,
    Color? primaryText,
    Color? secondaryText,
    Color? icon,
    Color? iconMuted,
    Color? error,
    Color? warning,
    Color? success,
    Color? info,
    Color? surface,
    Color? surfaceAlt,
    Color? accent1,
    Color? shadow,
  }) {
    return AevaraTheme(
      radius: radius ?? this.radius,
      elevation: elevation ?? this.elevation,
      primary: primary ?? this.primary,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      icon: icon ?? this.icon,
      iconMuted: iconMuted ?? this.iconMuted,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      info: info ?? this.info,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      accent1: accent1 ?? this.accent1,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AevaraTheme lerp(ThemeExtension<AevaraTheme>? other, double t) {
    if (other is! AevaraTheme) {
      return this;
    }
    return AevaraTheme(
      radius: lerpDouble(radius, other.radius, t)!,
      elevation: lerpDouble(elevation, other.elevation, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      accent1: Color.lerp(accent1, other.accent1, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }

  static AevaraTheme of(BuildContext context) {
    return Theme.of(context).extension<AevaraTheme>() ??
        AevaraTheme.fromScheme(Theme.of(context).colorScheme);
  }
}

// Convenient access: context.aevara
extension AevaraContextX on BuildContext {
  AevaraTheme get aevara => AevaraTheme.of(this);
}

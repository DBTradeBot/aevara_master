import 'package:flutter/material.dart';

/// A compact pill that sits BELOW the vitality gauge showing the delta vs chronological age.
/// Example: "≈ −0.3 yrs vs age 33"
class VitalityBlurb extends StatelessWidget {
  const VitalityBlurb({
    super.key,
    required this.vitalityAge,
    required this.chronologicalAge,
  });

  /// Pass nulls if not ready; the chip will hide.
  final double? vitalityAge;
  final double? chronologicalAge;

  @override
  Widget build(BuildContext context) {
    final v = vitalityAge;
    final c = chronologicalAge;
    if (v == null || c == null) {
      // Not ready → no blurb (keeps the hero minimal, avoids placeholders).
      return const SizedBox.shrink();
    }

    final delta = v - c;
    final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '±');
    final absDelta = delta.abs();

    final theme = Theme.of(context);
    final bg = _pillBackground(theme);
    final fg = _pillForeground(theme);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '≈ $sign${absDelta.toStringAsFixed(1)} yrs vs age ${c.round()}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _pillBackground(ThemeData theme) {
    // Subtle contrast with the hero card; auto for light/dark.
    if (theme.brightness == Brightness.light) {
      return theme.colorScheme.secondaryContainer.withOpacity(0.70);
    }
    return theme.colorScheme.surfaceVariant.withOpacity(0.60);
  }

  Color _pillForeground(ThemeData theme) {
    if (theme.brightness == Brightness.light) {
      return theme.colorScheme.onSecondaryContainer.withOpacity(0.90);
    }
    return theme.colorScheme.onSurfaceVariant.withOpacity(0.90);
  }
}

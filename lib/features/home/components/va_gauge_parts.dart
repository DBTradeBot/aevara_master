// lib/features/home/components/va_gauge_parts.dart
//
// Small shared bits used by Vitality gauge:
// - VaGaugeBanner (status/calibration line)
// - VaConfidenceRow (confidence indicator)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VaGaugeBanner extends StatelessWidget {
  const VaGaugeBanner({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF243039) : const Color(0xFFF4F7FA);
    final border =
    isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          const Text('ℹ️  '),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.25,
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VaConfidenceRow extends StatelessWidget {
  const VaConfidenceRow({super.key, required this.confidence});
  final int confidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = confidence.clamp(0, 100);
    final Color color = c >= 80
        ? const Color(0xFF24A699)
        : (c >= 50 ? const Color(0xFFF6B56B) : const Color(0xFFBF4A4A));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            'Confidence $c/100',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

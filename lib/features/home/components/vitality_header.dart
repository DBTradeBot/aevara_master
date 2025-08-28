// lib/features/home/components/vitality_header.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VitalityHeader extends StatelessWidget {
  const VitalityHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      "Your Vitality Age Today",
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600, // bold
        height: 1.0,
        // 👇 Use the same darker neutral as the chevron
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

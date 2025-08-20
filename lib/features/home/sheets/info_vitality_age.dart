// lib/features/home/sheets/info_vitality_age.dart
// ℹ️ Explains Vitality Age and how we compute/use it.

import 'package:flutter/material.dart';

class InfoVitalityAgeSheet extends StatelessWidget {
  const InfoVitalityAgeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('About Vitality age', style: tt.titleLarge),
              const Spacer(),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 8),
            Text(
              'Vitality age is a model-based estimate of your biological fitness age using sleep, HRV, resting HR, and recent activity. '
                  'Lower is better. We compare it to your chronological age to show +/− delta.',
              style: tt.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Confidence',
              style: tt.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Confidence reflects data freshness and agreement across inputs. Fresh, consistent inputs improve confidence.',
              style: tt.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

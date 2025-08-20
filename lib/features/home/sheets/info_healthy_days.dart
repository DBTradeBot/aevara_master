// lib/features/home/sheets/info_healthy_days.dart
// ℹ️ Explains the "Healthy days" mini metric and what counts.

import 'package:flutter/material.dart';

class InfoHealthyDaysSheet extends StatelessWidget {
  const InfoHealthyDaysSheet({super.key});

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
              Text('About Healthy days', style: tt.titleLarge),
              const Spacer(),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 8),
            Text(
              'Healthy days are days that meet sleep, recovery, and activity targets. We track the last 30 days and show your total.',
              style: tt.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Targets',
              style: tt.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Targets adapt as we learn your baseline. Missing device data may reduce the count and confidence.',
              style: tt.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

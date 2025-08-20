// lib/features/home/sheets/vitality_info_sheet.dart
import 'package:flutter/material.dart';

class VitalityInfoSheet extends StatelessWidget {
  const VitalityInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('About Vitality age', style: tt.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Vitality age is a composite marker derived from your HRV, resting HR, sleep, '
                  'and activity history. Lower is better (younger biological age).',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'What affects it?',
              style: tt.titleMedium,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '• Sleep duration & efficiency\n'
                  '• HRV (RMSSD)\n'
                  '• Resting heart rate (RHR)\n'
                  '• Daily load (steps / MVPA)\n'
                  '\nWe’ll show a confidence indicator when data is incomplete.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

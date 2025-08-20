// lib/features/home/components/vitality_age_gauge.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/daily_providers.dart';

class _Donut extends StatelessWidget {
  final double progress; // 0..1
  final String centerText;
  final String? subText;
  const _Donut({required this.progress, required this.centerText, this.subText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 180.0;          // Slightly larger and centered
    const thickness = 12.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: thickness,
              color: theme.colorScheme.surfaceContainerHighest,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          // Progress (start at 12 o'clock)
          Transform.rotate(
            angle: -math.pi / 2,
            child: SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: thickness,
                color: theme.colorScheme.primary,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          // Center labels
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerText, style: theme.textTheme.headlineSmall),
              if (subText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: (theme.textTheme.bodySmall?.color ?? Colors.black)
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class VitalityAgeGauge extends ConsumerWidget {
  const VitalityAgeGauge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyViewProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // page padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row stays left aligned per design system, chart is centered under it.
          Row(
            children: [
              Text('Vitality age', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 6),
              const Icon(Icons.info_outline, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: daily.when(
              loading: () => const _Donut(progress: 0.0, centerText: '—', subText: 'years'),
              error: (_, __) => const _Donut(progress: 0.0, centerText: '—', subText: 'years'),
              data: (v) {
                final hasAge = !v.vitalityAge.isNaN;
                final hasRisk = !v.riskIndex.isNaN;
                final progress = hasRisk ? (1.0 - v.riskIndex).clamp(0.0, 1.0) : 0.5;
                final center = hasAge ? v.vitalityAge.toStringAsFixed(1) : '—';
                return _Donut(progress: progress, centerText: center, subText: 'years');
              },
            ),
          ),
        ],
      ),
    );
  }
}

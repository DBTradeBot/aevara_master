// lib/features/home/components/healthy_days_mini_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/daily_providers.dart';

class HealthyDaysMiniBar extends ConsumerWidget {
  const HealthyDaysMiniBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final daily = ref.watch(dailyViewProvider);

    Widget strip(int filled) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 8,
        children: List.generate(30, (i) {
          final on = i < filled;
          return Container(
            width: 8,
            height: 24,
            decoration: BoxDecoration(
              color: on ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // page padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Healthy days', style: theme.textTheme.bodyMedium),
              const SizedBox(width: 6),
              const Icon(Icons.info_outline, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: daily.when(
              loading: () => strip(0),
              error: (_, __) => strip(0),
              data: (v) {
                final hd = (!v.healthyDays30.isNaN && v.healthyDays30 >= 0)
                    ? v.healthyDays30.clamp(0, 30).round()
                    : 0;
                return strip(hd);
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: daily.maybeWhen(
              data: (v) {
                final hd = (!v.healthyDays30.isNaN && v.healthyDays30 >= 0)
                    ? v.healthyDays30.clamp(0, 30).round()
                    : 0;
                return Text(hd > 0 ? '$hd / 30' : '—', style: theme.textTheme.bodySmall);
              },
              orElse: () => Text('—', style: theme.textTheme.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}

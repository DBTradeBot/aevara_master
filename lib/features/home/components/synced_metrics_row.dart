// lib/features/home/components/synced_metrics_row.dart
//
// Row that shows synced metrics with status dots.

import 'package:flutter/material.dart';
import '../../../core/widgets/tiles/sync_status_dot.dart';

class SyncedMetricsRow extends StatelessWidget {
  final Map<String, (String value, SyncStatus status)> metrics;
  const SyncedMetricsRow({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics.entries.map((e) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.key, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(e.value.$1, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              SyncStatusDot(status: e.value.$2),
            ],
          ),
        );
      }).toList(),
    );
  }
}

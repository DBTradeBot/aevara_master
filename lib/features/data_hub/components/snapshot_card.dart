// lib/features/data_hub/components/snapshot_card.dart
//
// Shows a single metric snapshot with value + sync status.

import 'package:flutter/material.dart';
import '../../../core/widgets/tiles/sync_status_dot.dart';

class SnapshotCard extends StatelessWidget {
  final String title;
  final String value;
  final SyncStatus status;

  const SnapshotCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          SyncStatusDot(status: status),
        ],
      ),
    );
  }
}

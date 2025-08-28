// lib/features/data_hub/components/sources_status_row.dart
//
// Horizontal row of provider sync status chips.

import 'package:flutter/material.dart';
import '../../../core/widgets/tiles/sync_status_dot.dart';

class SourcesStatusRow extends StatelessWidget {
  final Map<String, SyncStatus> sources; // providerName → status

  const SourcesStatusRow({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sources.entries.map((e) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                SyncStatusDot(status: e.value, size: 10),
                const SizedBox(width: 6),
                Text(e.key, style: theme.textTheme.bodySmall),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:aevara_app/features/sync/sync_status_icon.dart';

class MetricsHeader extends StatelessWidget {
  const MetricsHeader({
    super.key,
    required this.state,
    this.lastSync,
    this.onSyncTap,
    this.showInstruction = false,
  });

  final SyncState state;
  final DateTime? lastSync;
  final VoidCallback? onSyncTap;
  final bool showInstruction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // Keep it super subtle and compact
    final label = state == SyncState.synced ? 'Synced' : 'Sync';
    const labelColor =
        Color(0xFF6B7280); // faint gray that matches your existing copy

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Metrics',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onSyncTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Your existing status dot API: (state, lastSync, onTap)
                    SyncStatusIcon(
                        state: state, lastSync: lastSync, onTap: onSyncTap),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: text.labelSmall?.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: .1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
if (showInstruction) { ...[
          const SizedBox(height: 6),
          Text(
            'Tap a metric to enter your data, or sync your wearable for automatic tracking.',
            style: text.bodySmall?.copyWith(color: labelColor),
          ),
        ],
      ],
    ); }
  }
}


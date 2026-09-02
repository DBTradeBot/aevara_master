import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_status_dot.dart';
import 'package:aevara_app/state/sync_status_provider.dart'
    show syncStatusDetailProvider, SyncStatusDetail;

/// Tappable LED-only status icon:
/// - Shows ONLY the colored dot
/// - On tap: opens a small legend with italic explainers and “what to do”
class SyncStatusIcon extends ConsumerWidget {
  final SyncStatus status;

  const SyncStatusIcon({
    super.key,
    required this.status,
  });

  String _labelFor(SyncStatus s) {
    switch (s) {
      case SyncStatus.connected:
        return 'Connected';
      case SyncStatus.stale:
        return 'Needs refresh (24–48h or yesterday incomplete)';
      case SyncStatus.disconnected:
        return 'No sync in >48h (or 2 days incomplete)';
      case SyncStatus.none:
        return 'Never synced';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(syncStatusDetailProvider);

    return Semantics(
      button: true,
      label: 'Sync status. Tap for details.',
      value: _labelFor(status),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _openLegend(context, detail),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
          child: SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: SyncStatusDot(status: status, size: 14, padding: EdgeInsets.zero),
            ),
          ),
        ),
      ),
    );
  }

  void _openLegend(BuildContext context, SyncStatusDetail detail) {
    final last = detail.lastFreshAtUtc;
    final age = detail.lastFreshAge;

    String freshness = 'Unknown freshness';
    if (last != null && age != null) {
      String human;
      if (age.inHours < 24) {
        human = '${age.inHours}h ago';
      } else if (age.inDays < 7) {
        human = '${age.inDays}d ago';
      } else {
        final dt = last.toLocal();
        human = '${dt.month}/${dt.day}/${dt.year}';
      }
      freshness = 'Last fresh data: $human';
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  const SizedBox(width: 4),
                  Text('Sync status', style: Theme.of(ctx).textTheme.titleMedium),
                ]),
                const SizedBox(height: 12),

                // Current status detail
                Row(
                  children: [
                    SyncStatusDot(
                      status: detail.status,
                      size: 12,
                      padding: const EdgeInsets.only(right: 8),
                    ),
                    Text(_labelFor(detail.status), style: Theme.of(ctx).textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '• $freshness\n• ${detail.reason}',
                    style: Theme.of(ctx)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'What to do: ${detail.action}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),

                // Legend for all colors (quick reference)
                _legendRow(ctx, SyncStatus.connected,
                    'Connected (≤24h or yesterday complete)'),
                _legendRow(ctx, SyncStatus.stale,
                    'Needs refresh (24–48h or yesterday incomplete)'),
                _legendRow(ctx, SyncStatus.disconnected,
                    'No sync in >48h (or two days incomplete)'),
                _legendRow(ctx, SyncStatus.none, 'Never synced (no history)'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _legendRow(BuildContext ctx, SyncStatus s, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SyncStatusDot(status: s, size: 12, padding: const EdgeInsets.only(right: 8)),
          Text(label, style: Theme.of(ctx).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

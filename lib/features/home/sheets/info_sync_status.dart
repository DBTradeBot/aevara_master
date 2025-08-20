// lib/features/home/sheets/info_sync_status.dart
import 'package:flutter/material.dart';

/// Explains what each sync status dot means.
/// NOTE: This sheet is informational only. The actual "connect" bottom sheet
/// opens from tapping the status dot (see sync_status_dot.dart).
class InfoSyncStatusSheet extends StatelessWidget {
  const InfoSyncStatusSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const InfoSyncStatusSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onVar = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Text('Sync status legend', style: theme.textTheme.titleLarge),
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
              'Each wearable or data source shows a small status dot so you can quickly tell if your data is up to date.',
              style: theme.textTheme.bodyMedium?.copyWith(color: onVar),
            ),
          ),
          const SizedBox(height: 16),

          // Legend rows
          const _LegendRow(
            emoji: '🟢',
            title: 'Green = Synced / Current',
            desc:
            'Data was received recently (within 24h for daily metrics).\n→ Your dashboard is fully up to date.',
          ),
          const SizedBox(height: 12),
          const _LegendRow(
            emoji: '🟡',
            title: 'Yellow = Partial / Stale',
            desc:
            'Some metrics haven’t updated in time (e.g. HRV is 2–3 days old).\n→ You can still see last values, but sync is falling behind.',
          ),
          const SizedBox(height: 12),
          const _LegendRow(
            emoji: '🔴',
            title: 'Red = Error / Disconnected',
            desc:
            'The source stopped syncing due to an error or expired login.\n→ Tap to reconnect or check the provider’s app.',
          ),
          const SizedBox(height: 12),
          const _LegendRow(
            emoji: '⚪',
            title: 'Gray = Not Connected',
            desc:
            'You haven’t connected this source yet.\n→ Tap to link Apple Health, Google Fit, Garmin, WHOOP, etc.',
          ),

          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tip',
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tap the status dot on your dashboard to connect a device or manage connections.',
              style: theme.textTheme.bodySmall?.copyWith(color: onVar),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.emoji,
    required this.title,
    required this.desc,
  });

  final String emoji;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: t.titleLarge),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.titleMedium),
              const SizedBox(height: 4),
              Text(desc, style: t.bodySmall?.copyWith(color: c.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

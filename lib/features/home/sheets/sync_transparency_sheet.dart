// lib/features/home/sheets/sync_transparency_sheet.dart
import 'package:flutter/material.dart';
import 'connect_providers_sheet.dart';

enum ProviderFreshness { fresh, stale, notConnected }

class SyncTransparencySheet extends StatelessWidget {
  const SyncTransparencySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SyncTransparencySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: replace with real provider statuses from devices_provider.dart
    final rows = <_Row>[
      _Row('Apple Health', ProviderFreshness.notConnected, ''),
      _Row('Garmin', ProviderFreshness.stale, '2 days ago'),
      _Row('Fitbit', ProviderFreshness.fresh, '< 6h'),
      _Row('WHOOP', ProviderFreshness.notConnected, ''),
    ];

    final overall = _computeOverall(rows);
    final overallLabel = switch (overall) {
      ProviderFreshness.fresh => 'Fresh',
      ProviderFreshness.stale => 'Some sources stale',
      ProviderFreshness.notConnected => 'No sources connected',
    };

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

          // Title + close
          Row(
            children: [
              Text('Sync transparency', style: theme.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              overallLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Rows
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (context, i) {
                final r = rows[i];
                return _ProviderRow(
                  name: r.name,
                  freshness: r.freshness,
                  detail: r.detail,
                  onTap: () async {
                    // If not connected -> connect flow; else -> details (for now connect).
                    await ConnectProvidersSheet.show(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Primary action
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => ConnectProvidersSheet.show(context),
              icon: const Icon(Icons.link),
              label: const Text('Connect devices'),
            ),
          ),
          const SizedBox(height: 8),

          // Why this matters
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Fresh data improves your readiness, sleep, and activity insights. '
                  'If a source is stale, some metrics may show lower confidence.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ProviderFreshness _computeOverall(List<_Row> rows) {
    final anyConnected = rows.any((r) => r.freshness != ProviderFreshness.notConnected);
    if (!anyConnected) return ProviderFreshness.notConnected;
    final anyStale = rows.any((r) => r.freshness == ProviderFreshness.stale);
    if (anyStale) return ProviderFreshness.stale;
    return ProviderFreshness.fresh;
  }
}

class _Row {
  final String name;
  final ProviderFreshness freshness;
  final String detail; // e.g., '< 6h' or '2 days ago'
  _Row(this.name, this.freshness, this.detail);
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.name,
    required this.freshness,
    required this.detail,
    required this.onTap,
  });

  final String name;
  final ProviderFreshness freshness;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (dot, label) = switch (freshness) {
      ProviderFreshness.fresh => (Colors.teal, 'Fresh'),
      ProviderFreshness.stale => (Colors.orange, 'Stale'),
      ProviderFreshness.notConnected => (Colors.red, 'Not connected'),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: theme.textTheme.titleMedium)),
            const SizedBox(width: 12),
            Text(
              freshness == ProviderFreshness.notConnected ? label : '$label (${detail.isEmpty ? '—' : detail})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

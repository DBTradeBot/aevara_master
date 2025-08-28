// lib/features/home/sheets/connect_providers_sheet.dart
import 'package:flutter/material.dart';

/// Bottom sheet that lets users pick & connect a wearable/data source.
/// This is UI-only for now; wire the onTap callbacks to your real flows.
class ConnectProvidersSheet extends StatelessWidget {
  const ConnectProvidersSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ConnectProvidersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providers = _allProviders;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Connect a device', style: theme.textTheme.titleLarge),
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
              'Choose a source. We’ll sync securely in the background.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: providers.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (context, i) {
                final p = providers[i];
                return _ProviderRow(
                  name: p.name,
                  platformHint: p.platformHint,
                  icon: p.icon,
                  onTap: () {
                    // TODO: route into actual connect flow per provider.
                    // For now, pop and maybe show a toast/snackbar.
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Starting connect: ${p.name}')),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.name,
    required this.platformHint,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final String platformHint;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    platformHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _Provider {
  final String name;
  final String platformHint;
  final IconData icon;
  const _Provider(this.name, this.platformHint, this.icon);
}

// Initial list (we can expand any time):
const List<_Provider> _allProviders = [
  _Provider('Apple Health', 'iOS', Icons.apple),
  _Provider('Google Fit', 'Android', Icons.android),
  _Provider('Fitbit', 'Wearable', Icons.watch),
  _Provider('Garmin', 'Wearable', Icons.watch),
  _Provider('WHOOP', 'Wearable', Icons.watch),
  _Provider('Oura', 'Wearable', Icons.watch),
  _Provider('Polar', 'Wearable', Icons.watch),
  _Provider('Suunto', 'Wearable', Icons.watch),
  _Provider('Withings', 'Wearables & Scales', Icons.monitor_weight),
  _Provider('Samsung Health', 'Android', Icons.favorite),
  _Provider('Strava', 'Activity platform', Icons.directions_run),
  _Provider('Peloton', 'Fitness equipment', Icons.fitness_center),
  _Provider('Zwift', 'Cycling/Running', Icons.pedal_bike),
];

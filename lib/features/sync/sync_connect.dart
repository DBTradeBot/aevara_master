// lib/features/sync/sync_connect.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../theme/aevara_theme.dart';

/// Status for a provider connection. You can expand later (e.g., paused).
enum SyncStatus { synced, stale, notConnected, error }

/// Result returned by the connect sheet when it closes.
enum SyncConnectResult { disconnected }

/// Typed provider row used by your dashboard and the sheet.
class SyncProviderStatus {
  final String id;
  final String label;
  final IconData icon;
  final SyncStatus status;
  final DateTime? lastSync;
  final bool needsAction;

  const SyncProviderStatus({
    required this.id,
    required this.label,
    required this.icon,
    this.status = SyncStatus.notConnected,
    this.lastSync,
    this.needsAction = false,
  });
}

typedef ProviderTap = void Function(String providerId);

Future<SyncConnectResult?> showSyncConnectSheet(
    BuildContext context, {
      List<SyncProviderStatus>? providers,
      required ProviderTap onProviderTap,
      required VoidCallback onOpenPrivacy,
    }) {
  final theme = Theme.of(context);
  final aev = theme.extension<AevaraTheme>();
  bool agreed = false;

  // Default list (used if you don't pass providers)
  final List<SyncProviderStatus> provs = providers ??
      const [
        SyncProviderStatus(id: 'apple',  label: 'Apple Health',        icon: Icons.apple),
        SyncProviderStatus(id: 'google', label: 'Google Fit / Health', icon: Icons.android),
        SyncProviderStatus(id: 'fitbit', label: 'Fitbit',              icon: Icons.watch_outlined),
        SyncProviderStatus(id: 'whoop',  label: 'WHOOP',               icon: Icons.fitness_center),
        SyncProviderStatus(id: 'garmin', label: 'Garmin',              icon: Icons.gps_fixed),
        SyncProviderStatus(id: 'oura',   label: 'Oura',                icon: Icons.blur_circular),
      ];

  return showModalBottomSheet<SyncConnectResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (c) {
      return StatefulBuilder(
        builder: (c, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(c).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // grab handle
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              Text(
                'Connect your health data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              // consent row — inline link, aligned, non-breaking "metrics"
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    // nudge to better align with first baseline
                    padding: const EdgeInsets.only(top: 2),
                    child: Checkbox(
                      value: agreed,
                      onChanged: (v) => setState(() => agreed = v ?? false),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.25),
                        children: [
                          const TextSpan(
                            text:
                            'I agree to share data from my connected accounts with Aevara '
                                'to calculate insights and show my\u00A0metrics. ',
                          ),
                          TextSpan(
                            text: 'Privacy & Security',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: aev?.primary ?? theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = onOpenPrivacy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose a provider', style: theme.textTheme.labelLarge),
              ),

              const SizedBox(height: 8),

              // providers list
              ...provs.map((p) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    (aev?.primary ?? theme.colorScheme.primary).withOpacity(0.1),
                    child: Icon(
                      p.icon,
                      color: aev?.primary ?? theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(p.label),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: agreed,
                  onTap: agreed ? () => onProviderTap(p.id) : null,
                );
              }),

              const SizedBox(height: 8),

              // Always show a small, faint testing disconnect button (returns a result)
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(SyncConnectResult.disconnected);
                  },
                  icon: const Icon(Icons.link_off, size: 16),
                  label: const Text('Disconnect (testing)'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                    (aev?.secondaryText ?? Colors.grey).withOpacity(.7),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    textStyle: theme.textTheme.labelSmall,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

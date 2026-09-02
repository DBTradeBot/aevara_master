// lib/features/sync/widgets/provider_grid.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/devices_provider.dart';
import '../../../state/user_providers.dart';
import '../../../theme/icons.dart';
import '../../onboarding/components/device_card.dart';
import '../fitbit_auth_webview_page.dart';
import '../../../core/widgets/tiles/sync_status_dot.dart' show SyncStatus, SyncStatusDot;

/// Public and safe to ship in client; keep via dart-define so you don’t commit it.
const String kFitbitClientId = String.fromEnvironment(
  'FITBIT_CLIENT_ID',
  defaultValue: 'REPLACE_WITH_CLIENT_ID',
);

/// Your Hosting callback handled by the server exchange.
const String kFitbitRedirectUri = 'https://vitalis-a8577.web.app/fitbit/callback';

const List<String> _fitbitScopes = <String>['activity', 'heartrate', 'sleep', 'profile'];

/// Reusable grid of providers used by both Onboarding and Settings.
/// - Tapping a connected card calls [onManage]
/// - Tapping a disconnected card calls [onConnect]
class ProviderGrid extends ConsumerWidget {
  const ProviderGrid({
    super.key,
    this.preselect,
    this.onManage,
    this.onConnect,
    this.busyProviderId,
  });

  final String? preselect;
  final Future<void> Function(String providerId)? onManage;
  final Future<void> Function(String providerId)? onConnect;
  final String? busyProviderId;

  static Future<void> showAsBottomSheet(BuildContext context, {String? preselect}) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ProviderGrid(preselect: preselect),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesA = ref.watch(deviceStatusProvider);
    final uid = ref.watch(currentUserIdProvider);

    Future<void> _connectFitbitInApp() async {
      if (uid == null || uid.isEmpty) return;

      if (kFitbitClientId == 'REPLACE_WITH_CLIENT_ID') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configure FITBIT_CLIENT_ID to connect Fitbit.')),
        );
        return;
      }

      final stateJson = jsonEncode(<String, String>{'uid': uid});
      final state = base64Url.encode(utf8.encode(stateJson)).replaceAll('=', '');
      final scopes = Uri.encodeComponent(_fitbitScopes.join(' '));
      final redirect = Uri.encodeComponent(kFitbitRedirectUri);
      final authUrl = Uri.parse(
        'https://www.fitbit.com/oauth2/authorize'
            '?response_type=code'
            '&client_id=$kFitbitClientId'
            '&redirect_uri=$redirect'
            '&scope=$scopes'
            '&state=$state',
      );

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => FitbitAuthWebViewPage(
            authorizeUrl: authUrl,
            redirectPrefix: kFitbitRedirectUri,
            onAuthorized: () async {
              await ref.read(devicesServiceProvider).fitbitFetchNowFor(
                uid,
                days: 30,
                backfill: true,
                reason: 'post_connect',
              );
            },
          ),
        ),
      );
    }

    Future<void> _openManage(String providerId) async {
      // The host can pass a custom handler (e.g., open ManageProviderSheet).
      if (onManage != null) {
        await onManage!(providerId);
        return;
      }
      // Fallback: do nothing (host should provide a handler).
    }

    Future<void> _openConnect(String providerId) async {
      // Allow host override.
      if (onConnect != null) {
        await onConnect!(providerId);
        return;
      }
      if (providerId == 'fitbit') {
        await _connectFitbitInApp();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${providerId[0].toUpperCase()}${providerId.substring(1)} is coming soon')),
        );
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connect your wearables', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Sync data from your wearables. Add more than one — we normalize to one story.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: statusesA.when(
                data: (map) {
                  final items = <_ProviderConfig>[
                    _ProviderConfig(
                      id: 'fitbit',
                      name: 'Fitbit',
                      asset: AevaraBrandIcons.fitbitPng,
                      color: AevaraBrandIcons.fitbit,
                    ),
                    _comingSoon('garmin', 'Garmin', AevaraBrandIcons.garminPng, AevaraBrandIcons.garmin),
                    _comingSoon('oura', 'Oura', AevaraBrandIcons.ouraPng, AevaraBrandIcons.oura),
                    _comingSoon('whoop', 'WHOOP', AevaraBrandIcons.whoopPng, AevaraBrandIcons.whoop),
                    _comingSoon('apple', 'Apple Health', AevaraBrandIcons.appleHealthPng, AevaraBrandIcons.apple, localStore: true),
                    _comingSoon('googlefit', 'Google Fit', AevaraBrandIcons.googleFitPng, AevaraBrandIcons.google, localStore: true),
                    _comingSoon('strava', 'Strava', AevaraBrandIcons.stravaPng, AevaraBrandIcons.strava),
                    _comingSoon('polar', 'Polar', AevaraBrandIcons.polarPng, AevaraBrandIcons.polar),
                  ];

                  return LayoutBuilder(
                    builder: (ctx, c) {
                      final cross = c.maxWidth >= 560 ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          childAspectRatio: 1.22,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final pc = items[i];
                          final status = map[pc.id] ?? SyncStatus.none;

                          Widget card = DeviceCard(
                            title: pc.name,
                            providerId: pc.id,
                            asset: pc.asset,
                            accentColor: pc.color,
                            status: status,
                            comingSoon: pc.comingSoon,
                            localStore: pc.localStore,
                            onConnect: () => _openConnect(pc.id),
                            onManage: () => _openManage(pc.id),
                            busy: busyProviderId == pc.id,
                          );

                          if (preselect == pc.id) {
                            card = AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              child: card,
                            );
                          }

                          return card;
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Couldn’t load device statuses.\n$e')),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'We only read sleep, recovery, and activity. Tap a card to connect or manage.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderConfig {
  final String id;
  final String name;
  final String asset;
  final Color color;
  final bool comingSoon;
  final bool localStore;

  _ProviderConfig({
    required this.id,
    required this.name,
    required this.asset,
    required this.color,
    this.comingSoon = false,
    this.localStore = false,
  });
}

_ProviderConfig _comingSoon(
    String id,
    String name,
    String asset,
    Color color, {
      bool localStore = false,
    }) {
  return _ProviderConfig(
    id: id,
    name: name,
    asset: asset,
    color: color,
    comingSoon: true,
    localStore: localStore,
  );
}

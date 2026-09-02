import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/devices_provider.dart';
import '../../state/user_providers.dart';
import '../../core/widgets/tiles/sync_status_dot.dart';
import '../../theme/icons.dart';
import '../onboarding/components/device_card.dart';
import 'manage_provider_sheet.dart';
import 'fitbit_auth_webview_page.dart';

/// Prefer passing at build time:
///   flutter run --dart-define=FITBIT_CLIENT_ID=23QMBJ
const String kFitbitClientId = String.fromEnvironment(
  'FITBIT_CLIENT_ID',
  defaultValue: 'REPLACE_WITH_CLIENT_ID',
);

/// Hosting callback that your Cloud Function uses to exchange the code.
/// Example: https://vitalis-a8577.web.app/fitbit/callback
const String kFitbitRedirectUri = 'https://vitalis-a8577.web.app/fitbit/callback';

const List<String> _fitbitScopes = <String>[
  'activity', 'heartrate', 'sleep', 'profile',
];

class ConnectProvidersSheet extends ConsumerWidget {
  const ConnectProvidersSheet({super.key, this.preselect});

  /// If provided, the grid highlights this provider.
  final String? preselect;

  static Future<void> show(BuildContext context, {String? preselect}) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ConnectProvidersSheet(preselect: preselect),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesA = ref.watch(deviceStatusProvider);
    final uid = ref.watch(currentUserIdProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connect your devices', style: Theme.of(context).textTheme.titleLarge),
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
                      connect: () => _connectFitbitInApp(context, ref, uid),
                      manage: () => _openManage(context, providerId: 'fitbit', uid: uid),
                    ),
                    _ProviderConfig(
                      id: 'garmin',
                      name: 'Garmin',
                      asset: AevaraBrandIcons.garminPng,
                      color: AevaraBrandIcons.garmin,
                      comingSoon: true,
                    ),
                    _ProviderConfig(
                      id: 'oura',
                      name: 'Oura',
                      asset: AevaraBrandIcons.ouraPng,
                      color: AevaraBrandIcons.oura,
                      comingSoon: true,
                    ),
                    _ProviderConfig(
                      id: 'whoop',
                      name: 'WHOOP',
                      asset: AevaraBrandIcons.whoopPng,
                      color: AevaraBrandIcons.whoop,
                      comingSoon: true,
                    ),
                    _ProviderConfig(
                      id: 'apple',
                      name: 'Apple Health',
                      asset: AevaraBrandIcons.appleHealthPng,
                      color: AevaraBrandIcons.apple,
                      comingSoon: true,
                      localStore: true,
                    ),
                    _ProviderConfig(
                      id: 'googlefit',
                      name: 'Google Fit',
                      asset: AevaraBrandIcons.googleFitPng,
                      color: AevaraBrandIcons.google,
                      comingSoon: true,
                      localStore: true,
                    ),
                    _ProviderConfig(
                      id: 'strava',
                      name: 'Strava',
                      asset: AevaraBrandIcons.stravaPng,
                      color: AevaraBrandIcons.strava,
                      comingSoon: true,
                    ),
                    _ProviderConfig(
                      id: 'polar',
                      name: 'Polar',
                      asset: AevaraBrandIcons.polarPng,
                      color: AevaraBrandIcons.polar,
                      comingSoon: true,
                    ),
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
                            onConnect: pc.connect,
                            onManage: pc.manage,
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

  // ─────────────────────────────────────────────── Connect (in-app WebView)

  Future<void> _connectFitbitInApp(BuildContext context, WidgetRef ref, String? uid) async {
    if (uid == null || uid.isEmpty) return;

    if (kFitbitClientId == 'REPLACE_WITH_CLIENT_ID') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configure FITBIT_CLIENT_ID to connect Fitbit.')),
      );
      return;
    }

    // Build authorize URL
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

    // Navigate to our in-app WebView page
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FitbitAuthWebViewPage(
          authorizeUrl: authUrl,
          redirectPrefix: kFitbitRedirectUri,
          onAuthorized: () async {
            // 🔁 Immediately request a 30-day backfill after connect
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

  // ─────────────────────────────────────────────── Manage flow

  Future<void> _openManage(BuildContext context,
      {required String providerId, required String? uid}) async {
    await ManageProviderSheet.show(context, providerId: providerId, uid: uid);
  }
}

class _ProviderConfig {
  final String id;
  final String name;
  final String asset;
  final Color color;
  final bool comingSoon;
  final bool localStore;
  final Future<void> Function()? connect;
  final Future<void> Function()? manage;

  _ProviderConfig({
    required this.id,
    required this.name,
    required this.asset,
    required this.color,
    this.comingSoon = false,
    this.localStore = false,
    this.connect,
    this.manage,
  });
}

// lib/features/onboarding/connect_page.dart
//
// Onboarding → Connect your wearables
// Matches the Devices page look-and-feel, with the same ProviderTile rows,
// "Last sync ..." subtitle, and tap behaviors.
//
// - If connected: opens ManageProviderSheet
// - If not connected: launches provider connect (Fitbit uses in-app WebView)
// - Includes the informational blurb at the top
//
// Requirements:
//   * assets/providers/*.png available
//   * FITBIT_CLIENT_ID via --dart-define or replace the default below

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/devices_provider.dart';
import '../../state/user_providers.dart';
import '../../core/widgets/tiles/provider_tile.dart';
import '../../core/widgets/tiles/sync_status_dot.dart';
import '../../theme/icons.dart';
import '../../routing/route_paths.dart';
import '../sync/manage_provider_sheet.dart';
import '../sync/fitbit_auth_webview_page.dart';
import 'dart:async' show unawaited;

/// Public and safe to ship in client; keep via dart-define so you don’t commit it.
const String kFitbitClientId = String.fromEnvironment(
  'FITBIT_CLIENT_ID',
  defaultValue: 'REPLACE_WITH_CLIENT_ID',
);

/// Your Hosting callback handled by fitbitCallback (already deployed)
const String kFitbitRedirectUri = 'https://vitalis-a8577.web.app/fitbit/callback';

/// Minimal Fitbit scopes we need
const List<String> _fitbitScopes = <String>['activity', 'heartrate', 'sleep', 'profile'];

/// Stream of the provider's last sync (UTC) as DateTime, or null if unknown.
/// Reads: users/{uid}/integrations/{providerId}.last_sync_utc (Firestore Timestamp)
final _lastSyncUtcProvider =
StreamProvider.family<DateTime?, _LastSyncKey>((ref, key) {
  final uid = key.uid;
  final providerId = key.providerId;
  if (uid == null || uid.isEmpty) return const Stream<DateTime?>.empty();

  final doc = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('integrations')
      .doc(providerId);

  return doc.snapshots().map((snap) {
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>?;

    final ts = (data?['last_sync_utc'] ??
        data?['lastSyncUtc'] ??
        data?['last_sync'] ??
        data?['lastSync']) as Timestamp?;
    return ts?.toDate();
  });
});

class _LastSyncKey {
  final String? uid;
  final String providerId;
  const _LastSyncKey(this.uid, this.providerId);

  @override
  bool operator ==(Object other) =>
      other is _LastSyncKey && other.uid == uid && other.providerId == providerId;

  @override
  int get hashCode => Object.hash(uid, providerId);
}

String _formatLastSync(BuildContext context, DateTime? utc) {
  if (utc == null) return '';
  final dt = utc.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thatDay = DateTime(dt.year, dt.month, dt.day);
  final days = today.difference(thatDay).inDays;
  final t = TimeOfDay.fromDateTime(dt).format(context);
  if (days == 0) return 'Last sync Today, $t';
  if (days == 1) return 'Last sync Yesterday, $t';
  if (days < 7) return 'Last sync ${days}d ago';
  return 'Last sync ${dt.month}/${dt.day}/${dt.year}';
}

class ConnectPage extends ConsumerStatefulWidget {
  const ConnectPage({super.key});

  @override
  ConsumerState<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends ConsumerState<ConnectPage> {
  bool _launching = false;

  Future<void> _connectFitbitInApp() async {
    final uid = ref.read(currentUserIdProvider);
    if (!mounted) return;

    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to connect Fitbit.')),
      );
      return;
    }
    if (kFitbitClientId == 'REPLACE_WITH_CLIENT_ID') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set FITBIT_CLIENT_ID before connecting Fitbit.')),
      );
      return;
    }

    // Optional prefetch to keep backend warm
    unawaited(ref.read(devicesServiceProvider).fitbitFetchNowFor(uid));

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

    try {
      setState(() => _launching = true);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => FitbitAuthWebViewPage(
            authorizeUrl: authUrl,
            redirectPrefix: kFitbitRedirectUri,
            onAuthorized: () async {
              // 🔁 Immediately request a 30-day backfill after connect.
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finish Fitbit sign-in, then return to Aevara.')),
      );
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pushNamedAndRemoveUntil(RoutePaths.home, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final statusesA = ref.watch(deviceStatusProvider);
    final uid = ref.watch(currentUserIdProvider);
    final theme = Theme.of(context);
    final text = theme.textTheme;

    // Coming-soon providers: tapping should not open anything.
    const comingSoon = {'garmin', 'oura', 'whoop', 'strava', 'polar'};
    // Local stores (show info & later a native connect flow).
    const localStores = {'apple', 'googlefit'};

    Widget buildTile({
      required String id,
      required String title,
      String? fallbackSubtitle,
    }) {
      final lastSyncAsync =
      ref.watch(_lastSyncUtcProvider(_LastSyncKey(uid, id)));

      return lastSyncAsync.when(
        data: (dt) {
          final statuses =
              statusesA.asData?.value ?? const <String, SyncStatus>{};
          final status = statuses[id] ?? SyncStatus.none;
          final isConnected = status == SyncStatus.connected;

          final subtitle = isConnected
              ? (_formatLastSync(context, dt).isEmpty
              ? 'Connected'
              : _formatLastSync(context, dt))
              : (fallbackSubtitle ?? '');

          return ProviderTile(
            title: title,
            providerId: id,
            subtitle: subtitle,
            asset: AevaraBrandIcons.assetFor(id),
            accentColor: AevaraBrandIcons.colorFor(id),
            status: status,
            onTap: () async {
              if (comingSoon.contains(id)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title is coming soon')),
                );
                return;
              }
              if (isConnected) {
                ManageProviderSheet.show(context, providerId: id, uid: uid);
              } else {
                if (id == 'fitbit') {
                  await _connectFitbitInApp();
                } else if (localStores.contains(id)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reads from phone — coming soon')),
                  );
                }
              }
            },
          );
        },
        loading: () {
          final statuses =
              statusesA.asData?.value ?? const <String, SyncStatus>{};
          final status = statuses[id] ?? SyncStatus.none;
          final isConnected = status == SyncStatus.connected;

          return ProviderTile(
            title: title,
            providerId: id,
            subtitle: isConnected ? 'Checking last sync…' : (fallbackSubtitle ?? ''),
            asset: AevaraBrandIcons.assetFor(id),
            accentColor: AevaraBrandIcons.colorFor(id),
            status: status,
            onTap: () {}, // disabled while loading
          );
        },
        error: (e, _) {
          final statuses =
              statusesA.asData?.value ?? const <String, SyncStatus>{};
          final status = statuses[id] ?? SyncStatus.none;
          final isConnected = status == SyncStatus.connected;

          return ProviderTile(
            title: title,
            providerId: id,
            subtitle: isConnected ? 'Last sync: unavailable' : (fallbackSubtitle ?? ''),
            asset: AevaraBrandIcons.assetFor(id),
            accentColor: AevaraBrandIcons.colorFor(id),
            status: status,
            onTap: () {
              if (isConnected) {
                ManageProviderSheet.show(context, providerId: id, uid: uid);
              }
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Connect your wearables')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero / Intro (from screen 1)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(.09),
                      theme.colorScheme.secondary.withOpacity(.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                      child: Icon(Icons.devices_other_outlined, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bring your data with you', style: text.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Connect Fitbit now. Apple Health, Google Fit, Garmin, Oura, WHOOP and others are coming soon.',
                            style: text.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // List of providers — same look as Devices page
              Expanded(
                child: statusesA.when(
                  data: (_) {
                    return ListView(
                      children: [
                        const SizedBox(height: 8),
                        buildTile(
                          id: 'fitbit',
                          title: 'Fitbit',
                          fallbackSubtitle: 'Sleep • Recovery • Activity',
                        ),
                        buildTile(id: 'garmin', title: 'Garmin', fallbackSubtitle: 'Coming soon'),
                        buildTile(id: 'oura', title: 'Oura', fallbackSubtitle: 'Coming soon'),
                        buildTile(id: 'whoop', title: 'WHOOP', fallbackSubtitle: 'Coming soon'),
                        buildTile(id: 'apple', title: 'Apple Health', fallbackSubtitle: 'Reads from phone'),
                        buildTile(id: 'googlefit', title: 'Google Fit', fallbackSubtitle: 'Reads from phone'),
                        buildTile(id: 'strava', title: 'Strava', fallbackSubtitle: 'Coming soon'),
                        buildTile(id: 'polar', title: 'Polar', fallbackSubtitle: 'Coming soon'),
                        const SizedBox(height: 24),
                        if (uid != null)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Tip: Connect more than one — we normalize to one story.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Couldn’t load device statuses.\n$e')),
                ),
              ),

              // Privacy & copy footnote
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We only read sleep, recovery, and activity. Tap a row to connect or manage.',
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: _finishOnboarding,
              child: const Text('Skip for now'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _finishOnboarding,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _launching
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

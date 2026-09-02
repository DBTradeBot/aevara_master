import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' as cf;

import '../../state/devices_provider.dart';
import '../../state/user_providers.dart';
import '../../theme/icons.dart';
import '../../core/widgets/tiles/sync_status_dot.dart';
import 'fitbit_auth_webview_page.dart';

const String kFitbitClientId = String.fromEnvironment(
  'FITBIT_CLIENT_ID',
  defaultValue: 'REPLACE_WITH_CLIENT_ID',
);

const String kFitbitRedirectUri = 'https://vitalis-a8577.web.app/fitbit/callback';
const List<String> _fitbitScopes = <String>['activity', 'heartrate', 'sleep', 'profile'];

class ManageProviderSheet extends ConsumerWidget {
  const ManageProviderSheet({
    super.key,
    required this.providerId,
    this.uid,
  });

  final String providerId;
  final String? uid;

  static Future<void> show(BuildContext context, {required String providerId, String? uid}) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ManageProviderSheet(providerId: providerId, uid: uid),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = uid ?? ref.watch(currentUserIdProvider);
    final color = AevaraBrandIcons.colorFor(providerId);
    final logo = AevaraBrandIcons.assetFor(providerId);
    final statuses = ref.watch(deviceStatusProvider).asData?.value ?? const {};
    final status = statuses[providerId] ?? SyncStatus.none;

    final integDoc = (userId == null || userId.isEmpty)
        ? Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
        : FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('integrations')
        .doc(providerId)
        .snapshots();

    // ✅ Correct path: users/{uid}/days/{YYYY-MM-DD}
    final now = DateTime.now();
    final dayId =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final freshDoc = (userId == null || userId.isEmpty)
        ? Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
        : FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('days')
        .doc(dayId)
        .snapshots();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: integDoc,
          builder: (context, snap) {
            final data = snap.data?.data();
            final ts = (data?['last_sync_utc'] ??
                data?['lastSyncUtc'] ??
                data?['last_sync'] ??
                data?['lastSync']) as Timestamp?;
            final last = ts?.toDate().toLocal();
            final lastStr = _fmtLastSync(context, last);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(.10),
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: AssetImage(logo),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _titleFor(providerId),
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SyncStatusDot(status: status, size: 14),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lastStr.isEmpty ? 'Connected' : lastStr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: -6,
                  children: [
                    _chip(context, 'Sleep'),
                    _chip(context, 'Recovery'),
                    _chip(context, 'Activity'),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 24),

                // Optional freshness row (if we can infer it)
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: freshDoc,
                  builder: (context, daySnap) {
                    final d = daySnap.data?.data() ?? const <String, dynamic>{};
                    final chips = _freshnessChips(context, d);
                    if (chips.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Wrap(spacing: 8, runSpacing: -6, children: chips),
                    );
                  },
                ),

                _fullWidthButton(
                  context,
                  label: 'Sync now',
                  onPressed: (userId == null)
                      ? null
                      : () async {
                    if (providerId == 'fitbit') {
                      // ✅ 14-day coverage/backfill on manual “Sync now”
                      await ref.read(devicesServiceProvider).fitbitFetchNowFor(
                        userId,
                        days: 14,
                        backfill: true,
                        reason: 'manual_sync',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Requested Fitbit 14-day backfill')),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sync-now not available for this provider yet'),
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reconnect'),
                  onPressed: () async {
                    if (userId == null) return;
                    if (providerId == 'fitbit') {
                      await _reconnectFitbitInApp(context, ref, userId);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reconnect not implemented yet')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'We auto-sync several times a day. If your wearable app hasn’t pushed data yet, open it first, then tap Sync now.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.link_off, color: Colors.redAccent),
                    label: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
                    onPressed: (userId == null)
                        ? null
                        : () async {
                      final ok = await _confirmDisconnect(context);
                      if (!ok) return;

                      try {
                        final fn = cf.FirebaseFunctions.instanceFor(region: 'us-central1')
                            .httpsCallable(
                          'disconnectProviderCall',
                          options: cf.HttpsCallableOptions(timeout: const Duration(seconds: 30)),
                        );
                        final res = await fn.call<Map<String, dynamic>>({
                          'uid': userId,
                          'providerId': providerId,
                          'deleteVendorData': false,
                        });
                        final success = res.data['ok'] == true;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Disconnected' : 'Failed to disconnect')),
                          );
                          if (success) Navigator.of(context).maybePop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Disconnect failed: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _titleFor(String id) {
    switch (id) {
      case 'fitbit':
        return 'Fitbit';
      case 'garmin':
        return 'Garmin';
      case 'oura':
        return 'Oura';
      case 'whoop':
        return 'WHOOP';
      case 'apple':
        return 'Apple Health';
      case 'googlefit':
        return 'Google Fit';
      case 'strava':
        return 'Strava';
      case 'polar':
        return 'Polar';
      default:
        return id;
    }
  }

  String _fmtLastSync(BuildContext context, DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final d = today.difference(that).inDays;
    final t = TimeOfDay.fromDateTime(dt).format(context);
    if (d == 0) return 'Last sync Today, $t';
    if (d == 1) return 'Last sync Yesterday, $t';
    if (d < 7) return 'Last sync ${d}d ago';
    return 'Last sync ${dt.month}/${dt.day}/${dt.year}';
  }

  List<Widget> _freshnessChips(BuildContext context, Map<String, dynamic> day) {
    final chips = <Widget>[];
    Chip mk(String label, DateTime? last) {
      final age = (last == null) ? null : DateTime.now().difference(last);
      String text;
      final cs = Theme.of(context).colorScheme;
      if (age == null) {
        text = '$label • unknown';
      } else if (age.inHours <= 36) {
        text = '$label • Fresh';
      } else if (age.inHours <= 72) {
        text = '$label • 1–3d stale';
      } else {
        text = '$label • 3d+ stale';
      }
      return Chip(
        label: Text(text),
        backgroundColor: cs.surfaceVariant,
        side: BorderSide(color: cs.outlineVariant),
        visualDensity: VisualDensity.compact,
      );
    }

    DateTime? _toDt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final sleep = _toDt(day['sleep_last_utc'] ?? day['sleep_at_utc']);
    final hrv = _toDt(day['hrv_last_utc'] ?? day['last_hrv_utc']);
    final steps = _toDt(day['steps_last_utc'] ?? day['activity_last_utc']);

    if (sleep != null) chips.add(mk('Sleep', sleep));
    if (hrv != null) chips.add(mk('HRV', hrv));
    if (steps != null) chips.add(mk('Steps', steps));

    return chips;
  }

  Widget _chip(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      label: Text(text),
      backgroundColor: cs.surfaceVariant,
      side: BorderSide(color: cs.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _fullWidthButton(BuildContext context, {required String label, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label),
        ),
      ),
    );
  }

  Future<void> _reconnectFitbitInApp(BuildContext context, WidgetRef ref, String uid) async {
    if (kFitbitClientId == 'REPLACE_WITH_CLIENT_ID') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configure FITBIT_CLIENT_ID to reconnect Fitbit.')),
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
            // ✅ 14-day coverage/backfill on post-connect
            await ref.read(devicesServiceProvider).fitbitFetchNowFor(
              uid,
              days: 14,
              backfill: true,
              reason: 'post_reconnect',
            );
          },
        ),
      ),
    );
  }

  Future<bool> _confirmDisconnect(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect device?'),
        content: const Text(
          'We’ll stop syncing from this provider. Previously imported data will remain unless you delete it from Data & Privacy.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    return result == true;
  }
}

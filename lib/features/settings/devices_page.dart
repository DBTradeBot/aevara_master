// lib/features/settings/devices_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/widgets/tiles/provider_tile.dart';
import '../../theme/icons.dart';
import '../../state/devices_provider.dart';
import '../../state/user_providers.dart';
import '../sync/widgets/provider_grid.dart';
import '../sync/manage_provider_sheet.dart';
import '../../core/widgets/tiles/sync_status_dot.dart' show SyncStatus, SyncStatusDot;

/// Stream of the provider's last sync (UTC) as DateTime, or null if unknown.
final lastSyncUtcProvider = StreamProvider.family<DateTime?, _LastSyncKey>((ref, key) {
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

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesA = ref.watch(deviceStatusProvider);
    final uid = ref.watch(currentUserIdProvider);

    const comingSoon = {'garmin', 'oura', 'whoop', 'strava', 'polar'};
    const localStores = {'apple', 'googlefit'};

    Widget buildTile({
      required String id,
      required String title,
      String? fallbackSubtitle,
    }) {
      final lastSyncAsync = ref.watch(lastSyncUtcProvider(_LastSyncKey(uid, id)));

      return lastSyncAsync.when(
        data: (dt) {
          final statuses = statusesA.asData?.value ?? const <String, SyncStatus>{};
          final status = statuses[id] ?? SyncStatus.none;
          final isConnected = status == SyncStatus.connected;

          final subtitle = isConnected
              ? (_formatLastSync(context, dt).isEmpty ? 'Connected' : _formatLastSync(context, dt))
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
                await ManageProviderSheet.show(context, providerId: id, uid: uid);
              } else {
                await ProviderGrid.showAsBottomSheet(context, preselect: id);
              }
            },
          );
        },
        loading: () {
          final statuses = statusesA.asData?.value ?? const <String, SyncStatus>{};
          final status = statuses[id] ?? SyncStatus.none;
          final isConnected = status == SyncStatus.connected;

          return ProviderTile(
            title: title,
            providerId: id,
            subtitle: isConnected ? 'Checking last sync…' : (fallbackSubtitle ?? ''),
            asset: AevaraBrandIcons.assetFor(id),
            accentColor: AevaraBrandIcons.colorFor(id),
            status: status,
            onTap: () async {
              if (comingSoon.contains(id)) return;
              if (isConnected) {
                await ManageProviderSheet.show(context, providerId: id, uid: uid);
              } else {
                await ProviderGrid.showAsBottomSheet(context, preselect: id);
              }
            },
          );
        },
        error: (e, _) {
          final statuses = statusesA.asData?.value ?? const <String, SyncStatus>{};
          final status = statuses[id] ?? SyncStatus.none;
          final isConnected = status == SyncStatus.connected;

          return ProviderTile(
            title: title,
            providerId: id,
            subtitle: isConnected ? 'Last sync: unavailable' : (fallbackSubtitle ?? ''),
            asset: AevaraBrandIcons.assetFor(id),
            accentColor: AevaraBrandIcons.colorFor(id),
            status: status,
            onTap: () async {
              if (comingSoon.contains(id)) return;
              if (isConnected) {
                await ManageProviderSheet.show(context, providerId: id, uid: uid);
              } else {
                await ProviderGrid.showAsBottomSheet(context, preselect: id);
              }
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Connect',
            onPressed: () => ProviderGrid.showAsBottomSheet(context),
          ),
        ],
      ),
      body: statusesA.when(
        data: (_) {
          return ListView(
            children: [
              const SizedBox(height: 8),
              buildTile(id: 'fitbit', title: 'Fitbit', fallbackSubtitle: 'Sleep • Recovery • Activity'),
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
    );
  }
}

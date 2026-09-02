// lib/state/sync_status_provider.dart
//
// Sync status (LED) with "yesterday-first" rule + human explainers.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Canonical enum lives in sync_status_dot.dart
import 'package:aevara_app/core/widgets/tiles/sync_status_dot.dart' show SyncStatus;

import 'package:aevara_app/data/contracts/firestore_contracts_v1.dart' as Fx;
import 'user_providers.dart'; // provides currentUserIdProvider

/* Helpers */

String _todayKeyLocal() {
  final now = DateTime.now();
  String p2(int n) => n < 10 ? '0$n' : '$n';
  return '${now.year}-${p2(now.month)}-${p2(now.day)}';
}

String _daysAgoKeyLocal(int daysAgo) {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
  String p2(int n) => n < 10 ? '0$n' : '$n';
  return '${d.year}-${p2(d.month)}-${p2(d.day)}';
}

DateTime? _tryParseUtc(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String && v.isNotEmpty) {
    try {
      return DateTime.parse(v);
    } catch (_) {}
  }
  return null;
}

Map<String, dynamic> _m(Object? x) =>
    (x is Map ? x.cast<String, dynamic>() : const <String, dynamic>{});

/* Public streams */

final todayDailyDocSnapProvider =
StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.empty();
  final key = _todayKeyLocal();
  final docRef =
  FirebaseFirestore.instance.collection(Fx.FirestorePathsV1.days(uid)).doc(key);
  return docRef.snapshots();
});

final integrationsEverConnectedProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream<bool>.value(false);

  final db = FirebaseFirestore.instance;
  const providers = <String>['fitbit', 'oura', 'garmin', 'whoop', 'apple', 'googlefit'];

  final controller = StreamController<bool>.broadcast();
  final subs = <StreamSubscription>[];
  var connectedMap = <String, bool>{for (final p in providers) p: false};

  void _emit() {
    final anyConnected = connectedMap.values.any((v) => v);
    controller.add(anyConnected);
  }

  for (final p in providers) {
    final sub = db.doc('integrations/$p/users/$uid').snapshots().listen(
          (snap) {
        final data = snap.data();
        final isConn = (data?['connected'] == true);
        connectedMap[p] = isConn;
        _emit();
      },
      onError: (_) {},
    );
    subs.add(sub);
  }

  controller.add(false);

  ref.onDispose(() async {
    for (final s in subs) {
      await s.cancel();
    }
    await controller.close();
  });

  return controller.stream.distinct();
});

/* Day doc helpers */

final dayDocProvider =
StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>?, int>(
        (ref, daysAgo) {
      final uid = ref.watch(currentUserIdProvider);
      if (uid == null) {
        return Stream<DocumentSnapshot<Map<String, dynamic>>?>.value(null);
      }
      final key = _daysAgoKeyLocal(daysAgo);
      final docRef =
      FirebaseFirestore.instance.collection(Fx.FirestorePathsV1.days(uid)).doc(key);
      return docRef.snapshots();
    });

bool? _extractResolved(Map<String, dynamic>? day) {
  if (day == null) return null;

  final vMissing = day['sync_missing'];
  if (vMissing is bool) return !vMissing;

  final vDays = day['sync_days'];
  if (vDays is bool) return vDays;

  final vResolved = day['sync_resolved'] ?? day['resolved'];
  if (vResolved is bool) return vResolved;

  return null;
}

/* Provenance window (fallback) */

class _ProvenanceWindow {
  final DateTime? newestProviderUtc;
  final bool anyProvenance;
  const _ProvenanceWindow({required this.newestProviderUtc, required this.anyProvenance});
}

final _provenance30dStreamProvider =
StreamProvider<_ProvenanceWindow>((ref) async* {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    yield const _ProvenanceWindow(newestProviderUtc: null, anyProvenance: false);
    return;
  }

  final db = FirebaseFirestore.instance;
  final startKey = _daysAgoKeyLocal(29);
  final endKey = _todayKeyLocal();

  final query = db
      .collection(Fx.FirestorePathsV1.days(uid))
      .orderBy(FieldPath.documentId)
      .startAt([startKey])
      .endAt([endKey]);

  await for (final snap in query.snapshots()) {
    DateTime? newest;
    var anyProv = false;

    for (final d in snap.docs) {
      final data = d.data();

      final lastSample = _m(data['last_provider_sample_utc']).values;
      final lastSync = _m(data['last_provider_sync_utc']).values;
      final sources = _m(data['sources']);

      if (sources.isNotEmpty) anyProv = true;

      final Iterable all = [...lastSample, ...lastSync];
      if (all.isNotEmpty) anyProv = true;

      for (final v in all) {
        final t = _tryParseUtc(v);
        if (t != null && (newest == null || t.isAfter(newest))) {
          newest = t;
        }
      }
    }

    yield _ProvenanceWindow(newestProviderUtc: newest, anyProvenance: anyProv);
  }
});

/* Detail model + providers */

class SyncStatusDetail {
  final SyncStatus status;
  final Duration? lastFreshAge; // null if unknown
  final DateTime? lastFreshAtUtc; // null if unknown
  final String reason; // short explainer
  final String action; // what user should do

  const SyncStatusDetail({
    required this.status,
    required this.reason,
    required this.action,
    this.lastFreshAge,
    this.lastFreshAtUtc,
  });
}

final syncStatusDetailProvider = Provider<SyncStatusDetail>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return const SyncStatusDetail(
      status: SyncStatus.none,
      reason: 'No device connected yet.',
      action: 'Connect a wearable to start syncing.',
    );
  }

  final ySnapAV = ref.watch(dayDocProvider(1));
  final d2SnapAV = ref.watch(dayDocProvider(2));
  final provAV = ref.watch(_provenance30dStreamProvider);
  final integAV = ref.watch(integrationsEverConnectedProvider);

  final prov = provAV.value ??
      const _ProvenanceWindow(newestProviderUtc: null, anyProvenance: false);

  final yDay = ySnapAV.value?.data();
  final d2Day = d2SnapAV.value?.data();

  final yResolved = _extractResolved(yDay);
  final d2Resolved = _extractResolved(d2Day);

  SyncStatusDetail mk(SyncStatus s, String reason, String action) {
    final last = prov.newestProviderUtc?.toUtc();
    final age = last == null ? null : DateTime.now().toUtc().difference(last);
    return SyncStatusDetail(
      status: s,
      reason: reason,
      action: action,
      lastFreshAtUtc: last,
      lastFreshAge: age,
    );
  }

  if (yResolved != null) {
    if (yResolved == true) {
      return mk(
        SyncStatus.connected,
        'Yesterday’s data is complete.',
        'No action needed.',
      );
    }
    if (d2Resolved == false) {
      return mk(
        SyncStatus.disconnected,
        'Two consecutive days look incomplete.',
        'Open your wearable’s app to force a push, then tap “Sync now”. If that fails, disconnect and reconnect the provider.',
      );
    }
    return mk(
      SyncStatus.stale,
      'Yesterday looks incomplete or delayed.',
      'Open your wearable’s app/dashboard to sync, then tap “Sync now”.',
    );
  }

  bool everSynced = prov.anyProvenance;
  if (!everSynced && integAV.hasValue) {
    everSynced = integAV.value ?? false;
  }
  if (!everSynced) {
    return const SyncStatusDetail(
      status: SyncStatus.none,
      reason: 'No sync seen yet.',
      action: 'Connect a wearable to start syncing.',
    );
  }

  final newest = prov.newestProviderUtc;
  if (newest != null) {
    final age = DateTime.now().toUtc().difference(newest.toUtc());
    if (age <= const Duration(hours: 24)) {
      return mk(
        SyncStatus.connected,
        'Latest data is ≤24h old.',
        'No action needed.',
      );
    }
    if (age <= const Duration(hours: 48)) {
      return mk(
        SyncStatus.stale,
        'Latest data is 24–48h old.',
        'Open your wearable’s app, then tap “Sync now”.',
      );
    }
    return mk(
      SyncStatus.disconnected,
      'No fresh data in >48h.',
      'Open your wearable’s app. If nothing arrives, disconnect and reconnect the provider.',
    );
  }

  return mk(
    SyncStatus.stale,
    'Data freshness is unknown.',
    'Open your wearable’s app, then tap “Sync now”.',
  );
});

/* Simple status (LED color only) */

final syncStatusProvider = Provider<SyncStatus>((ref) {
  final detail = ref.watch(syncStatusDetailProvider);
  return detail.status;
});

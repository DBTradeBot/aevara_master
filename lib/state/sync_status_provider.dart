import 'package:aevara/data/contracts/firestore_contracts_v1.dart' as Fx;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aevara_app/state/app_providers.dart';
import 'package:aevara_app/core/widgets/tiles/sync_status_dot.dart';

final _firestore = FirebaseFirestore.instance;

String _todayKeyLocal() {
  final now = DateTime.now();
  String p2(int n) => n < 10 ? '0$n' : '$n';
  return '${now.year}-${p2(now.month)}-${p2(now.day)}';
}

final todayDailyDocSnapProvider =
StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const Stream.empty();
  final key = _todayKeyLocal();
  final docRef =
  _firestore.collection(Fx.FirestorePathsV1.days(uid)).doc(key);
  return docRef.snapshots();
});

final userIntegrationsSnapProvider =
StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const Stream.empty();
  // NOTE: Using users/{uid}/integrations/{provider}
  // If your path is different, tell me and I’ll switch it.
  return _firestore.collection('users').doc(uid).collection('integrations').snapshots();
});

final syncStatusProvider = Provider<SyncStatus>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return SyncStatus.none;

  final integAsync = ref.watch(userIntegrationsSnapProvider);
  final todayAsync = ref.watch(todayDailyDocSnapProvider);

  if (integAsync.isLoading || todayAsync.isLoading) {
    return SyncStatus.none; // neutral while loading
  }

  final integSnap = integAsync.asData?.value;
  final todaySnap = todayAsync.asData?.value;

  // no integrations at all => never synced (grey)
  if (integSnap == null || integSnap.docs.isEmpty) {
    return SyncStatus.none;
  }

  bool anyConnected = false;
  DateTime? latestSyncUtc;
  for (final d in integSnap.docs) {
    final data = d.data();
    if (data['connected'] == true) anyConnected = true;

    final ts = data['last_sync_utc'];
    DateTime? t;
    if (ts is Timestamp) t = ts.toDate();
    if (ts is String) { try { t = DateTime.parse(ts); } catch (_) {} }
    if (t != null && (latestSyncUtc == null || t.isAfter(latestSyncUtc))) {
      latestSyncUtc = t;
    }
  }

  bool freshRecovery = false, freshSleep = false, freshActivity = false, freshAffect = false;
  if (todaySnap != null && todaySnap.exists) {
    final data = todaySnap.data() ?? const <String, dynamic>{};
    final staleDays = (data['stale_days'] as Map?)?.cast<String, dynamic>() ?? const {};

    int? sd(String k) {
      final v = staleDays[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    final hrv = sd('hrv_rmssd_ms');
    final rhr = sd('rhr_bpm');
    freshRecovery = (hrv != null && hrv <= 1) || (rhr != null && rhr <= 1);

    final slp = sd('sleep_total_hours');
    freshSleep = (slp != null && slp <= 1);

    final steps = sd('steps_count');
    freshActivity = (steps != null && steps <= 1);

    final mood = sd('mood_level_1to5');
    final stress = sd('stress_level_1to5');
    freshAffect = (mood != null && mood <= 1) || (stress != null && stress <= 1);
  }

  final freshCount = [freshRecovery, freshSleep, freshActivity, freshAffect].where((b) => b).length;

  final now = DateTime.now().toUtc();
  Duration? sinceLatest;
  if (latestSyncUtc != null) sinceLatest = now.difference(latestSyncUtc.toUtc());

  final tooOld = sinceLatest != null && sinceLatest > const Duration(days: 7);
  if (!anyConnected || tooOld || freshCount == 0) return SyncStatus.disconnected;

  final recent = sinceLatest != null && sinceLatest <= const Duration(hours: 24);
  if (recent && freshCount >= 3) return SyncStatus.connected;

  return SyncStatus.stale;
});



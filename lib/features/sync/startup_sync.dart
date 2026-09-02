// Startup Vitality bootstrap:
//   • If user has <14 day docs → do a one-time 14-day vendor pull (backfill=true)
//   • Else → the usual priority 4-day pull (backfill=false)
//   • Then fast computes for the last 4 days
//
// Notes:
//   - No 30-day sweep here.
//   - We only *trigger* a 14-day vendor backfill when the `days` collection has
//     fewer than 14 docs; server-side ensures missing/incomplete days are filled.
//   - On every login/pull after a full 14-day history exists, we always do 4 days.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../state/user_providers.dart';
import '../../state/app_providers.dart' as app_state;
import '../../state/devices_provider.dart';

class StartupSync extends ConsumerStatefulWidget {
  const StartupSync({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<StartupSync> createState() => _StartupSyncState();
}

class _StartupSyncState extends ConsumerState<StartupSync> {
  String? _uid;
  bool _firedThisRun = false;
  ProviderSubscription<String?>? _authSub;

  @override
  void initState() {
    super.initState();
    _uid = ref.read(currentUserIdProvider);
    _maybeTrigger();

    _authSub = ref.listenManual<String?>(
      currentUserIdProvider,
          (prev, next) {
        if (next != _uid) {
          _uid = next;
          _firedThisRun = false;
          _maybeTrigger();
        }
      },
    );
  }

  @override
  void dispose() {
    try {
      _authSub?.close();
    } catch (_) {}
    super.dispose();
  }

  Future<bool> _hasAtLeastNDayDocs(String uid, {int n = 14}) async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('days')
          .orderBy(FieldPath.documentId, descending: true)
          .limit(n)
          .get();
      return qs.docs.length >= n;
    } catch (_) {
      // On any error, assume not enough docs so we err on filling.
      return false;
    }
  }

  Future<void> _maybeTrigger() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    if (_firedThisRun) return;

    _firedThisRun = true;

    try {
      // Decide coverage window:
      //   - If fewer than 14 day docs exist → pull 14 with backfill=true (one-time catch-up)
      //   - Else → standard 4-day priority pull, backfill=false
      final has14 = await _hasAtLeastNDayDocs(uid, n: 14);

      final int daysWindow = has14 ? 4 : 14;
      final bool backfill = has14 ? false : true;
      final String reason = has14 ? 'startup_sync' : 'startup_ensure14';

      if (kDebugMode) {
        debugPrint(
          '[StartupSync] uid=$uid daysWindow=$daysWindow backfill=$backfill reason=$reason',
        );
      }

      // 1) Vendor pull (Fitbit first; others when available)
      await ref.read(devicesServiceProvider).fitbitFetchNowFor(
        uid,
        days: daysWindow,
        backfill: backfill,
        includeCrf: false, // lightweight on startup
        reason: reason,
      );

      // 2) Fast computes for the last 4 days (keeps UI snappy)
      await ref
          .read(app_state.computeServiceProvider)
          .computeRangeFor(uid, days: 4, allowBackfill: true, source: reason);
    } catch (e) {
      if (kDebugMode) debugPrint('[StartupSync] bootstrap failed: $e');
      _firedThisRun = false; // allow retry on next auth change
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

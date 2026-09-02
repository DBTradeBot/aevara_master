// Firestore implementation of DailyService.
// Writes/reads at users/{uid}/days/{YYYY-MM-DD} to match readers/providers.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aevara_app/data/contracts/firestore_contracts_v1.dart' as Fx;
import '../../../core/services/time_service.dart';
import '../../services/daily_service.dart';

class DailyServiceFirestore implements DailyService {
  DailyServiceFirestore({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _todayRef(String uid) {
    final dayKey = TimeService.instance.todayKey();
    return _db.doc(Fx.FirestorePathsV1.dayDoc(uid, dayKey));
  }

  @override
  Future<Map<String, dynamic>?> getToday(String uid) async {
    final ref = _todayRef(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      // Create a minimal stub so UI can rely on doc existence.
      final now = DateTime.now();
      await ref.set(<String, dynamic>{
        Fx.FirestoreFieldsV1.dateLocal: TimeService.instance.todayKey(),
        'tz_offset_min': now.timeZoneOffset.inMinutes,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final created = await ref.get();
      return created.data();
    }
    return snap.data();
  }

  @override
  Future<void> setToday(String uid, Map<String, dynamic> patch) async {
    final ref = _todayRef(uid);
    await ref.set(
      <String, dynamic>{
        ...patch,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

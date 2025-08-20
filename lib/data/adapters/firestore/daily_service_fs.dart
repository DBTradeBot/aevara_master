// lib/data/adapters/firestore/daily_service_fs.dart
// Firestore implementation of DailyService.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/time_service.dart';
import '../../services/daily_service.dart';

class DailyServiceFirestore implements DailyService {
  DailyServiceFirestore({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _todayRef(String uid) {
    final dayKey = TimeService.instance.todayKey();
    return _db.collection('user_daily').doc(uid).collection('days').doc(dayKey);
  }

  @override
  Future<Map<String, dynamic>?> getToday(String uid) async {
    final ref = _todayRef(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      // Create a minimal stub so UI can rely on doc existence.
      await ref.set(<String, dynamic>{
        'created_at': FieldValue.serverTimestamp(),
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

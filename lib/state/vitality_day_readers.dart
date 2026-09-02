import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aevara_app/data/contracts/firestore_contracts_v1.dart' as Fx;
import '../core/services/time_service.dart';

class VitalityDayView {
  final String dateKey;
  final double? vitalityAge;       // doc.vitality_age
  final int? riskIndexPct;         // doc.risk_index_pct
  final bool? healthyDay;          // doc.healthy_day
  final String? status;            // doc.display.status (provisional|final)
  final int? confidence;           // doc.score_confidence
  const VitalityDayView({
    required this.dateKey,
    this.vitalityAge,
    this.riskIndexPct,
    this.healthyDay,
    this.status,
    this.confidence,
  });
}

final _uidProvider = Provider<String?>((ref) => FirebaseAuth.instance.currentUser?.uid);

final todayDayDocStreamProvider = StreamProvider<VitalityDayView?>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid == null) return const Stream.empty();
  final key = TimeService.instance.todayKey();
  final path = Fx.FirestorePathsV1.dayDoc(uid, key);
  final stream = FirebaseFirestore.instance.doc(path).snapshots();
  return stream.map((snap) {
    if (!snap.exists) return VitalityDayView(dateKey: key);
    final d = snap.data()!;
    return VitalityDayView(
      dateKey: key,
      vitalityAge: (d['vitality_age'] is num) ? (d['vitality_age'] as num).toDouble() : null,
      riskIndexPct: (d['risk_index_pct'] is num) ? (d['risk_index_pct'] as num).toInt() : null,
      healthyDay: d['healthy_day'] as bool?,
      status: (d['display'] is Map ? (d['display']['status'] as String?) : null),
      confidence: (d['score_confidence'] is num) ? (d['score_confidence'] as num).toInt() : null,
    );
  });
});

/// 30-day mini bar (reads final/ provisional healthy_day + risk_index_pct)
final last30DaySummariesProvider = StreamProvider<List<VitalityDayView>>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid == null) return const Stream.empty();
  final col = FirebaseFirestore.instance
      .collection(Fx.FirestorePathsV1.days(uid))
      .orderBy(FieldPath.documentId, descending: true)
      .limit(30);
  return col.snapshots().map((qs) {
    final out = <VitalityDayView>[];
    for (final doc in qs.docs) {
      final d = doc.data();
      out.add(VitalityDayView(
        dateKey: doc.id,
        vitalityAge: (d['vitality_age'] is num) ? (d['vitality_age'] as num).toDouble() : null,
        riskIndexPct: (d['risk_index_pct'] is num) ? (d['risk_index_pct'] as num).toInt() : null,
        healthyDay: d['healthy_day'] as bool?,
        status: (d['display'] is Map ? (d['display']['status'] as String?) : null),
        confidence: (d['score_confidence'] is num) ? (d['score_confidence'] as num).toInt() : null,
      ));
    }
    return out.reversed.toList(growable: false);
  });
});

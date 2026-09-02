// lib/data/adapters/firestore/export_service_fs.dart
// Firestore implementation of ExportService.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/export_request.dart';
import '../../services/export_service.dart';

class ExportServiceFs implements ExportService {
  final FirebaseFirestore _db;
  ExportServiceFs({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  @override
  Stream<List<ExportRequest>> watchMyExports(String uid) {
    return userExportsRef(_db, uid)
        .orderBy('created_at_utc', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(ExportRequest.fromDoc).toList());
  }

  @override
  Future<ExportRequest?> getExport(String uid, String exportId) async {
    final doc = await userExportsRef(_db, uid).doc(exportId).get();
    if (!doc.exists) return null;
    return ExportRequest.fromDoc(doc);
  }

  @override
  Future<ExportRequest> requestExport(String uid, {Map<String, dynamic>? params}) async {
    final col = userExportsRef(_db, uid);
    final doc = col.doc(); // client-side id
    final now = FieldValue.serverTimestamp();
    await doc.set({
      'uid': uid,
      'status': ExportStatus.queued,
      'created_at_utc': now,
      'updated_at_utc': now,
      if (params != null) 'params': params,
    });
    // A backend worker (Functions) should pick this up and progress it.
    final snap = await doc.get();
    return ExportRequest.fromDoc(snap);
  }

  @override
  Future<void> cancelExport(String uid, String exportId) async {
    final ref = userExportsRef(_db, uid).doc(exportId);
    await ref.set({
      'status': ExportStatus.canceled,
      'updated_at_utc': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

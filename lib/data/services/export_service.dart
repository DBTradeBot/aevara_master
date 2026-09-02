// lib/data/services/export_service.dart
// Service contract + default singleton for user data export operations.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/export_request.dart';
import '../contracts/firestore_contracts_v1.dart';
import '../adapters/firestore/export_service_fs.dart';

abstract class ExportService {
  Stream<List<ExportRequest>> watchMyExports(String uid);
  Future<ExportRequest> requestExport(String uid, {Map<String, dynamic>? params});
  Future<void> cancelExport(String uid, String exportId);
  Future<ExportRequest?> getExport(String uid, String exportId);
}

/// Default singleton (Firestore-backed).
final ExportService exportService = ExportServiceFs();

/// Helper path (kept here so UI can link to same contract).
CollectionReference<Map<String, dynamic>> userExportsRef(FirebaseFirestore db, String uid) {
  // v1: keep exports under users/{uid}/exports
  return db.collection('${FirestorePathsV1.users}/$uid/exports');
}

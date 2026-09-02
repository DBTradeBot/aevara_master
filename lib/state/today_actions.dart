//
// Fire-and-forget compute trigger after manual inputs.
// Uses VITALITY_COMPUTE_URL and user ID token.
//

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:intl/intl.dart';
import '../core/env.dart' as env;
import 'package:aevara_app/data/contracts/firestore_contracts_v1.dart' as Fx;

/// yyyy-MM-dd in local time.
String todayKeyLocal() => DateFormat('yyyy-MM-dd').format(DateTime.now());

/// Exported so AppShell can guarantee a stub before compute.
Future<DocumentReference<Map<String, dynamic>>> ensureTodayDoc(String uid) async {
  final dateKey = todayKeyLocal();
  final ref = FirebaseFirestore.instance.doc(Fx.FirestorePathsV1.dayDoc(uid, dateKey));
  final snap = await ref.get();
  if (!snap.exists) {
    final now = DateTime.now();
    await ref.set({
      Fx.FirestoreFieldsV1.dateLocal: dateKey,
      'tz_offset_min': now.timeZoneOffset.inMinutes,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'display': {'status': 'provisional'},
    }, SetOptions(merge: true));
  }
  return ref;
}

Future<void> _triggerComputeIfConfigured() async {
  final url = env.VITALITY_COMPUTE_URL ?? env.COMPUTE_DAILY_URL; // prefer vNext
  if (url == null || url.isEmpty) return;
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final idToken = await user.getIdToken();

    final client = HttpClient()..badCertificateCallback = (_, __, ___) => false;
    final req = await client.postUrl(Uri.parse(url));
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
    final secret = (env.SYNC_SHARED_SECRET ?? '').trim();
    if (secret.isNotEmpty) {
      req.headers.set('x-sync-secret', secret);
    }
    // Server infers uid from token when allowed; sending empty body is fine.
    req.add(utf8.encode('{}'));
    final resp = await req.close();
    await resp.drain<void>();
    client.close(force: true);
  } catch (_) {
    // swallow; manual inputs still reflect immediately; scheduler/refresh covers compute
  }
}

class TodayActions {
  final Ref ref;
  TodayActions(this.ref);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> setSleepHours(double hours) async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await ensureTodayDoc(uid);
    await doc.set({
      'sleep_total_hours': hours,
      'sources.sleep_total_hours': 'manual',
      'stale_days.sleep_total_hours': 0,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _triggerComputeIfConfigured();
  }

  Future<void> setHrv(double rmssdMs) async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await ensureTodayDoc(uid);
    await doc.set({
      'hrv_rmssd_ms': rmssdMs,
      'sources.hrv_rmssd_ms': 'manual',
      'stale_days.hrv_rmssd_ms': 0,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _triggerComputeIfConfigured();
  }

  Future<void> setRhr(int bpm) async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await ensureTodayDoc(uid);
    await doc.set({
      'rhr_bpm': bpm,
      'sources.rhr_bpm': 'manual',
      'stale_days.rhr_bpm': 0,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _triggerComputeIfConfigured();
  }

  Future<void> setSteps(int steps) async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await ensureTodayDoc(uid);
    await doc.set({
      'steps_count': steps,
      'sources.steps_count': 'manual',
      'stale_days.steps_count': 0,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _triggerComputeIfConfigured();
  }

  /// Standalone Wellbeing metric (1 = best .. 5 = worst)
  Future<void> setWellbeingLevel({required int value1to5, String? note}) async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await ensureTodayDoc(uid);

    await doc.set({
      'wellbeing_level_1to5': value1to5.clamp(1, 5),
      'sources.wellbeing_level_1to5': 'manual',
      'stale_days.wellbeing_level_1to5': 0,
      if (note != null && note.isNotEmpty) 'notes_wellbeing': note,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _triggerComputeIfConfigured();
  }

  /// Legacy combo writer for separate mood/stress (kept for compatibility).
  Future<void> setWellbeing({
    int? mood1to5,
    int? stress1to5,
    String? notesMood,
    String? notesEnergy,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await ensureTodayDoc(uid);
    final data = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (mood1to5 != null) {
      data['mood_level_1to5'] = mood1to5;
      data['sources.mood_level_1to5'] = 'manual';
      data['stale_days.mood_level_1to5'] = 0;
    }
    if (stress1to5 != null) {
      data['stress_level_1to5'] = stress1to5;
      data['sources.stress_level_1to5'] = 'manual';
      data['stale_days.stress_level_1to5'] = 0;
    }
    if (notesMood != null) data['notes_mood'] = notesMood;
    if (notesEnergy != null) data['notes_energy'] = notesEnergy;

    await doc.set(data, SetOptions(merge: true));
    await _triggerComputeIfConfigured();
  }
}

final todayActionsProvider = Provider<TodayActions>((ref) => TodayActions(ref));

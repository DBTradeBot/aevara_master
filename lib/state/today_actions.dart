import 'package:aevara/data/contracts/firestore_contracts_v1.dart' as Fx;
// lib/state/today_actions.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../core/env.dart' as env;

/// Local YYYY-MM-DD based on device time zone.
String _todayKeyLocal() => DateFormat('yyyy-MM-dd').format(DateTime.now());

Future<DocumentReference<Map<String, dynamic>>> _ensureTodayDoc(
    String uid) async {
  final ref = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('days')
      .doc(_todayKeyLocal());
  final snap = await ref.get();
  if (!snap.exists) {
    final now = DateTime.now();
    await ref.set({
      'date_local': _todayKeyLocal(),
      'tz_offset_min': now.timeZoneOffset.inMinutes,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  return ref;
}

/// Fire-and-forget call to computeDailyHttp after writes.
/// Uses Firebase ID token for Authorization.
Future<void> _triggerComputeIfConfigured() async {
  final url = env.COMPUTE_DAILY_URL;
  if (url == null || url.isEmpty) return;
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final idToken = await user.getIdToken();

    final client = HttpClient()..badCertificateCallback = (_, __, ___) => false;
    final req = await client.postUrl(Uri.parse(url));
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
    req.add(utf8.encode('{}'));
    final resp = await req.close();
    await resp.drain<void>();
    client.close(force: true);
  } catch (e) {
    // Intentionally swallow; UI still shows saved manual inputs,
    // and compute can run later (via scheduler).
  }
}

class TodayActions {
  final Ref ref;
  TodayActions(this.ref);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> setSleepHours(double hours) async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await _ensureTodayDoc(uid);
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
    final doc = await _ensureTodayDoc(uid);
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
    final doc = await _ensureTodayDoc(uid);
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
    final doc = await _ensureTodayDoc(uid);
    await doc.set({
      'steps_count': steps,
      'sources.steps_count': 'manual',
      'stale_days.steps_count': 0,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _triggerComputeIfConfigured();
  }

  Future<void> setWellbeing({
    int? mood1to5,
    int? stress1to5,
    String? notesMood,
    String? notesEnergy,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await _ensureTodayDoc(uid);
    final data = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (mood1to5 != null) {
      data['mood_level_1to5'] = mood1to5;
      data['sources.mood_level_1to5'] = 'manual';
    }
    if (stress1to5 != null) {
      data['stress_level_1to5'] = stress1to5;
      data['sources.stress_level_1to5'] = 'manual';
    }
    if (notesMood != null) data['notes_mood'] = notesMood;
    if (notesEnergy != null) data['notes_energy'] = notesEnergy;

    await doc.set(data, SetOptions(merge: true));
    await _triggerComputeIfConfigured();
  }
}

final todayActionsProvider = Provider<TodayActions>((ref) => TodayActions(ref));



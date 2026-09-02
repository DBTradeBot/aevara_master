// lib/data/adapters/firestore/notifications_service_fs.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/app_notification.dart';

class NotificationsServiceFs {
  final FirebaseFirestore _fs;
  NotificationsServiceFs({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _fs.collection('users').doc(uid).collection('notifications');

  /// Create or upsert by custom id (idempotent) if provided, else add().
  Future<String> createOnce({
    required String uid,
    String? id,
    required AppNotifType type,
    required AppNotifCategory category,
    required AppNotifSeverity severity,
    required String title,
    String? body,
    String? icon,
    String? route,
    Map<String, dynamic>? routeArgs,
    String source = 'app',
    DateTime? stickyUntil,
    DateTime? expiresAt,
  }) async {
    final now = DateTime.now();
    final data = AppNotification(
      id: id ?? '',
      type: type,
      category: category,
      severity: severity,
      title: title,
      body: body,
      icon: icon,
      route: route,
      routeArgs: routeArgs,
      source: source,
      createdAt: now,
      readAt: null,
      archivedAt: null,
      stickyUntil: stickyUntil,
      expiresAt: expiresAt,
    ).toFirestore();

    if (id != null && id.isNotEmpty) {
      await _col(uid).doc(id).set({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));
      return id;
    } else {
      final doc = await _col(uid).add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
      });
      return doc.id;
    }
  }

  Stream<List<AppNotification>> streamForUser(String uid, {bool includeArchived = false}) {
    Query<Map<String, dynamic>> q =
    _col(uid).orderBy('created_at', descending: true).limit(200);
    if (!includeArchived) {
      q = q.where('archived_at', isNull: true);
    }
    return q.snapshots().map((snap) {
      final now = DateTime.now();
      return snap.docs
          .map((d) => AppNotification.fromFirestore(d.id, d.data()))
          .where((n) => n.expiresAt == null || n.expiresAt!.isAfter(now))
          .toList(growable: false);
    });
  }

  Stream<int> streamUnreadCount(String uid) {
    return _col(uid)
        .where('read_at', isNull: true)
        .where('archived_at', isNull: true)
        .snapshots()
        .map((s) {
      final now = DateTime.now();
      return s.docs
          .map((d) => AppNotification.fromFirestore(d.id, d.data()))
          .where((n) => n.expiresAt == null || n.expiresAt!.isAfter(now))
          .length;
    });
  }

  Future<void> markRead(String uid, String id) =>
      _col(uid).doc(id).update({'read_at': FieldValue.serverTimestamp()});

  Future<void> markUnread(String uid, String id) =>
      _col(uid).doc(id).update({'read_at': null});

  Future<void> archive(String uid, String id) =>
      _col(uid).doc(id).update({'archived_at': FieldValue.serverTimestamp()});

  Future<void> unarchive(String uid, String id) =>
      _col(uid).doc(id).update({'archived_at': null});

  Future<void> markAllRead(String uid) async {
    final batch = _fs.batch();
    final qs = await _col(uid)
        .where('read_at', isNull: true)
        .where('archived_at', isNull: true)
        .get();
    for (final d in qs.docs) {
      batch.update(d.reference, {'read_at': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  /// Clear short-lived (non-sticky, non-critical) notifications by archiving them.
  Future<int> clearEphemeral(String uid) async {
    final now = DateTime.now();
    final qs = await _col(uid).where('archived_at', isNull: true).get();
    int count = 0;
    final batch = _fs.batch();
    for (final d in qs.docs) {
      final n = AppNotification.fromFirestore(d.id, d.data());
      final shouldArchive = (n.expiresAt != null && n.expiresAt!.isBefore(now)) ||
          (n.severity == AppNotifSeverity.info && !n.isSticky);
      if (shouldArchive) {
        batch.update(d.reference, {'archived_at': FieldValue.serverTimestamp()});
        count++;
      }
    }
    if (count > 0) await batch.commit();
    return count;
  }
}

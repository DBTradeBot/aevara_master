// lib/state/notifications_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/adapters/firestore/notifications_service_fs.dart';
import '../data/models/app_notification.dart';
import 'user_providers.dart' as user_state;

final notificationsServiceProvider = Provider<NotificationsServiceFs>((ref) {
  return NotificationsServiceFs(firestore: FirebaseFirestore.instance);
});

/// Include archived so the UI can show "Archived" history via filter.
final notificationsListProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final uid = ref.watch(user_state.currentUserIdProvider);
  if (uid == null || uid.isEmpty) return const Stream.empty();
  final svc = ref.watch(notificationsServiceProvider);
  return svc.streamForUser(uid, includeArchived: true);
});

final unreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(user_state.currentUserIdProvider);
  if (uid == null || uid.isEmpty) return const Stream.empty();
  final svc = ref.watch(notificationsServiceProvider);
  return svc.streamUnreadCount(uid);
});

class NotificationsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}
  NotificationsServiceFs get _svc => ref.read(notificationsServiceProvider);
  String? get _uid => ref.read(user_state.currentUserIdProvider);

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _svc.markAllRead(uid));
  }

  Future<int> clearEphemeral() async {
    final uid = _uid;
    if (uid == null) return 0;
    state = const AsyncLoading();
    final res = await _svc.clearEphemeral(uid);
    state = const AsyncData(null);
    return res;
  }

  Future<void> markRead(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await _svc.markRead(uid, id);
  }

  Future<void> markUnread(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await _svc.markUnread(uid, id);
  }

  Future<void> archive(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await _svc.archive(uid, id);
  }

  Future<void> unarchive(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await _svc.unarchive(uid, id);
  }

  Future<String?> createCalibrationDismissed({
    required int day,
    required DateTime stickyUntil,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    final id =
        'system:calibration:dismissed:${DateTime.now().toUtc().toIso8601String().substring(0, 10)}';
    return _svc.createOnce(
      uid: uid,
      id: id,
      type: AppNotifType.calibrationBannerDismissed,
      category: AppNotifCategory.system,
      severity: AppNotifSeverity.info,
      title: 'Calibration running (14 days)',
      body:
      'We’ll keep calibrating quietly. Tap to learn more or re-open the banner.',
      icon: 'hourglass_empty',
      route: '/info/methods_doc',
      routeArgs: {'from:': 'notification'},
      stickyUntil: stickyUntil,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }
}

final notificationsControllerProvider =
AsyncNotifierProvider<NotificationsController, void>(() => NotificationsController());

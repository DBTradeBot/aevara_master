// lib/core/notifications/notification_overlay_host.dart
//
// Global in-app notification overlay host.
// Shows up to 3 active (unarchived, non-expired) notifications at the top,
// with slide/fade animations, tap-to-expand, swipe-to-dismiss (archive) and UNDO.
//
// NEW: Also synthesizes a "Calibration running (14 days)" banner from users/{uid}
// when calibration is active and the user hasn't dismissed the banner yet.
// Dismissing the synthetic banner sets users/{uid}.ui.calibration_banner_dismissed = true
// AND creates a persisted notification via createCalibrationDismissed(...).

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_notification.dart';
import '../../state/notifications_providers.dart';
import '../../state/user_providers.dart' as user_state;
import '../../routing/route_paths.dart';
import 'notification_banner.dart';

class NotificationOverlayHost extends ConsumerStatefulWidget {
  const NotificationOverlayHost({super.key});

  @override
  ConsumerState<NotificationOverlayHost> createState() => _NotificationOverlayHostState();
}

class _NotificationOverlayHostState extends ConsumerState<NotificationOverlayHost> {
  // Track auto-dismiss timers so we don't stack them when list rebuilds
  final Map<String, Timer> _timers = {};

  static const _maxVisible = 3;
  static const _autoDismiss = Duration(seconds: 7);

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }

  bool _shouldAutoDismiss(AppNotification n) {
    // Only info/success and not sticky should auto-dismiss
    final isInfoOrSuccess =
        n.severity == AppNotifSeverity.info || n.severity == AppNotifSeverity.success;
    return isInfoOrSuccess && !n.isSticky && n.archivedAt == null;
  }

  void _ensureTimer(AppNotification n) {
    if (!_shouldAutoDismiss(n)) return;
    if (_timers.containsKey(n.id)) return;
    _timers[n.id] = Timer(_autoDismiss, () async {
      if (!mounted) return;
      // Double-check still active & not archived
      final list = ref.read(notificationsListProvider).asData?.value ?? const <AppNotification>[];
      final still = list.firstWhere(
            (x) => x.id == n.id && x.archivedAt == null,
        orElse: () => n,
      );
      if (still.archivedAt == null) {
        await ref.read(notificationsControllerProvider.notifier).archive(n.id);
      }
      _timers.remove(n.id)?.cancel();
      if (mounted) setState(() {});
    });
  }

  // Build a synthetic calibration notification (local only) from the user doc.
  AppNotification _buildSyntheticCalibration({
    required int day,
  }) {
    return AppNotification(
      id: 'synthetic:calibration:active',
      type: AppNotifType.calibrationBannerDismissed, // reuse enum (display only)
      category: AppNotifCategory.system,
      severity: AppNotifSeverity.info,
      title: 'Calibration running (14 days)',
      body: 'We’ll calibrate quietly. Tap to learn more or dismiss the banner.',
      icon: 'hourglass_empty',
      route: RoutePaths.methodsDoc,
      routeArgs: const {'from': 'overlay'},
      source: 'synthetic',
      createdAt: DateTime.now(),
      readAt: null,
      archivedAt: null,
      stickyUntil: DateTime.now().add(const Duration(days: 14)),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(notificationsListProvider);

    // Listen to user to know whether calibration is active + not dismissed
    final uid = ref.watch(user_state.currentUserIdProvider);
    final userStream = (uid == null || uid.isEmpty)
        ? const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
        : FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userStream,
      builder: (ctx, userSnap) {
        // Parse user state for synthetic calibration
        bool showSyntheticCal = false;
        int calDay = 0;
        if (userSnap.hasData && userSnap.data!.exists) {
          final data = userSnap.data!.data() ?? {};
          final status = (data['calibration_status'] ?? 'complete').toString();
          final day = (data['calibration_day'] is int)
              ? data['calibration_day'] as int
              : int.tryParse('${data['calibration_day'] ?? 0}') ?? 0;
          final ui = (data['ui'] as Map?)?.cast<String, dynamic>();
          final hideFlag = (ui?['calibration_banner_dismissed'] == true);

          if (status != 'complete' && !hideFlag) {
            showSyntheticCal = true;
            calDay = day;
          }
        }

        return IgnorePointer(
          ignoring: false, // allow interactions
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: listAsync.when(
                data: (list) {
                  final now = DateTime.now();
                  final active = list
                      .where((n) => n.archivedAt == null)
                      .where((n) => n.expiresAt == null || n.expiresAt!.isAfter(now))
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  // De-duplicate: if an existing persisted calibration notice is present,
                  // do NOT show the synthetic one.
                  final hasPersistedCalibration = active.any((n) =>
                  n.title.toLowerCase().contains('calibration') ||
                      n.id.startsWith('system:calibration'));

                  final List<Widget> cards = [];

                  // 1) Optional synthetic calibration banner (top)
                  if (showSyntheticCal && !hasPersistedCalibration) {
                    final synthetic = _buildSyntheticCalibration(day: calDay);
                    cards.add(
                      _AnimatedInOut(
                        key: const ValueKey('overlay_slot_synthetic_cal'),
                        delayMs: 0,
                        child: NotificationBanner(
                          key: const ValueKey('overlay_card_synthetic_cal'),
                          notification: synthetic,
                          onDismiss: () async {
                            // Hide UI flag + create a persisted notification for history
                            if (uid != null && uid.isNotEmpty) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .set({
                                'ui': {'calibration_banner_dismissed': true}
                              }, SetOptions(merge: true));

                              await ref
                                  .read(notificationsControllerProvider.notifier)
                                  .createCalibrationDismissed(
                                day: calDay,
                                stickyUntil: DateTime.now().add(const Duration(days: 14)),
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Calibration banner dismissed'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                            setState(() {});
                          },
                          onOpen: () async {
                            if (!mounted) return;
                            Navigator.of(context).pushNamed(RoutePaths.methodsDoc);
                          },
                          onMarkRead: () async {
                            // No-op for synthetic (there is no read_at server state)
                          },
                        ),
                      ),
                    );
                  }

                  // 2) Up to 3 persisted notifications under it
                  final visible = active.take(_maxVisible - cards.length).toList();

                  // Setup auto-dismiss for each visible item (if applicable)
                  for (final n in visible) {
                    _ensureTimer(n);
                  }

                  for (int i = 0; i < visible.length; i++) {
                    cards.add(
                      _AnimatedInOut(
                        key: ValueKey('overlay_slot_$i'),
                        delayMs: 60 * (i + (showSyntheticCal && !hasPersistedCalibration ? 1 : 0)),
                        child: NotificationBanner(
                          key: ValueKey('overlay_card_${visible[i].id}'),
                          notification: visible[i],
                          onDismiss: () async {
                            // Archive + UNDO snackbar
                            await ref.read(notificationsControllerProvider.notifier).archive(visible[i].id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Dismissed'),
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () => ref
                                      .read(notificationsControllerProvider.notifier)
                                      .unarchive(visible[i].id),
                                ),
                              ),
                            );
                            setState(() {});
                          },
                          onOpen: () async {
                            final r = visible[i].route;
                            if (r != null && r.isNotEmpty) {
                              await ref
                                  .read(notificationsControllerProvider.notifier)
                                  .markRead(visible[i].id);
                              if (!mounted) return;
                              Navigator.of(context).pushNamed(r);
                            }
                          },
                          onMarkRead: () async {
                            if (!visible[i].isRead) {
                              await ref
                                  .read(notificationsControllerProvider.notifier)
                                  .markRead(visible[i].id);
                            }
                          },
                        ),
                      ),
                    );
                  }

                  if (cards.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: cards,
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedInOut extends StatefulWidget {
  const _AnimatedInOut({required this.child, this.delayMs = 0, super.key});
  final Widget child;
  final int delayMs;

  @override
  State<_AnimatedInOut> createState() => _AnimatedInOutState();
}

class _AnimatedInOutState extends State<_AnimatedInOut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<Offset> _offset =
  Tween(begin: const Offset(0, -0.15), end: Offset.zero).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _fade =
  CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: FadeTransition(opacity: _fade, child: widget.child),
    );
  }
}

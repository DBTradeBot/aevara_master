// lib/shell/app_shell.dart
//
// AppShell — tabs + AppBar + Settings banner + sync LED.
// Boot/resume sync happens AFTER first frame.
// Small change: invalidate the gauge VM after boot compute,
// and stagger compute(today) before compute(yesterday) to land a score sooner.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aevara_app/data/contracts/firestore_contracts_v1.dart' as Fx;

// Feature entry pages
import '../features/home/dashboard_page.dart';
import '../features/data_hub/data_hub_page.dart';
import '../features/experiments/experiments_page.dart';
import '../features/community/community_page.dart';

// Shared widgets
import '../core/widgets/app_bottom_nav.dart';
import '../core/widgets/settings_banner.dart';
import '../core/widgets/avatar/coach_avatar.dart';
import '../core/widgets/avatar/coach_insights_overlay.dart';
import '../core/widgets/dev_fab_navigator.dart';

// Settings icon with red dot
import '../core/widgets/settings_icon_with_dot.dart';

// Global in-app notification overlay
import '../core/notifications/notification_overlay_host.dart';

// Sync status LED (tappable legend)
import '../core/widgets/tiles/sync_status_icon.dart';

// Devices + sync status + compute
import '../state/devices_provider.dart';
import '../state/sync_status_provider.dart' as sync;
import '../state/app_providers.dart' as app_state;

// Gauge VM (invalidate after boot compute)
import '../state/daily_providers.dart' as daily;

// Ensure today's stub
import '../state/today_actions.dart' show ensureTodayDoc;

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialTab = 0});
  final int initialTab; // 0..3

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  late int _index;

  final _pages = const <Widget>[
    DashboardPage(),
    DataHubPage(),
    ExperimentsPage(),
    CommunityPage(),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Coach overlay anchoring/handle
  final LayerLink _coachLink = LayerLink();
  CoachInsightsOverlayHandle? _coachHandle;

  // Boot/resume sync guards
  bool _syncInFlight = false;
  DateTime? _lastSyncKickUtc;
  Timer? _resumeDebounce;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.clamp(0, _pages.length - 1);
    WidgetsBinding.instance.addObserver(this);

    // Defer boot sync until after first frame to avoid blocking initial paint.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _runBootOrResumeSync(reason: 'boot_postframe');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeDebounce?.cancel();
    _coachHandle?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _resumeDebounce?.cancel();
      _resumeDebounce = Timer(const Duration(milliseconds: 250), () {
        _runBootOrResumeSync(reason: 'resume');
      });
    }
  }

  Future<void> _runBootOrResumeSync({required String reason}) async {
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    // Prevent spam if a sync just ran in the last ~20 seconds.
    final nowUtc = DateTime.now().toUtc();
    if (_lastSyncKickUtc != null &&
        nowUtc.difference(_lastSyncKickUtc!).inSeconds < 20) {
      return;
    }
    if (_syncInFlight) return;

    _syncInFlight = true;
    _lastSyncKickUtc = nowUtc;

    try {
      // 0) Ensure a users/{uid}/days/{today} stub first so readers bind instantly.
      await ensureTodayDoc(uid);

      // 1) Vendor fetch (Fitbit, etc.) — fast, tight window, no CRF.
      try {
        await ref.read(devicesServiceProvider).fitbitFetchNowFor(
          uid,
          days: 3,
          backfill: false,
          includeCrf: false,
          reason: reason,
        );
      } catch (_) {
        // Silent: avoid noise when not connected.
      }

      if (!mounted) return;

      // 2) Compute TODAY first to land a visible score fast.
      final compute = ref.read(app_state.computeServiceProvider);
      await compute.computeTodayFor(uid, source: 'shell_$reason');

      // 2b) Nudge the gauge VM + status to re-read now.
      ref.invalidate(sync.todayDailyDocSnapProvider);
      ref.invalidate(sync.syncStatusProvider);
      ref.invalidate(daily.vitalityGaugeVMProvider); // <- important on boot

      // 3) Kick YESTERDAY shortly after (spreads work across frames).
      //    Do not await; cooldowns and in-flight guards are in the service.
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        compute.computeYesterdayFor(uid, source: 'shell_$reason');
      });

      if (!mounted) return;
      setState(() {}); // ensure AppBar actions rebuild

      // Optional: diagnostic log (do not await).
      unawaited(_logShellSyncEvent(uid: uid, reason: reason));
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> _logShellSyncEvent({required String uid, required String reason}) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('system_runs_client')
          .add({
        'reason': reason,
        'at_utc': DateTime.now().toUtc().toIso8601String(),
        'source': 'app_shell',
      });
    } catch (_) {
      // best effort only
    }
  }

  void _openSettings() => _scaffoldKey.currentState?.openEndDrawer();

  double _drawerWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final isTablet = size.shortestSide >= 600;
    final percent = isTablet ? 0.45 : 0.72;
    final cap = isTablet ? 420.0 : 360.0;
    return math.min(w * percent, cap);
  }

  void _reopenSettingsAfterPop() {
    Future.microtask(() => _scaffoldKey.currentState?.openEndDrawer());
  }

  Future<void> _toggleCoachOverlay() async {
    if (_coachHandle != null && _coachHandle!.isOpen == false) {
      _coachHandle = null;
    }
    if (_coachHandle?.isOpen == true) {
      await _coachHandle!.close();
      _coachHandle = null;
      return;
    }
    _coachHandle = await showCoachInsightsOverlay(
      context: context,
      link: _coachLink,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(sync.syncStatusProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: CompositedTransformTarget(
            link: _coachLink,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggleCoachOverlay,
              child: Semantics(
                button: true,
                label: 'Open coach insights',
                child: const Center(
                  child: CoachAvatar(
                    size: 40,
                    padding: 0,
                    showHalo: false,
                    hideLayerNames: ['Aura 2'],
                    semanticLabel: 'Coach avatar',
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Text('Aevara'),
        centerTitle: false,
        actions: [
          SyncStatusIcon(status: status),
          SettingsIconWithDot(onPressed: _openSettings),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _pages),
          const Align(
            alignment: Alignment.topCenter,
            child: NotificationOverlayHost(),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
      endDrawer: Drawer(
        width: _drawerWidth(context),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          child: Material(
            child: SettingsBanner(
              onReturnToShell: _reopenSettingsAfterPop,
            ),
          ),
        ),
      ),
      endDrawerEnableOpenDragGesture: true,
      drawerScrimColor: Colors.black.withOpacity(0.30),
      floatingActionButton: (_index == 0)
          ? Offstage(
        offstage: kReleaseMode,
        child: const DevFabNavigator(),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

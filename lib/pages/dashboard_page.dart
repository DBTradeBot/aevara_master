// lib/pages/dashboard_page.dart
import 'package:flutter/material.dart';

// Manual metrics row (your existing widget with Tap-to-add + Sync tile)
import '../widgets/dashboard/metrics_row.dart';

// Read-only row when synced
import '../widgets/dashboard/synced_metrics_row.dart';

// Sheets (unchanged)
import '../widgets/dashboard/sheets/sleep_sheet.dart';
import '../widgets/dashboard/sheets/hrv_sheet.dart';
import '../widgets/dashboard/sheets/steps_sheet.dart';

// Sync: sheet + status dot + header
import '../features/sync/sync_connect.dart';
import '../features/sync/sync_status_icon.dart';
import '../widgets/dashboard/metrics_header.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double? _sleepHours;
  double? _hrvMs;
  int? _steps;
  bool _connected = false;

  DateTime? _lastFullSyncUtc;

  DateTime? _sleepUpdatedUtc;
  DateTime? _recoveryUpdatedUtc;
  DateTime? _activityUpdatedUtc;
  DateTime? _cardioUpdatedUtc;

  List<SyncProviderStatus> _providerStatusesFromState() {
    final now = DateTime.now();
    return [
      SyncProviderStatus(
        id: 'apple',
        label: 'Apple Health',
        icon: Icons.apple,
        status: _connected ? SyncStatus.synced : SyncStatus.notConnected,
        lastSync: _connected ? now.subtract(const Duration(hours: 6)) : null,
      ),
      SyncProviderStatus(
        id: 'google',
        label: 'Google Fit / Health',
        icon: Icons.android,
        status: SyncStatus.stale,
        lastSync: now.subtract(const Duration(days: 3)),
      ),
      const SyncProviderStatus(
        id: 'fitbit',
        label: 'Fitbit',
        icon: Icons.watch_outlined,
      ),
      const SyncProviderStatus(
        id: 'whoop',
        label: 'WHOOP',
        icon: Icons.fitness_center,
      ),
      const SyncProviderStatus(
        id: 'garmin',
        label: 'Garmin',
        icon: Icons.route,
      ),
      const SyncProviderStatus(
        id: 'oura',
        label: 'Oura',
        icon: Icons.circle_outlined,
      ),
    ];
  }

  void _openSleep() {
    showSleepSheet(
      context,
      initialHours: _sleepHours ?? 6.0,
      onSave: (hours) {
        setState(() {
          _sleepHours = hours;
          _sleepUpdatedUtc = DateTime.now().toUtc();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved Sleep: ${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)}h')),
        );
      },
    );
  }

  void _openHRV() {
    showHrvSheet(
      context,
      initialMs: _hrvMs ?? 45.0,
      onSave: (dynamic v) {
        final double ms = v is double ? v : (v as num).toDouble();
        setState(() {
          _hrvMs = ms;
          _recoveryUpdatedUtc = DateTime.now().toUtc();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved HRV: ${ms.toStringAsFixed(0)}ms')),
        );
      },
    );
  }

  void _openSteps() {
    showStepsSheet(
      context,
      initialSteps: (_steps ?? 6500).toDouble(),
      onSave: (dynamic v) {
        final int next = v is int ? v : (v as num).toInt();
        setState(() {
          _steps = next;
          _activityUpdatedUtc = DateTime.now().toUtc();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved Steps: $next')),
        );
      },
    );
  }

  Future<void> _openSync() async {
    final res = await showSyncConnectSheet(
      context,
      providers: _providerStatusesFromState(),
      onOpenPrivacy: () => Navigator.pushNamed(context, '/privacy'),
      onProviderTap: (id) async {
        setState(() {
          _connected = true;
          _lastFullSyncUtc = DateTime.now().toUtc();
          _sleepUpdatedUtc ??= _lastFullSyncUtc;
          _recoveryUpdatedUtc ??= _lastFullSyncUtc;
          _activityUpdatedUtc ??= _lastFullSyncUtc;
          _cardioUpdatedUtc ??= _lastFullSyncUtc;
        });
        if (mounted) Navigator.of(context).maybePop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected: $id')),
          );
        }
      },
    );

    if (res == SyncConnectResult.disconnected) {
      setState(() {
        _connected = false;
        _lastFullSyncUtc = null;
        _sleepUpdatedUtc = null;
        _recoveryUpdatedUtc = null;
        _activityUpdatedUtc = null;
        _cardioUpdatedUtc = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disconnected — showing manual entry')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerState = _connected ? SyncState.synced : SyncState.unsynced;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aevara'),
        actions: [
          IconButton(
            tooltip: 'Open Flow Preview',
            icon: const Icon(Icons.play_arrow),
            onPressed: () => Navigator.of(context).pushNamed('/app/flow-home'),
          ),
          PopupMenuButton<String>(
            tooltip: 'Dev Menu',
            onSelected: (value) {
              switch (value) {
                case 'sign_in':
                  Navigator.of(context).pushNamed('/auth/sign-in');
                  break;
                case 'create':
                  Navigator.of(context).pushNamed('/auth/create-account');
                  break;
                case 'verify':
                  Navigator.of(context).pushNamed('/auth/verify-email');
                  break;
                case 'profile':
                  Navigator.of(context).pushNamed('/onboarding/profile');
                  break;
                case 'ready':
                  Navigator.of(context).pushNamed('/onboarding/ready');
                  break;
                case 'devices':
                  Navigator.of(context).pushNamed('/app/devices');
                  break;
                case 'privacy':
                  Navigator.of(context).pushNamed('/app/privacy');
                  break;
                case 'account':
                  Navigator.of(context).pushNamed('/app/account');
                  break;
                case 'about':
                  Navigator.of(context).pushNamed('/app/about');
                  break;
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'sign_in', child: Text('Sign In')),
              PopupMenuItem(value: 'create', child: Text('Create Account')),
              PopupMenuItem(value: 'verify', child: Text('Verify Email')),
              PopupMenuItem(value: 'profile', child: Text('Profile Setup')),
              PopupMenuItem(value: 'ready', child: Text('Ready / Coach Intro')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'devices', child: Text('Device Connections')),
              PopupMenuItem(value: 'privacy', child: Text('Privacy & Data')),
              PopupMenuItem(value: 'account', child: Text('Account Settings')),
              PopupMenuItem(value: 'about', child: Text('About Aevara')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: MetricsHeader(
              state: headerState,
              lastSync: _lastFullSyncUtc?.toLocal(),
              onSyncTap: _openSync,
              showInstruction: !_connected,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _connected
                ? SyncedMetricsRow(
              sleepHours: _sleepHours,
              sleepGoalHours: 7.5,
              readinessScore: _hrvMs == null
                  ? null
                  : (((_hrvMs!.clamp(20, 100) - 20) / 80) * 100)
                  .round()
                  .clamp(0, 100),
              steps: _steps,
              stepsGoal: 10000,
              vo2max: 42.0,
            )
                : MetricsRow(
              sleepHours: _sleepHours,
              hrvRmssdMs: _hrvMs,
              stepsCount: _steps,
              isAnyProviderConnected: _connected,
              onSleepTap: _openSleep,
              onHRVTap: _openHRV,
              onStepsTap: _openSteps,
              onSyncTap: _openSync,
              lastSyncUtc: _lastFullSyncUtc,
              syncError: false,
            ),
          ),
        ],
      ),
    );
  }
}

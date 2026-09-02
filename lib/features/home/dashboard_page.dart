// lib/features/home/dashboard_page.dart
//
// Pull-to-refresh for Vitality vNext:
//   1) Fast vendor fetch (tight window)
//   2) vitalityComputeRangeHttp days=4 (single call, bypass cooldown)
//   3) Invalidate streams immediately
//
// Note: no 30-day coverage sweep here (callable handles backfill=false).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Needed for FirebaseFirestore, SetOptions, DocumentSnapshot

import '../../state/user_providers.dart' as user_state;
import '../../state/app_providers.dart' as app_state;
import '../../state/daily_providers.dart' as daily;
import '../../state/healthy_days_providers.dart' as healthy;
import '../../state/notifications_providers.dart' as notif;
import '../../state/devices_provider.dart';
import '../../state/sync_status_provider.dart' as sync;

import '../../routing/route_paths.dart';
import 'components/hero_header.dart';

import 'sheets/input_sleep_sheet.dart';
import 'sheets/input_hrv_sheet.dart';
import 'sheets/input_rhr_sheet.dart';
import 'sheets/input_steps_sheet.dart';
import 'sheets/input_wellbeing_sheet.dart';

final _calibHideLocalProvider = StateProvider<bool>((_) => false);

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _handleRefresh(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(user_state.currentUserIdProvider);
    if (uid != null && uid.isNotEmpty) {
      // 1) Pull latest from devices (Fitbit; others when available). Ignore if not connected.
      try {
        await ref.read(devicesServiceProvider).fitbitFetchNowFor(
          uid,
          days: 4,
          backfill: false,
          includeCrf: false,
          reason: 'pull_to_refresh',
        );
      } catch (_) {
        // no-op when not connected
      }

      // 2) Vitality compute for last 4 days (force via bypassCooldown)
      await ref.read(app_state.computeServiceProvider).computeRangeFor(
        uid,
        days: 4,
        allowBackfill: true,
        source: 'pull_to_refresh',
        bypassCooldown: true,
      );
    }

    // 3) Invalidate so UI updates with fresh data immediately
    ref.invalidate(sync.todayDailyDocSnapProvider);
    ref.invalidate(daily.vitalityGaugeVMProvider);
    ref.invalidate(healthy.healthyDaysCountProvider);
    ref.invalidate(healthy.healthyDaysRiskSeriesProvider);
    ref.invalidate(sync.syncStatusProvider);

    // Small settle delay so first post-compute snapshot lands before end of refresh UI
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(user_state.currentUserIdProvider);

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(context, ref),
      edgeOffset: 0,
      displacement: 36,
      child: ListView(
        padding: EdgeInsets.zero,
        children: const [
          _CalibrationBannerWrapper(),
          SizedBox(height: 8),
          HeroHeader(),
          SizedBox(height: 16),
          _QuickInputsSection(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CalibrationBannerWrapper extends ConsumerWidget {
  const _CalibrationBannerWrapper();

  Future<void> _dismissCalibration(
      BuildContext context,
      WidgetRef ref,
      String uid,
      int day,
      ) async {
    ref.read(_calibHideLocalProvider.notifier).state = true;

    final stickyUntil = DateTime.now().add(const Duration(days: 14));
    await ref
        .read(notif.notificationsControllerProvider.notifier)
        .createCalibrationDismissed(day: day, stickyUntil: stickyUntil);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'ui': {'calibration_banner_dismissed': true}
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(user_state.currentUserIdProvider);
    if (uid == null || uid.isEmpty) return const SizedBox.shrink();

    final userDocStream =
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    final hdAsync = ref.watch(healthy.healthyDaysCountProvider);
    final hideLocal = ref.watch(_calibHideLocalProvider);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocStream,
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
        final data = snap.data!.data() ?? {};
        final status = (data['calibration_status'] ?? 'complete').toString();
        final day = (data['calibration_day'] is int)
            ? data['calibration_day'] as int
            : int.tryParse('${data['calibration_day'] ?? 0}') ?? 0;

        final ui = (data['ui'] as Map?)?.cast<String, dynamic>();
        final hideServer = (ui?['calibration_banner_dismissed'] == true);

        if (status == 'complete' || hideLocal || hideServer) {
          return const SizedBox.shrink();
        }

        final tt = Theme.of(context).textTheme;
        final healthyDays = hdAsync.maybeWhen(orElse: () => null, data: (v) => v);
        final healthyText = healthyDays == null
            ? ''
            : ' · $healthyDays healthy day${healthyDays == 1 ? '' : 's'} logged';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Dismissible(
            key: const ValueKey('calibration_banner'),
            direction: DismissDirection.horizontal,
            onDismissed: (_) => _dismissCalibration(context, ref, uid, day),
            child: InkWell(
              onTap: () => _dismissCalibration(context, ref, uid, day),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F3F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB9DCE6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_empty,
                        color: Color(0xFF1B1B1B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Calibrating your baseline · Day $day of 14$healthyText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: const Color(0xFF1B1B1B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(RoutePaths.methodsDoc),
                      style: TextButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Learn more'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickInputsSection extends StatelessWidget {
  const _QuickInputsSection();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick inputs', style: tt.titleLarge),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionChipButton(label: 'Add Sleep', sheetBuilder: InputSleepSheet()),
              _ActionChipButton(label: 'Add HRV', sheetBuilder: InputHrvSheet()),
              _ActionChipButton(label: 'Add RHR', sheetBuilder: InputRhrSheet()),
              _ActionChipButton(label: 'Add Steps', sheetBuilder: InputStepsSheet()),
              _ActionChipButton(label: 'Wellbeing', sheetBuilder: InputWellbeingSheet()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({required this.label, required this.sheetBuilder});
  final String label;
  final Widget sheetBuilder;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => sheetBuilder,
      ),
      child: Text(label),
    );
  }
}

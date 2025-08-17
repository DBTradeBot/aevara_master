// lib/widgets/dashboard/metrics_section_switcher.dart
import 'package:flutter/material.dart';

/// Pure logic switcher: decides whether to show the manual MetricsRow
/// or the SyncedMetricsRow based on freshness rules. It does NOT render
/// a header (you already have MetricsHeader with your status dot).
class MetricsSectionSwitcher extends StatelessWidget {
  // Connection & sync
  final bool hasPrimaryConnected;     // any wearable connected?
  final DateTime? lastFullSyncUtc;    // last "all sources merged" sync

  // Freshness timestamps (UTC)
  final DateTime? sleepUpdatedUtc;
  final DateTime? recoveryUpdatedUtc; // HRV/RHR composite freshness
  final DateTime? activityUpdatedUtc; // steps/MVPA
  final DateTime? cardioUpdatedUtc;   // VO2max / Fitness Age

  // Child rows
  final Widget manualMetricsRow;
  final Widget syncedMetricsRow;

  const MetricsSectionSwitcher({
    super.key,
    required this.hasPrimaryConnected,
    required this.lastFullSyncUtc,
    required this.sleepUpdatedUtc,
    required this.recoveryUpdatedUtc,
    required this.activityUpdatedUtc,
    required this.cardioUpdatedUtc,
    required this.manualMetricsRow,
    required this.syncedMetricsRow,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();

    // Thresholds
    const dailyFreshHrs = 24;   // "current"
    const dailyStaleHrs = 48;   // revert threshold
    const cardioFreshDays = 7;  // VO2max/Fitness Age

    bool _isFresh(DateTime? t, Duration maxAge) =>
        t != null && now.difference(t) <= maxAge;

    // Per-metric freshness
    final sleepFresh    = _isFresh(sleepUpdatedUtc, const Duration(hours: dailyFreshHrs));
    final recoveryFresh = _isFresh(recoveryUpdatedUtc, const Duration(hours: dailyFreshHrs));
    final activityFresh = _isFresh(activityUpdatedUtc, const Duration(hours: dailyFreshHrs));
    final cardioFresh   = _isFresh(cardioUpdatedUtc, const Duration(days: cardioFreshDays));

    final dailyFreshCount = [sleepFresh, recoveryFresh, activityFresh].where((b) => b).length;

    // Count how many daily metrics are beyond stale threshold (>= 48h)
    int _staleDailyCount() {
      int c = 0;
      if (!_isFresh(sleepUpdatedUtc, const Duration(hours: dailyStaleHrs))) c++;
      if (!_isFresh(recoveryUpdatedUtc, const Duration(hours: dailyStaleHrs))) c++;
      if (!_isFresh(activityUpdatedUtc, const Duration(hours: dailyStaleHrs))) c++;
      return c;
    }

    final twoDailyStaleOrMore = _staleDailyCount() >= 2;

    // Show synced when:
    // - device connected
    // - >= 3/3 daily metrics fresh within 24h
    // - last full sync within 24h
    // - cardio fresh within 7d
    final canShowSynced =
        hasPrimaryConnected &&
            dailyFreshCount >= 3 &&
            (lastFullSyncUtc != null && _isFresh(lastFullSyncUtc, const Duration(hours: dailyFreshHrs))) &&
            cardioFresh;

    // Revert if:
    // - no device OR
    // - two or more daily metrics are stale beyond 48h
    final mustRevertToManual = !hasPrimaryConnected || twoDailyStaleOrMore;

    final showSynced = (!mustRevertToManual && canShowSynced);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: showSynced ? syncedMetricsRow : manualMetricsRow,
    );
  }
}

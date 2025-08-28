// lib/data/models/daily_metrics.dart
//
// DTOs for coach & daily UI. Safe to extend later.


/// Coach-facing state bucket based on Vitality vs Chronological delta.
enum CoachAgeState { younger, near, slightlyOlder, muchOlder }

CoachAgeState coachAgeStateFromDelta(double deltaHealthyYears) {
  // +delta => younger than chrono (vitality < chrono)
  if (deltaHealthyYears > 2.0) return CoachAgeState.younger;
  if (deltaHealthyYears < -5.0) return CoachAgeState.muchOlder;
  if (deltaHealthyYears < -2.0) return CoachAgeState.slightlyOlder;
  return CoachAgeState.near;
}

/// Compact context the Coach uses to generate copy.
class DailyCoachContext {
  final double chronoAgeYears;
  final double? vitalityAgeYears; // null when not computed yet
  final double deltaHealthyYears; // + => younger than chrono
  final int confidence; // 0–100
  final CoachAgeState state;

  // Optional domain subscores (0–100)
  final int? scoreRecovery;
  final int? scoreSleep;
  final int? scoreActivity;
  final int? scoreWellbeing;
  final int? scoreCrf;

  // Readiness/transparency
  final bool hasAnyRawInputsToday;
  final bool seenComputeToday;
  final String readyReason; // 'synced' | 'manual' | 'unknown'
  final int? healthyDays30; // optional 0..30

  const DailyCoachContext({
    required this.chronoAgeYears,
    required this.vitalityAgeYears,
    required this.deltaHealthyYears,
    required this.confidence,
    required this.state,
    required this.scoreRecovery,
    required this.scoreSleep,
    required this.scoreActivity,
    required this.scoreWellbeing,
    required this.scoreCrf,
    required this.hasAnyRawInputsToday,
    required this.seenComputeToday,
    required this.readyReason,
    this.healthyDays30,
  });

  bool get hasVitality => vitalityAgeYears != null;

  /// Coarse confidence buckets for copy logic.
  String get confidenceBucket {
    if (confidence >= 70) return 'high';
    if (confidence >= 40) return 'medium';
    return 'low';
  }

  /// Returns the (domainKey,score) pair for the weakest observed domain, or null.
  (String, int)? weakestDomain() {
    final pairs = <(String, int)>[];
    if (scoreRecovery != null) pairs.add(('recovery', scoreRecovery!));
    if (scoreSleep != null) pairs.add(('sleep', scoreSleep!));
    if (scoreActivity != null) pairs.add(('activity', scoreActivity!));
    if (scoreWellbeing != null) pairs.add(('wellbeing', scoreWellbeing!));
    if (scoreCrf != null) pairs.add(('crf', scoreCrf!));
    if (pairs.isEmpty) return null;
    pairs.sort((a, b) => a.$2.compareTo(b.$2));
    return pairs.first;
  }
}

/// Optional: raw daily values DTO (handy elsewhere).
class DailyMetrics {
  final double? sleepHours;
  final double? hrvRmssd;
  final double? restingHr;
  final int? steps;
  final int? wellbeing; // 1..5 (1 best)
  final int? confidence; // 0..100

  const DailyMetrics({
    this.sleepHours,
    this.hrvRmssd,
    this.restingHr,
    this.steps,
    this.wellbeing,
    this.confidence,
  });

  factory DailyMetrics.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const DailyMetrics();
    return DailyMetrics(
      sleepHours: (m['sleep_total_hours'] as num?)?.toDouble(),
      hrvRmssd: (m['hrv_rmssd_ms'] as num?)?.toDouble(),
      restingHr: (m['rhr_bpm'] as num?)?.toDouble(),
      steps: (m['steps_count'] as num?)?.toInt(),
      wellbeing: (m['wellbeing_level_1to5'] as num?)?.toInt(),
      confidence: (m['score_confidence'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'sleep_total_hours': sleepHours,
    'hrv_rmssd_ms': hrvRmssd,
    'rhr_bpm': restingHr,
    'steps_count': steps,
    'wellbeing_level_1to5': wellbeing,
    'score_confidence': confidence,
  };
}
